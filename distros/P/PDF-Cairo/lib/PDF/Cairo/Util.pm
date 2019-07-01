package PDF::Cairo::Util;

use 5.016;
use strict;
use warnings;
use Carp;
use Module::Path 'module_path';

our $VERSION = "1.05";
$VERSION = eval $VERSION;

=head1 NAME

PDF::Cairo::Util - utility functions

=head1 SYNOPSIS

    use PDF::Cairo::Util;

    $points = cm(5);
    $points = in(8.5);
    $points = mm(300);
    ($width, $height) = paper_size('usletter');
    $hex = regular_polygon(6);

=head1 DESCRIPTION

=cut

our %paper;


BEGIN {
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw();
	our @EXPORT_OK = qw(cm in mm paper_size regular_polygon);
	our %EXPORT_TAGS = (all => \@EXPORT_OK);
	%paper = ();
	my $file = module_path('PDF::Cairo') || "PDF/Cairo/papers.txt";
	$file =~ s/\.pm$/\/papers.txt/;
	open(my $In, "<", $file) or
		die "$0: PDF::Cairo::papers.txt ($file): $!\n";
	while (<$In>) {
		next if /^\s*$|^\s*#/;
		chomp;
		my ($name,$w,$h,$notes);
		tr/A-Z/a-z/;
		if (/^([^ =]+)\s*=\s*(.*)$/) {
			$paper{$1} = $2;
		}else{
			($name,$w,$h,$notes) = split(' ');
			$paper{$name} = { w=>$w, h=>$h, notes=>$notes};
		}
	}
	CORE::close($In);
}

=head2 FUNCTIONS

=over 4

=item B<cm> $centimeters

Converts the arguments from centimeters to points. Importable.

=cut

sub cm {
	return $_[0] / 2.54 * 72;
}

=item B<in> $inches

Converts the arguments from inches to points. Importable.

=cut

sub in {
	return $_[0] * 72;
}

=item B<mm> $millimeters

Converts the arguments from millimeters to points. Importable.

=cut

sub mm {
	return $_[0] / 25.4 * 72;
}

=item B<paper_size> %options

=over 4

=item paper => $paper_size

=item wide|landscape => 1

=item tall|portrait => 1

=back

Return size in points of a paper type. The default is "US Letter"
(8.5x11 inches). The wide/tall options can be used to ensure that the
orientation of the page is as expected. Importable.

The supported paper sizes are listed in L<PDF::Cairo::Papers>.

=cut

# can either be called as a method or a function;
# returns ($width, $height) in points
#
sub paper_size {
	my $self = ref($_[0]) ? shift : {};
	my %options = @_;
	if (defined $options{width} and defined $options{height}) {
		$self->{w} = $options{width};
		$self->{h} = $options{height};
		$self->{paper} = undef;
		return ($self->{w}, $self->{h});
	}
	my $size = $options{paper};
	$size =~ tr/A-Z/a-z/;
	if (!defined $paper{$size}) {
		croak "PDF::Cairo::paper_size: unknown size '$size'.\n";
	}
	# process aliases
	my $rotated = 0;
	if (!ref $paper{$size}) {
		my $tmp;
		($size, $tmp) = split(/,/,$paper{$size});
		$rotated = !$rotated if defined $tmp and $tmp eq 'rotated';
	}
	if ($rotated) {
		$self->{w} = $paper{$size}->{h};
		$self->{h} = $paper{$size}->{w};
	}else{
		$self->{w} = $paper{$size}->{w};
		$self->{h} = $paper{$size}->{h};
	}
	if ($options{wide} or $options{landscape}) {
		my $tmp = $self->{w};
		if ($tmp < $self->{h}) {
			$self->{w} = $self->{h};
			$self->{h} = $tmp;
		}
	}elsif ($options{tall} or $options{portrait}) {
		my $tmp = $self->{w};
		if ($tmp > $self->{h}) {
			$self->{w} = $self->{h};
			$self->{h} = $tmp;
		}
	}
	return ($self->{w}, $self->{h});
}

=item B<regular_polygon> $sides

Calculate the vertices of a regular polygon with $sides sides with
radius 1, along with the relative lengths of the inradius and edge.

Returns a hashref:

    {
      points => [ [$x0, $y0], ... ],
      edge => $edge_length,
      inradius => $inradius_length,
      radius => 1,
    }

Calling the polygon($cx, $cy, $radius, $sides) method is equivalent to:

    $poly = regular_polygon($sides);
    @points = map(@$_, @{$poly->{points}});
    $pdf->save;
    $pdf->translate($cx, $cy);
    $pdf->scale($radius);
    $pdf->poly(@points);
    $pdf->close;
    $pdf->restore;

=cut

sub regular_polygon {
	use constant PI => 4 * atan2(1, 1);
	my $sides = shift;
	my $polygon = {};
	my @points;
	my $da = 2 * PI / $sides;
	my $a = ($da - PI) / 2;
	for my $side (1..$sides) {
		push(@points, [cos($a), sin($a)]);
		$a += $da;
	}
	$polygon->{points} = \@points;
	$polygon->{radius} = 1;
	$polygon->{edge} = 2 * sin(PI / $sides);
	$polygon->{inradius} = cos(PI / $sides);
	return $polygon;
}

=back

=head1 BUGS

Gosh, none I hope.

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=cut

1;
