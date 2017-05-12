package PDF::Imposition::Schema;
use strict;
use warnings;

use File::Basename qw/fileparse/;
use File::Spec;
use PDF::API2;
use File::Temp ();
use File::Copy;
use POSIX ();
use Types::Standard qw/Int Bool Num HashRef Str Maybe Object Enum/;

use Moo::Role;
requires qw(_do_impose);

use constant { DEBUG => $ENV{AMW_DEBUG} };

=head1 NAME

PDF::Imposition::Schema - Role for the imposition schemas.

=head1 SYNOPSIS

This class provides the shared method for real imposition schemas and
can't me called directly.

Consuming classes must provide a C<_do_impose> method.

    use PDF::Imposition;
    my $imposer = PDF::Imposition->new(file => "test.pdf",
                                       # either use 
                                       outfile => "out.pdf",
                                       # or suffix
                                       suffix => "-2up"
                                      );
    $imposer->impose;
or 

    use PDF::Imposition;
    my $imposer = PDF::Imposition->new();
    $imposer->file("test.pdf");
    
    $imposer->outfile("out.pdf");
    # or
    $imposer->suffix("-imp");

    $imposer->impose;
  
=head1 METHODS

=head2 Read/write accessors

All the following accessors accept an argument, which sets the
value.

=head3 file

Unsurprisingly, the input file, which must exist.

=cut

has _version => (is => 'ro',
                 isa => Str,
                 default => sub { 'PDF::Imposition' });

has file => (is => 'rw',
             isa => sub { die "$_[0] is not a pdf" unless $_[0] && $_[0] =~ m/\.pdf\z/i });

has _tmp_dir => (is => 'ro',
                 default => sub { File::Temp->newdir(CLEANUP => 1); });

=head3 outfile

The destination file of the imposition. You may prefer to use the
suffix method below, which takes care of the filename.

=head3 suffix

The suffix of the file. By default, '-imp', so test.pdf imposed will
be saved as 'test-imp.pdf'. If test-imp.pdf already exists, it will be
replaced merciless.

=cut

has outfile =>  (is => 'rw',
                 isa => sub { die "$_[0] is not a pdf file"
                                unless $_[0] && $_[0] =~ m/\.pdf\z/i });

has suffix => (is => 'rw',
               isa => Str,
               default => sub { '-imp' });

=head3 signature($num_or_range)

The signature, must be a multiple of the C<pages_per_sheet> option
(usually 4 or 8), or a range, like the string "20-100". If a range is
selected, the signature is determined heuristically to minimize the
white pages left on the last signature. The wider the range, the better
the results.

=cut

has signature => (is => 'rw',
                  isa => Str,
                  default => sub { '0' });

=head3 pages_per_sheet

The number of logical pages which fit on a sheet, recto-verso. Default
to 1. Subclasses usually change this and ignore your option unless
otherwise specified.

=head3 title

The title to set in the PDF meta information. Defaults to the basename.

=cut

has pages_per_sheet => (is => 'ro',
                        default => sub { 1 },
                        isa => Enum[qw/1 2 4 8 16 32/]);

