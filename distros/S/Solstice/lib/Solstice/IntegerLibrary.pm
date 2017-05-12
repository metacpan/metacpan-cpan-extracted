package Solstice::IntegerLibrary;

# $Id: IntegerLibrary.pm 2425 2005-08-01 21:51:02Z mcrawfor $

=head1 NAME

IntegerLibrary - A library of generic integer manipulation functions.

=head1 SYNOPSIS

  use IntegerLibrary qw(inttoroman);

  my $str = inttoroman(49); 

=head1 DESCRIPTION

Functions in this library make no assumptions about the integer 
being modified.

=cut

use 5.006_000;
use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our ($VERSION) = ('$Revision: 2425 $' =~ /^\$Revision:\s*([\d.]*)/);

our @EXPORT = qw|inttobytes inttotime inttoword inttoroman inttolatin|;
our %EXPORT_TAGS = ( all => [ qw|
    inttobytes
    inttotime
    inttoword
    inttoroman
    inttolatin
| ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

my @alpha = ('a' .. 'z');

=head2 Superclass

L<Exporter|Exporter>

=head2 Export

No symbols exported.

=head2 Functions

=over 4

=cut


=item inttobytes($int, $compact)

Returns $int transformed into a string displaying a byte size;
$compact specifies an abbreviated units label.

=cut

sub inttobytes {
    my ($int, $compact) = @_;
    return undef unless defined $int;
    $int = abs int $int;

    my $string = '';
    if ($int < 1000) {
        $string  = $int;
        $string .= $compact ? ' B' : ' bytes';
    } elsif ($int > 999 and $int < 1000000) {
        $string  = sprintf("%.1f", $int/1000);
        $string .= $compact ? ' KB' : ' Kbytes';
    } elsif ($int > 999999  and $int < 1000000000) {
        $string  = sprintf("%.2f", $int/1000000);
        $string .= $compact ? ' MB' : ' Mbytes';
    } elsif ($int > 999999999 and $int < 1_000_000_000_000  ) {
        $string  = sprintf("%.2f", $int/1000000000);
        $string .= $compact ? ' GB' : ' Gbytes';
    } elsif ($int > 999_999_999_999 ){
        $string  = sprintf("%.2f", $int/1_000_000_000_000);
        $string .= $compact ? ' TB' : ' Tbytes';
    }
    return $string; 
}

=item inttotime($int, $compact)

Returns $int transformed into a string displaying
hours, minutes, seconds; $compact specifies a HH:MM:SS format.

=cut

sub inttotime {
    my ($int, $compact) = @_;
    return undef unless defined $int;
    $int = abs int $int;

    my $hour = int ($int / 3600);
    $int = $int - $hour * 3600;
    
    my $min = int ($int / 60);
    $int = int ($int - $min  * 60);

    return sprintf("%02d", $hour).':'.sprintf("%02d", $min).':'.sprintf("%02d", $int) if ($compact);
    
    my $string = "";
    $string  = "$hour hr " if $hour;
    $string .= "$min min " if $min;
    $string .= "$int sec "  if $int;
    chop $string;
    return $string ? $string : '<1 sec';
}

=item inttoword($int)

Returns $int transformed into a string containing its equivalent word form.
Currently, 1-9 are implemented. If greater number conversions are required,
consider reimplementing this function as a wrapper around Lingua::EN::Nums2Words.

=cut

sub inttoword {
    my ($int) = @_;
    return $int unless (defined $int and $int > 0 and $int < 10);
    
    my %values = ( 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five', 6 => 'six', 7 => 'seven', 8 => 'eight', 9 => 'nine');
    
    return $values{$int};
}

=item inttoroman($int, $upper)

Returns $int transformed into a roman numeral string; $int
must be a non-zero integer between -4000 and 4000.
$upper specifies upper-case.

=cut

sub inttoroman {
    my ($int, $upper) = @_;
    return undef unless (defined $int and $int != 0 and -4000 < $int and $int < 4000);

    my $string = '';
    if ($int < 0) {
        $string = '-' . _inttoroman( abs int $int );
    } else {
        $string = _inttoroman( int $int );
    }
    return ($upper) ? $string : lc $string;
}

=item inttolatin($int, $upper)

Returns $int transformed into a latin alphabet string,
where $int is a non-zero integer. $upper specifies upper-case.

=cut

sub inttolatin {
    my ($int, $upper) = @_;
    return undef unless (defined $int and $int != 0);
    
    my $string = '';
    if ($int < 0) {
        $string = '-' . _inttolatin( abs int $int );
    } else {
        $string = _inttolatin( int $int );
    }
    return ($upper) ? uc $string : $string;
}

=back

=head2 Private Functions

=over 4

=item _inttoroman($int)

Internal function for converting $int to a roman numeral string

=cut

sub _inttoroman {
    my $int = shift;    

    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my @figure = reverse sort keys %roman_digit;
    grep($roman_digit{$_} = [split(//, $roman_digit{$_}, 2)], @figure);

    my ($x, $roman);
    foreach (@figure) {
        my ($digit, $i, $v) = (int($int / $_), @{$roman_digit{$_}});
        if (1 <= $digit and $digit <= 3) {
            $roman .= $i x $digit;
        } elsif ($digit == 4) {
            $roman .= "$i$v";
        } elsif ($digit == 5) {
            $roman .= $v;
        } elsif (6 <= $digit and $digit <= 8) {
            $roman .= $v . $i x ($digit - 5);
        } elsif ($digit == 9) {
            $roman .= "$i$x";
        }
        $int -= $digit * $_;
        $x = $i;
    }    
    return $roman;
}

=item _inttolatin($int)

Recursive function for converting $int to a latin alphabet string

=cut

sub _inttolatin {
    my $int = shift || return '';
    return _inttolatin(int (($int - 1) / 26)) . $alpha[$int % 26 - 1];
}


1;
__END__

=back

=head2 Modules Used

L<Exporter|Exporter>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2425 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
