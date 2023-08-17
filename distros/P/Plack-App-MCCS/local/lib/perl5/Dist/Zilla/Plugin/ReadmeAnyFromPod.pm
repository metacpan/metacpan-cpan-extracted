use strict;
use warnings;

package Dist::Zilla::Plugin::ReadmeAnyFromPod;
# ABSTRACT: Automatically convert POD to a README in any format for Dist::Zilla
$Dist::Zilla::Plugin::ReadmeAnyFromPod::VERSION = '0.163250';
use List::Util 1.33 qw( none first );
use Moose::Util::TypeConstraints qw(enum);
use Moose;
use MooseX::Has::Sugar;
use Path::Tiny 0.004;
use Scalar::Util 'blessed';

with 'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::AfterRelease',
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FilePruner',
    'Dist::Zilla::Role::FileWatcher',
    'Dist::Zilla::Role::PPI',
;

# TODO: Should these be separate modules?
our $_types = {
    pod => {
        filename => 'README.pod',
        parser => sub {
            return $_[0];
        },
    },
    text => {
        filename => 'README',
        parser => sub {
            my $pod = $_[0];

            require Pod::Simple::Text;
            Pod::Simple::Text->VERSION('3.23');
            my $parser = Pod::Simple::Text->new;
            $parser->output_string( \my $content );
            $parser->parse_characters(1);
            $parser->parse_string_document($pod);
            return $content;
        },
    },
    markdown => {
        filename => 'README.mkdn',
        parser => sub {
            my $pod = $_[0];

            require Pod::Markdown;
            Pod::Markdown->VERSION('2.000');
            my $parser = Pod::Markdown->new();
            $parser->output_string( \my $content );
            $parser->parse_characters(1);
            $parser->parse_string_document($pod);
            return $content;
        },
    },
    gfm => {
        filename => 'README.md',
        parser => sub {
            my $pod = $_[0];

            require Pod::Markdown::Github;
            Pod::Markdown->VERSION('0.01');
            my $parser = Pod::Markdown::Github->new();
            $parser->output_string( \my $content );
            $parser->parse_characters(1);
            $parser->parse_string_document($pod);
            return $content;
        },
    },
    html => {
        filename => 'README.html',
        parser => sub {
            my $pod = $_[0];

            require Pod::Simple::HTML;
            Pod::Simple::HTML->VERSION('3.23');
            my $parser = Pod::Simple::HTML->new;
            $parser->output_string( \my $content );
            $parser->parse_characters(1);
            $parser->parse_string_document($pod);
            return $content;
        }
    }
};


has type => (
    ro, lazy,
    isa        => enum([keys %$_types]),
    default    => sub { $_[0]->__from_name()->[0] || 'text' },
);


has filename => (
    ro, lazy,
    isa => 'Str',
    default => sub { $_types->{$_[0]->type}->{filename}; }
);


has source_filename => (
    ro, lazy,
    isa => 'Str',
    builder => '_build_source_filename',
);

sub _build_source_filename {
    my $self = shift;
    my $pm = $self->zilla->main_module->name;
    (my $pod = $pm) =~ s/\.pm$/\.pod/;
    return -e $pod ? $pod : $pm;
}


has location => (
    ro, lazy,
    isa => enum([qw(build root)]),
    default => sub { $_[0]->__from_name()->[1] || 'build' },
);


has phase => (
    ro, lazy,
    isa => enum([qw(build release)]),
    default => 'build',
);


sub BUILD {
    my $self = shift;

    $self->log_fatal('You cannot use location=build with phase=release!')
        if $self->location eq 'build' and $self->phase eq 'release';

    $self->log('You are creating a .pod directly in the build - be aware that this will be installed like a .pm file and as a manpage')
        if $self->location eq 'build' and $self->type eq 'pod';
}


sub gather_files {
    my ($self) = @_;

    my $filename = $self->filename;
    if ( $self->location eq 'build'
         # allow for the file to also exist in the dist
         and none { $_->name eq $filename } @{ $self->zilla->files }
       ) {
        require Dist::Zilla::File::InMemory;
        my $file = Dist::Zilla::File::InMemory->new({
            content => 'this will be overwritten',
            name    => $self->filename,
        });

        $self->add_file($file);
    }
    return;
}


sub prune_files {
    my ($self) = @_;

    # leave the file in the dist if another instance of us is adding it there.
    if ($self->location eq 'root'
        and not grep {
            blessed($self) eq blessed($_)
                and $_->location eq 'build'
                and $_->filename eq $self->filename
        } @{$self->zilla->plugins}) {
        for my $file (@{ $self->zilla->files }) {
            next unless $file->name eq $self->filename;
            $self->log_debug([ 'pruning %s', $file->name ]);
            $self->zilla->prune_file($file);
        }
    }
    return;
}


