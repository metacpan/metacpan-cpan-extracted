package Pod::Weaver::Plugin::Rinci;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Perinci::Access::Perl;
use Perinci::To::POD;
use Sub::Identify qw(sub_fullname);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-13'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Rinci'; # DIST
our $VERSION = '0.781'; # VERSION

our $pa = Perinci::Access::Perl->new;

# regex
has exclude_modules => (
    is => 'rw',
    isa => 'Str',
);
has exclude_files => (
    is => 'rw',
    isa => 'Str',
);

sub _process_module {
    require Require::Hook::DzilBuild;

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};
    my ($file) = grep { $_->name eq $filename } @{ $input->{zilla}->files };

    # guess package from filename
    $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $input->{zilla}, debug=>1), @INC);

    # force reload to get the recent version of module
    (my $package_pm = "$package.pm") =~ s!::!/!g;
    delete $INC{$package_pm};

    my $url = $package; $url =~ s!::!/!g; $url = "pl:/$url/";
    my $res = $pa->request(meta => $url);
    die "Can't meta $url: $res->[0] - $res->[1]" unless $res->[0] == 200;
    my $meta = $res->[2];
    $res = $pa->request(child_metas => $url);
    die "Can't child_metas $url: $res->[0] - $res->[1]" unless $res->[0] == 200;
    my $cmetas = $res->[2];

    my $exports = {};
    {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        # we import specifically when module is using Exporter::Rinci as its
        # exporter, because Exporter::Rinci works by filling @EXPORT* variables
        # during import().
        if (sub_fullname($package->can("import")) =~ /^Exporter::Rinci::/) {
            $package->import;
        }

        my $uses_exporter_mod = @{"$package\::EXPORT"} || @{"$package\::EXPORT_OK"};
        for my $funcname (keys %$cmetas) {
            next unless $funcname =~ /\A\w+\z/;
            my $funcmeta = $cmetas->{$funcname};
            my $export = -1;
            if ($uses_exporter_mod &&
                    grep {$_ eq $funcname} @{"$package\::EXPORT"}) {
                $export = 1;
            } elsif ($uses_exporter_mod &&
                    grep {$_ eq $funcname} @{"$package\::EXPORT_OK"}) {
                $export = 0;
            } elsif ($uses_exporter_mod) {
                $export = -1;
            } elsif (grep {$_ eq 'export:default'} @{ $funcmeta->{tags} // [] }) {
                $export = 1;
            } elsif (grep {$_ eq 'export:never'} @{ $funcmeta->{tags} // [] }) {
                $export = -1;
            }
            $exports->{$funcname} = $export;
        }
    }
    my $doc = Perinci::To::POD->new(
        name=>$package, meta=>$meta, child_metas=>$cmetas, url=>$url,
        exports=>$exports);
    $doc->delete_doc_section('summary'); # already handled by other plugins
    $doc->delete_doc_section('version'); # ditto
    my $pod_text = $doc->gen_doc;

    my $found;
    while ($pod_text =~ /^=head1 ([^\n]+)\n(.+?)(?=^=head1|\z)/msg) {
        my ($sectname, $sectcontent) = ($1, $2);

        # skip inserting section if there is no text
        next unless $sectcontent =~ /\S/;

        # skip inserting FUNCTIONS if there are no functions
        next if $sectname eq 'FUNCTIONS' && $sectcontent !~ /^=head2/m;

        # skip inserting METHODS if there are no functions
        next if $sectname eq 'METHODS' && $sectcontent !~ /^=head2/m;

        $found++;
        #$self->log(["generated POD section %s", $1]);

        my %opts;
        # position
        if ($sectname eq 'FUNCTIONS' || $sectname eq 'METHODS') {
            $opts{after_section} = [
                'DESCRIPTION',
            ];
            # make sure we don't put it too below
            $opts{before_section} = [
                'SEE ALSO',
                'HOMEPAGE',
            ];
        }

        $self->add_text_to_section($document, $sectcontent, $sectname, \%opts);
    }
    if ($found) {
        $self->log(["added POD sections from Rinci metadata for file (module) '%s'", $filename]);
    }
}

sub _process_script {
    require File::Temp;
    require Perinci::CmdLine::POD;
    require Perinci::CmdLine::Util;
    #require Require::Hook::DzilBuild; # script is dumped in a different process, so doesn't work here

    my ($self, $document, $input) = @_;
    # dump to temporary file first because the file might not be an ondisk file
    # and/or already munged.
    my $filename;
    {
        require File::Temp;
        my ($fh, $tempname) = File::Temp::tempfile();
        my ($file) = grep { $_->name eq $input->{filename} }
            @{ $input->{zilla}->files };
        print $fh $file->encoded_content;
        close $fh;
        $filename = $tempname;
    }

    (my $command_name = $input->{filename}) =~ s!.+/!!;

    my $det_res = Perinci::CmdLine::Util::detect_pericmd_script(
        filename => $filename,
    );
    if ($det_res->[0] == 412) {
        $self->log_debug(["skipped file '%s' (%s)", $filename, $det_res->[1]]);
        return;
    } elsif (!$det_res->[2]) {
        $self->log_debug(["skipped file '%s' (not detected as Perinci::CmdLine script)", $filename]);
        return;
    }

    # so scripts can know that they are being dumped in the context of
    # Dist::Zilla
    local $ENV{DZIL} = 1;

    my $completer_name = $command_name;
    if ($det_res->[3]{'func.is_inline'}) {
        (my $comp_filename = $input->{filename}) =~ s!(.+)/(.+)!$1/_$2!;
        my $has_completer = grep { $_->name eq $comp_filename }
            @{ $input->{zilla}->files };
        if ($has_completer) {
            $completer_name = "_$command_name";
        } else {
            $completer_name = undef;
        }
    }
    my $res = Perinci::CmdLine::POD::gen_pod_for_pericmd_script(
        script => $filename,
        program_name => $command_name,
        libs => ["lib"],
        (completer_script => $completer_name) x !!defined($completer_name),
    );
    die "Can't generate POD for script: $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $modified;
    for my $s (@{ $res->[3]{'func.sections'} }) {
        next unless $s->{content};
        $modified++ if $self->add_text_to_section(
            $document, $s->{content}, $s->{name},
            {
                (ignore => $s->{ignore}) x !!$s->{ignore},
            });
    }

    if ($modified) {
        $self->log(["added POD sections from Rinci metadata for script '%s'", $input->{filename}]);
    }
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    if (defined $self->exclude_files) {
        my $re = $self->exclude_files;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in exclude_files: $re";
        if ($filename =~ $re) {
            $self->log_debug(["skipped file '%s' (matched exclude_files)", $filename]);
            return;
        }
    }

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        if (defined $self->exclude_modules) {
            my $re = $self->exclude_modules;
            eval { $re = qr/$re/ };
            $@ and die "Invalid regex in exclude_modules: $re";
            if ($package =~ $re) {
                $self->log (["skipped package %s (matched exclude_modules)", $package]);
                return;
            }
        }
        $self->_process_module($document, $input);
    } elsif ($filename =~ m!^(?:bin|scripts?)/!) {
        $self->_process_script($document, $input);
    }
}

