package Papery;

use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

use Papery::Util qw( merge_meta );
use Papery::Pulp;

use File::Spec;
use YAML::Tiny qw( LoadFile );
use Storable qw( dclone );

my %defaults = (
);

sub new {
    my ( $class, $source, $destination, %args ) = @_;

    # checks
    croak "Source directory '$source' doesn't exist"
        if !-e $source;
    croak "Source '$source' is not a directory"
        if !-d $source;

    # read the configuration file
    my ($config) = LoadFile( File::Spec->catfile( $source, '_config.yml' ) );

    # create object
    return bless {
        __source      => $source,
        __destination => $destination,
        __stash       => {},
        __meta        => {
            %defaults, %$config, %args,
            __source      => $source,
            __destination => $destination,
        },
    }, $class;
}

sub generate {
    my ($self) = @_;
    $self->process_tree( dclone( $self->{__meta} ), '' );
}

# $dir is relative to __source
sub process_tree {
    my ( $self, $meta, $dir ) = @_;
    my $absdir = File::Spec->catdir( $self->{__source}, $dir );
    $dir ||= File::Spec->curdir;

    # local metafile for directory
    if ( -e ( my $metafile = File::Spec->catfile( $absdir, '_meta.yml' ) ) ) {
        merge_meta( $meta, LoadFile($metafile) );
    }

    # special directories
    merge_meta(
        $meta,
        {   map      {@$_}             # back to key/value pairs
                grep { -d $_->[1][0] }    # skip non-existing dirs
                map {
                chop( my $name = $_ );
                [ $_ => [ File::Spec->catdir( $absdir, $name ) ] ]
                } qw( _templates- _lib- _hooks+ )
        }
    );

    # process directory
    opendir my $dh, $absdir or die "Can't open $absdir for reading: $!";

FILE:
    for my $file ( File::Spec->no_upwards( readdir($dh) ) ) {


        # always ignore _ files (reserved for Papery)
        next if $file =~ /^_/;

        # relative and absolute path for the file
        my $path    = File::Spec->catfile( $dir,    $file );
        my $abspath = File::Spec->catfile( $absdir, $file );

        # check against ignore list
        for my $check ( @{ $meta->{_ignore} } ) {
            if ( $file =~ /$check/ ) {
                next FILE;
            }
        }

        # recurse into directory
        if ( -d $abspath ) {
            $self->process_tree( $meta, $path );
        }
        else {
            $self->process_file( $meta, $path );
        }
    }
}

sub process_file {
    my ( $self, $meta, $file ) = @_;
    return
        map    { $_->save() }                 # will create final files
        map    { $_->render() }               # may insert Papery::Pulp
        map    { $_->process() }              # may insert Papery::Pulp
        map    { $_->analyze_file($file) }    # may insert Papery::Pulp
        Papery::Pulp->new($meta);             # clone $meta
}

'Vélin';

__END__

=head1 NAME

Papery - The thin layer between what you write and what you publish

=head1 SYNOPSIS

Below is a significant excerpt of the B<papery> command-line tool:

    use Papery;

    # generate the site
    Papery->new( @ARGV )->generate();

=head1 DESCRIPTION

C<Papery> is meant to be a very thin layer between a number of Perl modules
that you can use to generate the files of a static web site.

It is intended to make it very flexible, so that it's easy to add hooks
and specialized modules to generate any file that is needed for the site.

=head2 Workflow

C<Papery> processes entire directory trees containing files and templates,
and for each file that is not ignored, it will run the follwing steps:

=over 4

=item analysis

splits the file between "metadata" and "text", and creates one or more
objects encapsulating those (everything is basically a hash, and the
text is just some special metadata)

=item processing

turns the "text" into "content" by parsing it with a given processor.
For example C<Papery::Processor::Pod::POM> uses C<Pod::POM> to turn
POD text into HTML.

=item rendering

turns the "content" into "output", by processing it through a templating
engine. For example, C<Papery::Renderer::Template> will use Template Toolkit
to process the main template and produce the target file.

=back

Each step takes a C<Papery::Pulp> object, which is basically a hash
of metadata. Each step can return more than one C<Papery::Pulp> object.
After the rendering step, each C<Papery::Pulp> object is saved to a file.

=head2 Metadata

Initial meta information comes from the global configuration (top-level
F<_config.yml> file). It is then updated from the F<_meta.yml> file in
the current directory.

Furthermore, each file can contain metadata for itself, using "YAML Front
Matter":

    ---
    # this is actually YAML
    title: Page title
    ---
    This is the actual content

The metadata comes in three kinds:

=over 4

=item *

variables prefixed with a double underscore (C<__>) are internal to Papery
and set by Papery. They cannot be overwritten by any of F<_config.yml>,
F<_meta.yml> or the YAML front matter

=item *

variables prefixed with a single underscore (C<_>) are reserved for
Papery, and can be overridden by any of F<_config.yml>, F<_meta.yml>
or the YAML front matter

=item *

all the other variables are free to use by the web site itself.

=back

=head2 Papery internal / reserved variables

The metadata variables recognized by Papery are:

=over 4

=item __source

The top-level source directory for the site

=item __destination

The top-level destination directory for the site

=item _analyer

The C<Papery::Analyzer> subclass that will be used to I<analyze> the
source file.

=item _processors

A hash of extentions to C<Papery::Processor> classes

=item _processor

The C<Papery::Processor> subclass that will be used to process I<text>
and generate the I<content>.

=item _renderer

The C<Papery::Renderer> subclass that will be used to render the I<content>
and create the I<output>

=item _text

The I<text> resulting from the analysis step.

=item _content

The I<content> resulting from the processing step.

=item _output

The I<output> resulting from the rendering step.

=item _permalink

The final destination for the I<output>. The filename is relative to
C<__destination>.

=back

Some of the analyzers, processors and renderers may also define their own
variables.

=head1 METHODS

C<Papery> supports the following methods:

=over 4

=item new( $src, $dst )

Create a new C<Papery> object, with the provided I<source> and I<destination>
directories.

=item generate()

Process all the files in the I<source> directory and generate the resulting
files in the I<destination> directory.

=item process_tree( $dir )

Process the C<$dir> tree.

C<$dir> is relative to the I<source> directory.

=item process_file( $file )

Process the C<$file> file, to generate one or more target files.

C<$file> is relative to the I<source> directory.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Much of the inspiration for this module comes from Jekyll
(L<http://jekyllrb.com/>) and Template Toolkit's C<ttree>
(http://www.template-toolkit.org/>).

While my initial goal was to be able to write a web site in POD,
I realized that any format can be turned into HTML and no limitation
on the source format should be imposed on the people. Same goes
for the templating engine. My plan is to make this flexible enough
(using hooks) that one can extend it easily to build any kind of website.

=head1 BUGS

Please report any bugs or feature requests to C<bug-papery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Papery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Here's a list of some of the things ahead:

=over 4

=item *

post_(analyze|process|render) hooks

=item *

post_site hooks (for all those files we need to generate after the whole
site has been generated)

=item *

file copy

=item *

not rebuilding files that don't need to be rebuilt

=item *

dependencies

=item *

support for local F<_lib> and F<_hooks> directories

=item *

more analyzers (e.g. C<Papery::Analyzer::Multiple>)
=item *

more processors (e.g. C<Text::Markdown>)

=item *

more renderers (e.g. C<Text::Template>

=item *


=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Papery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Papery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Papery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Papery>

=item * Search CPAN

L<http://search.cpan.org/dist/Papery>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT


Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