sub munge_files {
    my $self = shift;

    if ( $self->location eq 'build' ) {
        my $filename = $self->filename;
        my $file = first { $_->name eq $filename } @{ $self->zilla->files };
        if ($file) {
            $self->munge_file($file);
        }
        else {
            $self->log_fatal(
                      "Could not find a $filename file during the build"
                    . ' - did you prune it away with a PruneFiles block?' );
        }
    }
    return;
}


my %watching;
sub munge_file {
    my ($self, $target_file) = @_;

    # Ensure that we repeat the munging if the source file is modified
    # after we run.
    my $source_file = $self->_source_file();
    $self->watch_file($source_file, sub {
        my ($self, $watched_file) = @_;

        # recalculate the content based on the updates
        $self->log('someone tried to munge ' . $watched_file->name . ' after we read from it. Making modifications again...');
        $self->munge_file($target_file);
    }) if not $watching{$source_file->name}++;

    $self->log_debug([ 'ReadmeAnyFromPod updating contents of %s in dist', $target_file->name ]);
    $target_file->content($self->get_readme_content);
    return;
}


sub after_build {
    my $self = shift;
    $self->_create_readme if $self->phase eq 'build';
}


sub after_release {
    my $self = shift;
    $self->_create_readme if $self->phase eq 'release';
}

sub _create_readme {
    my $self = shift;

    if ( $self->location eq 'root' ) {
        my $filename = $self->filename;
        $self->log_debug([ 'ReadmeAnyFromPod updating contents of %s in root', $filename ]);

        my $content = $self->get_readme_content();

        my $destination_file = path($self->zilla->root)->child($filename);
        if (-e $destination_file) {
            $self->log("overriding $filename in root");
        }
        my $encoding = $self->_get_source_encoding();
        $destination_file->spew_raw(
            $encoding eq 'raw'
                ? $content
                : do { require Encode; Encode::encode($encoding, $content) }
        );
    }

    return;
}

sub _source_file {
    my ($self) = shift;

    my $filename = $self->source_filename;
    first { $_->name eq $filename } @{ $self->zilla->files };
}

# Holds the contents of the source file as of the last time we
# generated a readme from it. We use this to detect when the source
# file is modified so we can update the README file again.
has _last_source_content => (
    is => 'rw', isa => 'Str',
    default => '',
);

sub _get_source_pod {
    my ($self) = shift;

    my $source_file = $self->_source_file;

    # cache contents before we alter it, for later comparison
    $self->_last_source_content($source_file->content);

    require PPI::Document;  # for Dist::Zilla::Role::PPI < 5.009
    my $doc = $self->ppi_document_for_file($source_file);

    my $pod_elems = $doc->find('PPI::Token::Pod');
    my $pod_content = "";
    if ($pod_elems) {
        # Concatenation should stringify it
        $pod_content .= PPI::Token::Pod->merge(@$pod_elems);
    }

    if ((my $encoding = $self->_get_source_encoding) ne 'raw'
            and not eval { Dist::Zilla::Role::PPI->VERSION('6.003') }
    ) {
        # older Dist::Zilla::Role::PPI passes encoded content to PPI
        require Encode;
        $pod_content = Encode::decode($encoding, $pod_content);
    }

    return $pod_content;
}

sub _get_source_encoding {
    my ($self) = shift;
    my $source_file = $self->_source_file;
    return
        $source_file->can('encoding')
            ? $source_file->encoding
            : 'raw';        # Dist::Zilla pre-5.0
}


sub get_readme_content {
    my ($self) = shift;
    my $source_pod = $self->_get_source_pod();
    my $parser = $_types->{$self->type}->{parser};
    # Save the POD text used to generate the README.
    return $parser->($source_pod);
}