sub _optimize_signature {
    my ($self, $sig, $total_pages) = @_;
    unless ($total_pages) {
        $total_pages = $self->total_pages;
    }
    return 0 unless $sig;
    my $ppsheet = $self->pages_per_sheet or die;
    print "# pages per sheet is $ppsheet\n" if DEBUG;
    if ($sig =~ m/^[0-9]+$/s) {
        die "Signature must be a multiple of $ppsheet" if $sig % $ppsheet;
        return $sig;
    }
    my ($min, $max);
    if ($sig =~ m/^([0-9]+)?-([0-9]+)?$/s) {
        $min = $1 || $ppsheet;
        $max = $2 || $total_pages;
        $min = $min + (($ppsheet - ($min % $ppsheet)) % $ppsheet);
        $max = $max + (($ppsheet - ($max % $ppsheet)) % $ppsheet);
        die "Bad range $max - $min" unless $max > $min;
        die "bad min $min" if $min % $ppsheet;
        die "bad max $max" if $max % $ppsheet;
    }
    else {
        die "Unrecognized range $sig";
    }
    my $signature = 0;
    my $roundedpages = $total_pages + (($ppsheet - ($total_pages % $ppsheet)) % $ppsheet);
    my $needed = $roundedpages - $total_pages;
    die "Something is wrong" if $roundedpages % $ppsheet;
    if ($roundedpages <= $min) {
        wantarray ? return ($roundedpages, $needed) : return $roundedpages;
    }
    $signature = $self->_find_signature($roundedpages, $max);
    if ($roundedpages > $max) {
        while ($signature < $min) {
            $roundedpages += $ppsheet;
            $needed += $ppsheet;
            $signature = $self->_find_signature($roundedpages, $max)
        }
    }
    # warn "Needed $needed blank pages";
    wantarray ? return ($signature, $needed) : return $signature;
}

sub _find_signature {
    my ($self, $num, $max) = @_;
    my $ppsheet = $self->pages_per_sheet or die;
    die "not a multiple of $ppsheet" if $num % $ppsheet;
    die "uh?" unless $num;
    my $i = $max;
    while ($i > 0) {
        # check if the the pagenumber is divisible by the signature
        # with modulo 0
        # warn "trying $i for $num / max $max\n";
        if (($num % $i) == 0) {
            return $i;
        }
        $i -= $ppsheet;
    }
    warn "_find_signature loop ended with no result\n";
}



=head2 Internal methods accessors

The following methods are used internally but documented for schema's
authors.

=head3 dimensions

Returns an hashref with the original pdf dimensions in points.

  { w => 800, h => 600 }

=head3 orig_width

=head3 orig_height

=head3 total_pages

Returns the number of pages


=cut

has dimensions => (is => 'lazy',
                   isa => HashRef[Num]);

sub _build_dimensions {
    my $self = shift;
    my $pdf = $self->in_pdf_obj;
    my ($x, $y, $w, $h) = $pdf->openpage(1)->get_mediabox; # use the first page
    warn $self->file . "use x-y offset, cannot proceed safely" if ($x + $y);
    die "Cannot retrieve paper dimensions" unless $w && $h;
    my %dimensions = (
                      w => sprintf('%.2f', $w),
                      h => sprintf('%.2f', $h),
                     );
    # return a copy
    return \%dimensions;
}

has total_pages => (is => 'lazy',
                    isa => Int);

sub _build_total_pages {
    my $self = shift;
    my $count = $self->in_pdf_obj->pages;
    return $count;
}

sub orig_width {
    return shift->dimensions->{w};
}

sub orig_height {
    return shift->dimensions->{h};
}



=head3 in_pdf_obj

Internal usage. It's the PDF::API2 object used as source.

=head3 out_pdf_obj

Internal usage. The PDF::API2 object used as output.

=cut

has in_pdf_obj => (is => 'lazy',
                   isa => Maybe[Object]);

has _in_pdf_object_is_open => (is => 'rw', isa => Bool);

sub _build_in_pdf_obj {
    my $self = shift;
    my $input;
    if ($self->file) {
        die "File " . $self->file . " doesn't exists" unless -f $self->file;
        print $self->file . ": building in_pdf_obj\n" if DEBUG;
        my ($basename, $path, $suff) = fileparse($self->file, qr{\.pdf}i);
        my $tmpfile = File::Spec->catfile($self->_tmp_dir,
                                          $basename . $suff);
        copy($self->file, $tmpfile) or die "copy to $tmpfile failed $!";

        eval {
            $input = PDF::API2->open($tmpfile);
        };
        if ($@) {
            die "Couldn't open $tmpfile $@";
        }
        else {
            print "$tmpfile built\n" if DEBUG;
        }
        $self->_in_pdf_object_is_open(1);
    }
    return $input;
}

has out_pdf_obj => (is => 'lazy',
                    isa => Maybe[Object]);

