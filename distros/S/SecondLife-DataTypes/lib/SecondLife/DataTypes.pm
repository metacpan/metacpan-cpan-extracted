package SecondLife::DataTypes;
{
  $SecondLife::DataTypes::VERSION = '0.900';
}
# ABSTRACT: Support for parsing, working with and printing Second Life's data types
use strict;
use warnings;
use SecondLife::Rotation;
use SecondLife::Vector;
use SecondLife::Region;
use Sub::Exporter -setup => { exports => [qw( slrot slvec slregion )] };

sub slrot($) { SecondLife::Rotation->new(@_); }

sub slvec($) { SecondLife::Vector->new(@_); }

sub slregion($) { SecondLife::Region->new(@_); }

1;


__END__
=pod

=head1 NAME

SecondLife::DataTypes - Support for parsing, working with and printing Second Life's data types

=head1 VERSION

version 0.900

=head1 SYNOPSIS

    use SecondLife::Rotation;
    my $null_rot = SecondLife::Rotation->new("<0,0,0,1.0>");

    # or

    use SecondLife::DataTypes qw( slrot );
    my $null_rot2 = slrot "<0,0,0,1.0>";

    print $null_rot2->s,"\n"; # 1.0
    
    use SecondLife::DataTypes qw( slvec );
    my $cyan = SecondLife::Vector->new("<0,1,1>");
    my $rec = slvec '<1,0,0>';
    
    use SecondLife::DataTypes qw( slregion );
    my $region = SecondLife::Region->new("Dew Drop (236544, 242944)");
    my $region2 = slregion 'Dew Drop (236544, 242944)'; # same

=head1 DESCRIPTION

This module loads the other SecondLife data type modules and optionally
provides sugar for creating new instances of them from strings.

=head1 FUNCTIONS

=head2 sub slrot(Str $rot_str) returns SecondLife::Rotation

Create a new L<SecondLife::Rotation> object from a string.

=head2 slvec(Str $vec_str) returns SecondLife::Vector

Create a new L<SecondLife::Vector> object from a string.

=head2 slregion(Str $region_str) returns SecondLife::Region

Create a new L<SecondLife::Region> object from a string

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<SecondLife::Rotation|SecondLife::Rotation>

=item *

L<SecondLife::Vector|SecondLife::Vector>

=item *

L<SecondLife::Region|SecondLife::Region>

=item *

L<Math::Quaternion|Math::Quaternion>

=back

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

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

