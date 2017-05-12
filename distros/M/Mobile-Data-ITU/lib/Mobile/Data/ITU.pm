package Mobile::Data::ITU;

use warnings;
use strict;
use Carp;

use vars qw(@ISA @EXPORT);
use CDB_File;
use File::ShareDir 'dist_file';
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(itu2country);

use version; 
our $VERSION = qv('0.0.1');

sub itu2country {
    my $itu = shift;
    croak "Set proper ITU code" unless ( defined( $itu ) && $itu =~ /^\d{3}(?:\s?\d{2})?$/ );

    $itu =~ s/\s//g;

    my $cdbfile;
    {
        local $^W; # To avoid File::Spec::Unix error
        $cdbfile = dist_file('Mobile-Data-ITU', 'itu.cdb');
    }
    my %cdb;
    my $ref = tie %cdb, 'CDB_File', $cdbfile or die 'Cannot tie CDB file';

    my $name;

    if ( $cdb{$itu} ) {
        $name = $cdb{$itu};
    } else {
        foreach my $xid ( 0 .. 2 ) {
            my $key = substr( $itu, 0, 1 + $xid ) . ('X' x ( 2 - $xid));

            if ( $cdb{$key} ) {
                $name = $cdb{$key};
                last;
            }
        }
    }
    return $name;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Mobile::Data::ITU - Convert ITU area code into country name


=head1 SYNOPSIS

    use Mobile::Data::ITU;

    # Convert ITU code to country name
    my $country = itu2country($itu);
  
  
=head1 DESCRIPTION

    This module provide function for converting ITU (INTERNATIONAL TELECOMMUNICATION UNION) 
    COUNTRY OR GEOGRAPHICAL AREA CODES to country or area name.
    To know about ITU code, please see the web site L<http://www.itu.int/itudoc/itu-t/ob-lists/icc/e212_685.pdf>.


=head1 EXPORT 

=over

=item C<< itu2country >>

=back


=head1 DEPENDENCIES

CDB_File
File::ShareDir
Exporter


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
