# ABSTRACT: Static website generator

package StaticVolt;
{
  $StaticVolt::VERSION = '1.00';
}

use strict;
use warnings;

use Cwd qw( getcwd );
use File::Copy qw( copy );
use File::Find;
use File::Path qw( mkpath rmtree );
use File::Spec;
use FindBin;
use Template;
use YAML;

use base qw( StaticVolt::Convertor );

use StaticVolt::Convertor::Markdown;
use StaticVolt::Convertor::Textile;

sub new {
    my ( $class, %config ) = @_;

    my %config_defaults = (
        'includes'    => '_includes',
        'layouts'     => '_layouts',
        'source'      => '_source',
        'destination' => '_site',
    );

    for my $config_key ( keys %config_defaults ) {
        $config{$config_key} = $config{$config_key}
          || $config_defaults{$config_key};
        $config{$config_key} = File::Spec->canonpath( $config{$config_key} );
    }

    return bless \%config, $class;
}

sub _clean_destination {
    my $self = shift;

    my $destination = $self->{'destination'};
    rmtree $destination;

    return;
}

sub _traverse_files {
    my $self = shift;

    push @{ $self->{'files'} }, $File::Find::name;

    return;
}

sub _gather_files {
    my $self = shift;

    my $source = $self->{'source'};
    find sub { _traverse_files $self }, $source;

    return;
}

sub _extract_file_config {
    my ( $self, $fh_source_file ) = @_;

    my $delimiter = qr/^---\n$/;
    if ( <$fh_source_file> =~ $delimiter ) {
        my @yaml_lines;
        while ( my $line = <$fh_source_file> ) {
            if ( $line =~ $delimiter ) {
                last;
            }
            push @yaml_lines, $line;
        }

        return Load join '', @yaml_lines;
    }
}

sub compile {
    my $self = shift;

    $self->_clean_destination;
    $self->_gather_files;

    my $source      = $self->{'source'};
    my $destination = $self->{'destination'};
    for my $source_file ( @{ $self->{'files'} } ) {
        my $destination_file = $source_file;
        $destination_file =~ s/^$source/$destination/;
        if ( -d $source_file ) {
            mkpath $destination_file;
            next;
        }

        open my $fh_source_file, '<', $source_file
          or die "Failed to open $source_file for input: $!";
        my $file_config = $self->_extract_file_config($fh_source_file);

        # For files that do not have a configuration defined, copy them over
        unless ($file_config) {
            copy $source_file, $destination_file;
            next;
        }

        my ($extension) = $source_file =~ m/\.(.+?)$/;

        # If file does not have a registered convertor and is not an HTML file,
        # copy the file over to the destination and skip current loop iteration
        if ( !$self->has_convertor($extension) && $extension ne 'html' ) {
            copy $source_file, $destination_file;
            next;
        }

        # Only files that have a registered convertor need to be handled

        $destination_file =~ s/\..+?$/.html/;    # Change extension to .html

        my $file_layout      = $file_config->{'layout'};
        my $includes         = $self->{'includes'};
        my $layouts          = $self->{'layouts'};
        my $abs_include_path = File::Spec->catfile( getcwd, $includes );
        my $abs_layout_path =
          File::Spec->catfile( getcwd, $layouts, $file_layout );
        my $template = Template->new(
            'INCLUDE_PATH' => $abs_include_path,
            'WRAPPER'      => $abs_layout_path,
            'ABSOLUTE'     => 1,
        );

        my $source_file_content = do { local $/; <$fh_source_file> };
        my $converted_content;
        if ( $extension eq 'html' ) {
            $converted_content = $source_file_content;
        }
        else {
            $converted_content =
              $self->convert( $source_file_content, $extension );
        }

        $file_config->{sv_rel_base} = $self->_relative_path ( $destination_file );

        open my $fh_destination_file, '>', $destination_file
          or die "Failed to open $destination_file for output: $!";
        if ($file_layout) {
            $template->process( \$converted_content, $file_config,
                $fh_destination_file )
              or die $template->error;
        }
        else {
            print $fh_destination_file $converted_content;
        }

        close $fh_source_file;
        close $fh_destination_file;
    }
}


sub _relative_path {

    my ($self,$dest_file) = @_;

    my ($dummy1,$dest_file_dir,$dummy2) = File::Spec->splitpath( $dest_file );

    my $rel_path = File::Spec->abs2rel ( $self->{'destination'},
                                         $dest_file_dir );

    $rel_path .= "/" if $rel_path;

    return $rel_path;

};

1;

__END__

=pod

=head1 NAME

StaticVolt - Static website generator

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use StaticVolt;

    my $staticvolt = StaticVolt->new;  # Default configuration
    $staticvolt->compile;

=over

=item C<new>

Accepts an optional hash with the following parameters:

    # Override configuration (parameters set explicitly)
    my $staticvolt = StaticVolt->new(
        'includes'    => '_includes',
        'layouts'     => '_layouts',
        'source'      => '_source',
        'destination' => '_site',
    );

=over 4

=item * C<includes>

Specifies the directory in which to search for template files. By default, it
is set to C<_includes>.

=item * C<layouts>

Specifies the directory in which to search for layouts or wrappers. By default,
it is set to C<_layouts>.

=item * C<source>

Specifies the directory in which source files reside. Source files are files
which will be compiled to HTML if they have a registered convertor and a YAML
configuration in the beginning. By default, it is set to C<_source>.

=item * C<destination>

This directory will be created if it does not exist. Compiled and output files
are placed in this directory. By default, it is set to C<_site>.

=back

=item C<compile>

Each file in the L</C<source>> directory is checked to see if it has a
registered convertor as well as a YAML configuration at the beginning. All such
files are compiled considering the L</YAML Configuration Keys> and the compiled
output is placed in the L</C<destination>> directory. The rest of the files are
copied over to the L</C<destination>> without compiling.

=back

=head2 YAML Configuration Keys

L</YAML Configuration Keys> should be placed at the beginning of the file and
should be enclosed within a pair of C<--->.

Example of using a layout along with a custom key and compiling a markdown
L</C<source>> file:

L</layout> file - C<main.html>:

    <!DOCTYPE html>
    <html>
        <head>
            <title></title>
        </head>
        <body>
            [% content %]
        </body>
    </html>

L</source> file - C<index.markdown>:

    ---
    layout: main.html
    drink : water
    ---
    Drink **plenty** of [% drink %].

L</destination> (output/compiled) file - C<index.html>:

    <!DOCTYPE html>
    <html>
        <head>
            <title></title>
        </head>
        <body>
            <p>Drink <strong>plenty</strong> of water.</p>

        </body>
    </html>

=over 4

=item * C<layout>

Uses the corresponding layout or wrapper to wrap the compiled content. Note that
C<content> is a special variable used in C<L<Template Toolkit|Template>> along
with wrappers. This variable contains the processed wrapped content. In essence,
the output/compiled file will have the C<content> variable replaced with the
compiled L</C<source>> file.

=item * C<I<custom keys>>

These keys will be available for use in the same page as well as in the layout.
In the above example, C<drink> is a custom key.

=back

=head2 Pre-defined template variables

Some variables are automatically made available to the
templates. Apart from C<content> described elsewhere, these are all
prefixed C<sv_> to differentiate them from user variables.

=over

=item sv_rel_base

If the generated web-site is being used without a web-server (i.e. just
on the local file-system), or perhaps if it may be moved around in the
web-server hierarchy, then absolute URIs to shared resouces like CSS
or JS will not work.

Relative paths can be used in these situations.

C<sv-rel-base> provides a relative path from the source file being
processed to the top of the generated web-site. This means that layout
files can refer to shared files like CSS using the following in a
layout file:

    <link rel="stylesheet" type="text/css" href="[% sv_rel_base %]css/bootstrap.css" />

For top level source files, this expands to C<./>. For any
sub-directories, it expands to C<../>, C<../../> etc. Sub-directory
expansions always include the trailing slash.

=back

=head1 Walkthrough

Consider the source file C<index.markdown> which contains:

    ---
    layout : main.html
    title  : Just an example title
    heading: StaticVolt Example
    ---

    StaticVolt Example
    ==================

    This is an **example** page.

Let C<main.html> which is a wrapper or layout contain:

    <!DOCTYPE html>
    <html>
        <head>
            <title>[% title %]</title>
        </head>
        <body>
            [% content %]
        </body>
    </html>

During compilation, all variables defined as L</YAML Configuration Keys> at the
beginning of the file will be processed and be replaced by their values in the
output file C<index.html>. A registered convertor
(C<L<StaticVolt::Convertor::Markdown>>) is used to convert the markdown text to
HTML.

Compiled output file C<index.html> contains:

    <!DOCTYPE html>
    <html>
        <head>
            <title>Just an example title</title>
        </head>
        <body>
            <h1>StaticVolt Example</h1>
            <p>This is an <strong>example</strong> page.</p>

        </body>
    </html>

=head1 Default Convertors

=over 4

=item * C<L<StaticVolt::Convertor::Markdown>>

=item * C<L<StaticVolt::Convertor::Textile>>

=back

=head1 How to build a convertor?

The convertor should inherit from L<C<StaticVolt::Convertor>>. Define a
subroutine named C<L<StaticVolt::Convertor/convert>> that takes a single argument. This argument should
be converted to HTML and returned.

Register filename extensions by calling the C<register> method inherited from
L<C<StaticVolt::Convertor>>. C<register> accepts a list of filename extensions.

A convertor template that implements conversion from a hypothetical format
I<FooBar>:

    package StaticVolt::Convertor::FooBar;

    use strict;
    use warnings;

    use base qw( StaticVolt::Convertor );

    use Foo::Bar qw( foobar );

    sub convert {
        my $content = shift;
        return foobar $content;
    }

    # Handle files with the extensions:
    #   .foobar, .fb, .fbar, .foob
    __PACKAGE__->register(qw/ foobar fb fbar foob /);

=head1 Inspiration

L<StaticVolt> is inspired by Tom Preston-Werner's L<Jekyll|http://jekyllrb.com/>.

=head1 Success Stories

Charles Wimmer successfully uses StaticVolt to generate and maintain his
L<website|http://www.wimmer.net/>. He describes it in his
L<post|http://www.wimmer.net/sysadmin/2012/08/11/hosting-a-static-website-in-the-cloud/>.

If you wish to have your website listed here, please send an e-mail to
C<haggai@cpan.org>, and I will be glad to list it here. :-)

=head1 Contributors

L<Gavin Shelley|https://github.com/columbusmonkey>

=head1 Acknowledgements

L<Shlomi Fish|http://www.shlomifish.org/> for suggesting change of licence.

=head1 See Also

L<Template Toolkit|Template>

=head1 AUTHOR

Alan Haggai Alavi <haggai@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alan Haggai Alavi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
