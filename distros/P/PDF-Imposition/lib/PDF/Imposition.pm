package PDF::Imposition;

use strict;
use warnings;
use Module::Load;
use Types::Standard qw/Enum Object Maybe Str HashRef/;
use File::Temp;
use File::Copy;
use File::Spec;
use File::Basename;
use Data::Dumper;
use PDF::Cropmarks;
use namespace::clean;

use constant {
    DEBUG => $ENV{AMW_DEBUG},
};

use Moo;

=head1 NAME

PDF::Imposition - Perl module to manage the PDF imposition

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';

sub version {
    return "PDF::Imposition $VERSION PDF::Cropmarks "
      . $PDF::Cropmarks::VERSION;
}


=head1 SYNOPSIS

This module is meant to simplify the so-called imposition, i.e.,
rearrange the pages of a PDF to get it ready to be printed and folded,
with more logical pages placed on the sheet, usually (but not
exclusively) on recto and verso.

This is what the routine looks like:

    use PDF::Imposition;
    my $imposer = PDF::Imposition->new(file => "test.pdf",
                                       outfile => "out.pdf",
                                       # or # suffix => "-imposed",
                                       signature => "40-80",
                                       cover => 0,
                                       schema => "2up");
    $imposer->impose;
    print "Output left in " . $imposer->outfile;


Please note that you don't pass the PDF dimensions (which are
extracted from the source PDF itself by the class, using the very
first page: if you want imposition, I do the reasonable assumption you
have all the pages with the same dimensions).

=head1 METHODS

=head2 Costructor options and accessors

=head3 file

The input file

=head3 outfile

The output file

=head3 suffix