{
    my %cache;
    sub __from_name {
        my ($self) = @_;
        my $name = $self->plugin_name;

        # Use cached values if available
        if ($cache{$name}) {
            return $cache{$name};
        }

        # qr{TYPE1|TYPE2|...}
        my $type_regex = join('|', map {quotemeta} keys %$_types);
        # qr{LOC1|LOC2|...}
        my $location_regex = join('|', map {quotemeta} qw(build root));
        # qr{(?:Readme)? (TYPE1|TYPE2|...) (?:In)? (LOC1|LOC2|...) }x
        my $complete_regex = qr{ (?:Readme)? ($type_regex) (?:(?:In)? ($location_regex))? }ix;
        my ($type, $location) = (lc $name) =~ m{(?:\A|/) \s* $complete_regex \s* \Z}ix;
        $cache{$name} = [$type, $location];
        return $cache{$name};
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::ReadmeAnyFromPod - Automatically convert POD to a README in any format for Dist::Zilla

=head1 VERSION

version 0.163250

=head1 SYNOPSIS

In your F<dist.ini>

    [ReadmeAnyFromPod]
    ; Default is plaintext README in build dir

    ; Using non-default options: POD format with custom filename in
    ; dist root, outside of build. Including this README in version
    ; control makes Github happy.
    [ReadmeAnyFromPod / ReadmePodInRoot]
    type = pod
    filename = README.pod
    location = root

    ; Using plugin name autodetection: Produces README.html in root
    [ ReadmeAnyFromPod / HtmlInRoot ]

=head1 DESCRIPTION

Generates a README for your L<Dist::Zilla> powered dist from its
C<main_module> in any of several formats. The generated README can be
included in the build or created in the root of your dist for e.g.
inclusion into version control.

=head2 PLUGIN NAME AUTODETECTION

If you give the plugin an appropriate name (a string after the slash)
in your dist.ini, it will can parse the C<type> and C<location>
attributes from it. The format is "Readme[TYPE]In[LOCATION]". The
words "Readme" and "In" are optional, and the whole name is
case-insensitive. The SYNOPSIS section above gives one example.

When run with C<location = dist>, this plugin runs in the C<FileMunger> phase
to create the new file. If it runs before another C<FileMunger> plugin does,
that happens to modify the input pod (like, say,
L<C<[PodWeaver]>|Dist::Zilla::Plugin::PodWeaver>), the README file contents
will be recalculated, along with a warning that you should modify your
F<dist.ini> by referencing C<[ReadmeAnyFromPod]> lower down in the file (the
build still works, but is less efficient).

=head1 ATTRIBUTES

=head2 type

The file format for the readme. Supported types are "text",
"markdown", "gfm" (Github-flavored markdown), "pod", and "html". Note
that you are not advised to create a F<.pod> file in the dist itself,
as L<ExtUtils::MakeMaker> will install that, both into C<PERL5LIB> and
C<MAN3DIR>.

=head2 filename

The file name of the README file to produce. The default depends on
the selected format.

=head2 source_filename

The file from which to extract POD for the content of the README. The
default is the file of the main module of the dist. If the main module
has a companion ".pod" file with the same basename, that is used as
the default instead.

=head2 location

Where to put the generated README file. Choices are:

=over 4

=item build

This puts the README in the directory where the dist is currently
being built, where it will be incorporated into the dist.

=item root

This puts the README in the root directory (the same directory that
contains F<dist.ini>). The README will not be incorporated into the
built dist.

=back

If you want to generate the same README file in both the build
directory and the root directory, simply generate it in the build
directory and use the
L<C<[CopyFilesFromBuild]>|Dist::Zilla::Plugin::CopyFilesFromBuild>
plugin to copy it to the dist root.

=head2 phase

At what phase to generate the README file. Choices are:

=over 4

=item build

(Default) This generates the README at 'after build' time. A new
README will be generated each time you build the dist.

=item release

This generates the README at 'after release' time. Note that this is
too late to get the file into the generated tarball, and is therefore
incompatible with C<location = build>. However, this is ideal if you
are using C<location = root> and only want to update the README upon
each release of your module.

=back

=head1 METHODS

=head2 gather_files

We create the file early, so other plugins that need to have the full list of
files are aware of what we will be generating.

=head2 prune_files

Files with C<location = root> must also be pruned, so that they don't
sneak into the I<next> build by virtue of already existing in the root
dir.  (The alternative is that the user doesn't add them to the build in the
first place, with an option to their C<GatherDir> plugin.)

=head2 munge_files

=head2 munge_file

Edits the content into the requested README file in the dist.

=head2 after_build

Create the requested README file at build time, if requested.

=head2 after_release

Create the requested README file at release time, if requested.

=head2 get_readme_content

Get the content of the README in the desired format.

=for Pod::Coverage BUILD

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::ReadmeFromPod> - The base for this module

=item *

L<Dist::Zilla::Plugin::ReadmeMarkdownFromPod> - Functionality subsumed by this module

=item *

L<Dist::Zilla::Plugin::CopyReadmeFromBuild> - Functionality partly subsumed by this module

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHORS

=over 4

=item *

Ryan C. Thompson <rct@thompsonclan.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