has _out_pdf_object_is_open => (is => 'rw', isa => Bool);

has title => (is => 'ro',
              isa => Maybe[Str]);

sub _build_out_pdf_obj {
    my $self = shift;
    my $pdf;
    if ($self->file) {
        die "File " . $self->file . " is not a file" unless -f $self->file;
        print $self->file . ": building out_pdf_object\n" if DEBUG;
        $pdf = PDF::API2->new();
        my %info = (
                    $self->in_pdf_obj->info,
                    Creator => $self->_version,
                    CreationDate => $self->_orig_file_timestamp,
                    ModDate => $self->_now_timestamp,
                   );
        $pdf->info(%info);
        $self->_out_pdf_object_is_open(1);
    }
    return $pdf;
}

=head3 get_imported_page($pagenumber)

Retrieve the page form object from the input pdf to the output pdf,
and return it. The method return undef if the page is out of range.

=cut


sub get_imported_page {
    my ($self, $page) = @_;
    if ((!defined $page) || ($page <= 0) || ($page > $self->total_pages)) {
        return undef;
    }
    return  $self->out_pdf_obj->importPageIntoForm($self->in_pdf_obj, $page)
}

=head3 impose

Do the job and leave the output in C<< $self->outfile >>, cleaning up
the internal objects.

=cut

sub impose {
    my $self = shift;
    my $out = $self->output_filename;
    $self->_do_impose;
    $self->out_pdf_obj->saveas($out);
    $self->out_pdf_obj->end;
    $self->_out_pdf_object_is_open(0);
    $self->in_pdf_obj->end;
    $self->_in_pdf_object_is_open(0);
    $self->outfile($out);
    return $out;
}

=head3 output_filename

If outfile is not provided, use the suffix provided and return the
filename.

=cut

sub output_filename {
    my $self = shift;
    my $out = $self->outfile;
    unless ($out) {
        my ($name, $path, $suffix) = fileparse($self->file, qr{\.pdf}i);
        die $self->file . " has a suffix not recognized" unless $suffix;
        $out = File::Spec->catfile($path, $name . $self->suffix . $suffix);
    }
    return $out;
}


sub _orig_file_timestamp {
    my $self = shift;
    my $mtime = (stat($self->file))[9];
    return $self->_format_timestamp($mtime);
}

sub _now_timestamp {
    return shift->_format_timestamp(time());
}

sub _format_timestamp {
    my ($self, $epoc) = @_;
    return POSIX::strftime(q{%Y%m%d%H%M%S+00'00'}, localtime($epoc));
}

=head3 computed_signature

Return the actual number of signature, resolving 0 to the nearer
signature.

=head3 total_output_pages

Return the computed number of pages of the output, taking in account
the signature handling.

=head3 DEMOLISH

Object cleanup.

=cut

sub computed_signature {
    my $self = shift;
    my $signature = $self->signature || 0;
    if ($signature) {
        return $self->_optimize_signature($self->signature) + 0;
    }
    else {
        my $pages = $self->total_pages;
        my $ppsheet = $self->pages_per_sheet;
        return $pages + (($ppsheet - ($pages % $ppsheet)) % $ppsheet);
    }
}

sub total_output_pages {
    my $self = shift;
    my $pages = $self->total_pages;
    my $signature = $self->computed_signature;
    return $pages + (($signature - ($pages % $signature)) % $signature);
}

=head3 cropmarks_options

By default, cropmarks are centered and twoside is true.

=cut


sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 1,
                   outer => 1,
                   twoside => 1,
                  );
    return %options;
}

sub DEMOLISH {
    my $self = shift;
    if ($self->_out_pdf_object_is_open) {
        print $self->file . ": closing outpdf object\n" if DEBUG;
        $self->out_pdf_obj->end;
    }
    if ($self->_in_pdf_object_is_open) {
        print $self->file . ": closing inpdf object\n" if DEBUG;
        $self->in_pdf_obj->end;
    }
}

1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut


