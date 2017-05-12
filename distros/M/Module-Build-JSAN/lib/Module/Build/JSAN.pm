package Module::Build::JSAN;

# $Id$

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.05';
use Module::Build;
@ISA = qw(Module::Build);
use File::Spec::Functions qw(catdir catfile);
use File::Basename qw(dirname);

sub new {
    my $pkg = shift;
    my %p = @_;
    $p{metafile} ||= 'META.json';
    if (my $keywords = delete $p{keywords} || delete $p{tags}) {
        if ($p{meta_merge}) {
            $p{meta_merge}->{keywords} = $keywords
        } else {
            $p{meta_merge} = { keywords => $keywords };
        }
    }
    return $pkg->SUPER::new(%p);
}


sub ACTION_dist {
    my $self = shift;

    require Pod::Simple::HTML;
    require Pod::Simple::Text;
    require Pod::Select;

    for (qw(html text pod)) {
        my $dir = catdir 'doc', $_;
        unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755)
                or die "Couldn't mkdir $dir: $!";
            $self->add_to_cleanup($dir);
        }
    }

    my $lib_dir  = catdir 'lib';
    my $pod_dir  = catdir 'doc', 'pod';
    my $html_dir = catdir 'doc', 'html';
    my $txt_dir  = catdir 'doc', 'text';

    my $js_files = $self->find_dist_packages;
    foreach my $file (map { $_->{file} } values %$js_files) {
        (my $pod = $file) =~ s|^$lib_dir|$pod_dir|;
        $pod =~ s/\.js$/.pod/;
        my $dir = dirname $pod;
		unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755)
                or die "Couldn't mkdir $dir: $!";
		}
        # Ignore existing documentation files.
        next if -e $pod;
        open my $fh, ">", $pod or die "Cannot open $pod: $!\n";

        Pod::Select::podselect( { -output => $fh }, $file );

        print $fh "\n=cut\n";

        close $fh;
    }

    for my $pod (@{Module::Build->rscan_dir($pod_dir, qr/\.pod$/)}) {
        # Generate HTML docs.
        (my $html = $pod) =~ s|^\Q$pod_dir|$html_dir|;
        $html =~ s/\.pod$/.html/;
        my $dir = dirname $html;
		unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755)
                or die "Couldn't mkdir $dir: $!";
		}
        open my $fh, ">", $html or die "Cannot open $html: $!\n";
        my $parser = Pod::Simple::HTML->new;
        $parser->output_fh($fh);
        $parser->parse_file($pod);
        close $fh;

        # Generate text docs.
        (my $txt = $pod) =~ s|^\Q$pod_dir|$txt_dir|;
        $txt =~ s/\.pod$/.txt/;
        $dir = dirname $txt;
		unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755)
                or die "Couldn't mkdir $dir: $!";
		}
        open $fh, ">", $txt or die "Cannot open $txt: $!\n";
        $parser = Pod::Simple::Text->new;
        $parser->output_fh($fh);
        $parser->parse_file($pod);
        close $fh;
    }
    $self->depends_on('manifest');

    $self->depends_on('distdir');

    my $dist_dir = $self->dist_dir;

    $self->_strip_pod($dist_dir);

    $self->make_tarball($dist_dir);
    $self->delete_filetree($dist_dir);


#    $self->add_to_cleanup('META.json');
#    $self->add_to_cleanup('*.gz');
}

sub ACTION_manifest {
    my $self = shift;
    $self->SUPER::ACTION_manifest(@_);
    $self->add_to_cleanup('MANIFEST.bak');
}

sub ACTION_deps {
    my $self = shift;

    my $prefix = './tests/lib';

    require JSAN::Shell;
    my $jsan = JSAN::Shell->new;
    $jsan->index;

    my @deps = (
        keys( %{$self->{properties}{build_requires}} ),
        keys( %{$self->{properties}{requires}} ),
    );

    eval { $jsan->install( $_, $prefix ) }, ($@ && print$@)
        for @deps;

    $self->add_to_cleanup( $prefix );
}

sub dist_version {
    my $self = shift;
    my $p = $self->{properties};
    return $p->{dist_version} if defined $p->{dist_version};

    if ($self->module_name) {
        $p->{dist_version_from} ||=
          join( '/', 'lib', split /\./, $self->module_name ) . '.js';
        print $p->{dist_version_from}, $/;
    }

    die "Can't determine distribution version, must supply either "
      . "'dist_version',\n'dist_version_from', or 'module_name' parameter"
      unless $p->{dist_version_from};

    # Search for the version number.
    return $p->{dist_version} = $self->_parse_version(
        $self->module_name,
        $p->{dist_version_from}
    );
}

sub find_js_files  { shift->_find_file_by_type('js',  'lib') }

sub find_dist_packages {
    my $self = shift;
    # Only packages in .js files are candidates for inclusion here.
    # Only include things in the MANIFEST, not things in developer's
    # private stock.

    my $manifest = $self->_read_manifest('MANIFEST')
      or die "Can't find dist packages without a MANIFEST file "
        . "- run 'manifest' action first";

    # Localize
    my %dist_files = map { $self->localize_file_path($_) => $_ }
      keys %$manifest;

    my @js_files = grep {exists $dist_files{$_}} keys %{ $self->find_js_files };

    my %out;
    for my $file (@js_files) {
        next if $file =~ m{^t/};  # Skip things in t/

        # Assume that the file name corresponds to the library. This may need
        # to be more sophisticated in the future, but will do for now.
        (my $lib = $file) =~ s|^[^/]+/||;
        $lib = join '.', split m{/}, $lib;
        $lib =~ s/\.js$//;
        $out{$lib} = {
            file => $dist_files{$file},
            version => $self->_parse_version($lib, $file),
        };
    }
    return \%out;
}

sub _parse_version {
    my ($self, $lib, $file) = @_;
    my $version_from = File::Spec->catfile( split m{/}, $file );
    open VF, "<$version_from" or die "Cannot open '$version_from': $!\n";
    my $version = '';
    my $find    = qr/VERSION\s*(?:=|:)\s*[^\d._]*([\d._]+)/;
    while (<VF>) {
        last if ($version) = /$find/;
    }
    close VF;
    return $version;
}

sub write_metafile {
    my $self = shift;
    my $metafile = $self->metafile;

    require Module::Build::JSAN::ConfigData;  # Only works after the 'build'
    if (Module::Build::JSAN::ConfigData->feature('JSON_support')) {
        require JSON;
        $self->prepare_metadata( my $node = {} );
        open my $meta, '>', $metafile or die "Cannot open '$metafile': $!\n";
        print $meta JSON->new->pretty->encode( $node );
        close $meta;
    } else {
        $self->log_warn(
            "\nCouldn't load JSON.pm, generating a minimal META.json without ",
            "it.\nPlease check and edit the generated metadata, or consider ",
            "installing\nJSON.pm.\n\n"
        );
        $self->_write_minimal_metadata;
    }
    $self->_add_to_manifest('MANIFEST', $metafile);
}

sub _write_minimal_metadata {
    my $self = shift;
    my $p = $self->{properties};

    my $file = $self->metafile;
    my $fh = IO::File->new("> $file") or die "Can't open $file: $!";

  # XXX Add the meta_add & meta_merge stuff
  print $fh <<"END_OF_META";
{
    "name": "$p->{dist_name}",
    "version": "$p->{dist_version}",
    "author":
    @{[ join "\n", map qq{  "$_"}, @{$self->dist_author} ]},
    "abstract": "@{[ $self->dist_abstract ]}",
    "license": "$p->{license}",
    "generated_by": "Module::Build::JSAN version $Module::Build::JSAN::VERSION, without JSON.pm"
}
END_OF_META
}

sub _write_default_maniskip {
    my $self = shift;
    my $file = shift || 'MANIFEST.SKIP';

    $self->SUPER::_write_default_maniskip($file);

    my $fh = IO::File->new(">> $file")
      or die "Can't open $file: $!";
    print $fh <<'EOF';
^Build.PL$
.tar.gz$
^tests/lib/
EOF
    print $fh $self->dist_dir, "\n";
    $fh->close();
}

sub _strip_pod {
    my ($self, $dist_dir) = @_;

    require Pod::Stripper;

    my $files    = $self->find_js_files;
    my $stripper = Pod::Stripper->new;
    foreach my $from ( keys %{$files} ) {
        my $to = catfile $dist_dir, $from;
        # This will leave empty comment blocks intact.
        # That looks odd. Pod::Stripper::JSAN should be made.
        chmod 0644, $to;
        $stripper->parse_from_file($from => $to);
        chmod 0444, $to;
    }
}

sub check_prereq {  }
sub ignore_prereqs { 1 }

1;
__END__

=head1 NAME

Module::Build::JSAN - Build JavaScript distributions for JSAN

=head1 SYNOPSIS

In F<Build.PL>:

  use Module::Build::JSAN;

  my $build = Module::Build::JSAN->new(
      module_name    => 'Foo.Bar',
      license        => 'perl',
      keywords       => [qw(Foo Bar pithyness)],
      requires     => {
          'JSAN'     => 0.10,
          'Baz.Quux' => 0.02,
      },
      build_requires => {
          'Test.Simple' => 0.20,
      },
  );

  $build->create_build_script;

To build a distribution:

  % perl Build.PL
  % ./Build dist

=head1 DESCRIPTION

This is a developer aid for creating JSAN distributions. JSAN is the
"JavaScript Archive Network," a JavaScript library akin to CPAN. Visit
L<http://www.openjsan.org/> for details.

This module works nearly identically to L<Module::Build>, so please refer to
its documentation.

=head1 DIFFERENCES

=over 4

=item 1 META.json

JSAN uses the JSON format instead of the YAML format for META files, as JSON
is legal Javascript and just plain easier to work with. This means that
Module::Build::JSAN will generate F<META.json> files instead of F<META.yml>
files. Do not be alarmed. See L<http://www.json.org/> for more information on
JSON.

=item 2 ./Build deps

This is a new action added to Module::Build::JSAN. Run this action in order to
update your JSAN dependencies while developing your JSAN library. This will
allow you to develop against the latest versions of the distributions upon
which your library depends.

=item 3. ./Build dist

This action overrides that provided by Module::Build to extract all
documentation from your source files or from F<doc/pod> and convert them into
HTML and plain text representations in F<doc/html> and F<doc/text>,
respectively. This keeps your F<.js> libraries free of the weight of
documentation in the distribution.

=item 4. Version, Abstract, Author

Like Module::Build, Module::Build::JSAN will extract the module version
number, abstract, and author from the JavaScript file for which the
distribution is named. The abstract and author will only be extracted
if they are specified in POD in the mode of Perl CPAN modules, i.e.:

  /*

  =head1 NAME

  Foo.Bar - Foo your Bar, baby

  =head1 AUTHOR

  Joe Developer <joe@foobar.com>

  */

The version number will be parsed from the JavaScript code only if it is
specified in one of the following manners:

  Foo.Bar.VERSION = '0.34';

  Foo.Bar = {
      VERSION: '0.34'
  }

If none of these options works for you for some reason, just specify the
abstract, author, and version number in your F<Build.PL> file:

  my $build = Module::Build::JSAN->new(
      module_name    => 'Foo.Bar',
      dist_author    => 'Joe Developer <joe@foobar.com>',
      dist_abstract  => 'Say something pithy here',
      dist_version   => '0.34',
      # ...
  );

=back

=head1 SEE ALSO

=over

=item L<http://www.openjsan.org/>

Home of the JavaScript Archive Network.

=item L<http://www.json.org/>

Home page for JSON, the JavaScript Object Notation, which the format used in
the F<META.json> file generated by this module.

=item L<http://justatheory.com/computers/programming/javascript/emulating_namespaces.html>

The description of JavaScript namespaces on which JSAN modules are based.

=back

=head1 SUPPORT

This module is stored in an open repository at the following address:

L<http://github.com/theory/module-build-jsan/tree/>

Patches against Module::Build::JSAN are welcome. Please send bug reports to
Please send bug reports to <bug-module-build-jsan@rt.cpan.org>.

=head1 AUTHORS

=over

=item David Wheeler <david@kineticode.com>

=item Casey West <casey@geeknest.com>

=item Rob Kinyon <rob.kinyon@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2009 by David Wheeler, Casey West, and Rob Kinyon. Some Rights
Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