The suffix of the output file (don't mix the two options).

=head3 schema

The schema to use.

=over 4 

=item 2up

See L<PDF::Imposition::Schema2up>

=item 2down

See L<PDF::Imposition::Schema2down>

=item 2x4x1

See L<PDF::Imposition::Schema2x4x1>

=item 2x4x2

See L<PDF::Imposition::Schema2x4x2>

=item 2side

See L<PDF::Imposition::Schema2side>

=item 4up

See L<PDF::Imposition::Schema4up>

=item 1x4x2cutfoldbind

See L<PDF::Imposition::Schema1x4x2cutfoldbind>

=item 1repeat2top

See L<PDF::Imposition::Schema1repeat2top>

=item 1repeat2side

See L<PDF::Imposition::Schema1repeat2side>

=item 1repeat4

See L<PDF::Imposition::Schema1repeat4>

=item ea4x4

See L<PDF::Imposition::Schemaea4x4>

=item 1x8x2

See L<PDF::Imposition::Schema1x8x2>

=item 1x1

See L<PDF::Imposition::Schema1x1>

=back

=head3 cover

If the last logical page must be placed at the very end, B<after> the
blank pages used to pad the signature. (C<2up>, C<2down>
C<1x4x2cutfoldbind>, C<4up>, C<1x1> only).

Often it happens that we want the last page of the pdf to be the last
one on the physical booklet after folding. If C<cover> is set to a
true value, the last page of the logical pdf will be placed on the
last page of the last signature.

=head3 signature

The signature (integer multiple of four or range): C<2up> and C<2down> only.

=head3 paper

Passing this option triggers the cropmarks. While the original
dimensions are left unchanged, this size represents the size of the
logical page which is actually imposed.

For example, you have a PDF in a6, you pass C<a5> as paper, and schema
C<2up>, you are going to get an a4 with 2 a6 with cropmarks.

This option is passed to L<PDF::Cropmarks>. See the module
documentation for the accepted values.

=head3 title

The title to set in the PDF meta information. Defaults to the basename.

=head2 Cropmarks options

The following options are passed verbatim to L<PDF::Cropmarks>. See
the module documentation for the meaning and accepted values.

=head3 paper_thickness

Defaults to C<0.1mm>

=head3 font_size

Defaults to C<8pt>

=head3 cropmark_offset

Defaults to C<1mm>

=head3 cropmark_length

Defaults to C<12mm>

=head2 impose

Main method which does the actual job. You have to call this to get
your file. It returns the output filename.

=head2 version

Return the version string.

=cut

sub BUILDARGS {
    my ($class, %options) = @_;
    my $schema = lc(delete $options{schema} || '2up'); #  default
    $options{_version} = $class->version;
    my $loadclass = __PACKAGE__ . '::Schema' . $schema;
    my %our_options;
    foreach my $cropmark_opt (qw/paper
                                 cropmark_offset
                                 cropmark_length
                                 font_size
                                 paper_thickness/) {
        if (exists $options{$cropmark_opt}) {
            $our_options{$cropmark_opt} = $options{$cropmark_opt};
        }
    }
    load $loadclass;
    unless ($options{title}) {
        if ($options{file}) {
            $options{title} = basename($options{file});
        }
    }

    my $imposer = $loadclass->new(%options);
    $our_options{imposer} = $imposer;
    $our_options{schema} = $schema;
    $our_options{_schema_class} = $loadclass;
    $our_options{title} = $options{title};
    $our_options{_schema_options} = { %options };
    return \%our_options;
}

has schema => (is => 'ro',
               required => 1,
               isa => Enum[__PACKAGE__->available_schemas]);

has _schema_class => (is => 'ro',
                     isa => Str,
                     required => 1);

has _schema_options => (is => 'ro',
                       isa => HashRef,
                       required => 1);

has imposer => (is => 'rwp',
                required => 1,
                handles => [qw/file outfile suffix
                               cover
                               signature
                               computed_signature
                               total_pages
                               orig_width
                               orig_height
                               dimensions
                               total_output_pages
                              /],
                isa => Object);

has paper => (is => 'ro',
              isa => Maybe[Str]);

has paper_thickness => (is => 'ro',
                        isa => Str,
                        default => sub { '0.1mm' });

has cropmark_offset => (is => 'ro',
                        isa => Str,
                        default => sub { '1mm' });

has cropmark_length => (is => 'ro',
                        isa => Str,
                        default => sub { '12mm' });

has font_size => (is => 'ro',
                  isa => Str,
                  default => sub { '8pt' });

has title => (is => 'ro',
              isa => Maybe[Str]);

has job_name => (is => 'lazy',
                 isa => Str);

sub _build_job_name {
    my $self = shift;
    my $name = $self->title || basename($self->file);
    return $name;
}

sub impose {
    my $self = shift;
    my $tmpdir = File::Temp->newdir(CLEANUP => !DEBUG);
    if (my $cropmark_paper = $self->paper) {
        my %imposer_options = %{ $self->_schema_options };
        # clone the parameter and set outfile and file

        $imposer_options{outfile} ||= $self->imposer->output_filename;
        my $crop_output = $imposer_options{file} = File::Spec->catfile($tmpdir, 'with-crop-marks.pdf');

        # pass it to cropmarks
        my %crop_args = (
                         title => $self->job_name,
                         input => $self->file,
                         output => $crop_output,
                         paper => $cropmark_paper,
                         cover => $imposer_options{cover},
                         signature => $self->imposer->computed_signature,
                         paper_thickness => $self->paper_thickness,
                         cropmark_offset => $self->cropmark_offset,
                         cropmark_length => $self->cropmark_length,
                         font_size => $self->font_size,
                         $self->imposer->cropmarks_options,
                        );
        print Dumper(\%crop_args) if DEBUG;

        # rebuild the imposer, which should free the memory as well
        $self->_set_imposer($self->_schema_class->new(%imposer_options));

        my $cropper = PDF::Cropmarks->new(%crop_args);
        $cropper->add_cropmarks;
        print "# cropping output in $crop_output\n" if DEBUG;
        print Dumper($self->imposer) if DEBUG;
    }
    # in any case impose
    return $self->imposer->impose;
}

=head2 available_schemas

Called on the class (not on the object returned by C<new>) will report
the list of available schema.

E.g.

 PDF::Imposition->available_schemas;

=cut

sub available_schemas {
    return qw/2up 2down 2side 2x4x2 1x4x2cutfoldbind
              2x4x1
              4up 1repeat2top 1repeat2side 1repeat4 ea4x4
              1x8x2 1x1/
}

=head1 INTERNALS

=over 4

=item BUILDARGS

=item imposer

=back

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email. If
you find a bug, please provide a minimal example file which reproduces
the problem (so I can add it to the test suite).

Or, at your discretion, feel free to use the CPAN's RT.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDF::Imposition

=head1 REPOSITORY

L<https://github.com/melmothx/pdf-imposition-perl>

=head1 SEE ALSO

=over 4

=item psutils

L<http://knackered.org/angus/psutils/> (shipped by any decent
GNU/Linux distro and in TeXlive!). If you don't bother the
PDF->PS->PDF route, it's a great and useful tool which just aged well.

=item pdfpages

L<http://www.ctan.org/pkg/pdfpages>

=item pdfjam

L<http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/firth/software/pdfjam/>
(buil on the top of pdfpages)

=item ConTeXt

L<http://wiki.contextgarden.net/Imposition>

The names of schemas are taken straight from the ConTeXt ones (if
existing), as described in the book I<Layouts in context>, by Willi
Egger, Hans Hagen and Taco Hoekwater, 2011.

=back

=head1 TODO

The idea is to provide a wide range of imposition schemas (at least
the same provided by ConTeXt). This could require some time. If you
want to contribute, feel free to fork the repository and send a pull
request or a patch (please include documentation and at some tests).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

=cut

1; # End of PDF::Imposition