1;
# ABSTRACT: Insert stuffs to POD from Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Rinci - Insert stuffs to POD from Rinci metadata

=head1 VERSION

This document describes version 0.781 of Pod::Weaver::Plugin::Rinci (from Perl distribution Pod-Weaver-Plugin-Rinci), released on 2022-06-13.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Rinci]
 ;exclude_modules = REGEX
 ;exclude_files = REGEX

=head1 DESCRIPTION

This plugin inserts stuffs to POD documentation based on information found on
Rinci metadata.

=head2 For modules

For modules, the following are inserted:

=over

=item * DESCRIPTION

From C<description> property from package metadata, if any.

=item * FUNCTIONS (or METHODS)

Documentation for each function (or method) for which the metadata is found
under the package will be added here. For each function, there will be summary,
description, usage, list of arguments and their documentation, as well as
examples, according to what's available in the function metadata of
corresponding function.

=back

To get Rinci metadata from a module, L<Perinci::Access::Perl> is used.

=head2 For Perinci::CmdLine-based CLI script

For scripts using L<Perinci::CmdLine> (or its variant ::Any and ::Lite), the
following are inserted:

=over

=item * SYNOPSIS

If the script's POD does not yet have this section, this section will be added
containing the usage line of the script.

=item * DESCRIPTION

If the script's POD does not already have this section, and if the script does
not have subcommands, description from function metadata will be inserted here,
if any.

=item * SUBCOMMANDS

If the script's POD does not already have his section, and if the script has
subcommands, then each subcommand will be listed here along with its summary and
description.

=item * OPTIONS

If the script's POD does not already have his section, command-line options for
the script will be listed here. If script has subcommands, the options will be
categorized per subcommand.

=item * CONFIGURATION

If the script's POD does not already have his section, general information about
configuration files and available configuration parameters will be listed here.
If script has subcommands, the parameters will be categorized per subcommand.

=item * FILES

Configuration files read by script will be listed here.

=back

To get Perinci::CmdLine object information (which contains the URL of the Rinci
function, or the list of subcommands, among others), the script is run with a
patched C<run()> that will dump the content of the object and exit immediately,
so the plugin can inspect it.

Caveats: 1) Function used by the script must reside in the module, not embedded
inside the script itself, otherwise it will not be readable by the plugin. 2)
Coderef C<subcommands> is not supported.

To exclude a script from being processed, you can also put C<# NO_PWP_RINCI> in
the script.

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Rinci>.

=head1 SEE ALSO

L<Pod::Weaver>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
