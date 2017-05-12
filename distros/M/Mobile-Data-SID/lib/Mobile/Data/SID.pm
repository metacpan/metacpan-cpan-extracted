package Mobile::Data::SID;

use warnings;
use strict;
use Carp;

use vars qw(@ISA @EXPORT);
use CDB_File;
use File::ShareDir 'dist_file';
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(sid2country);

use version; 
our $VERSION = qv('0.0.1');

sub sid2country {
    my $sid = shift;
    croak "Set proper SID code" unless ( defined( $sid ) && $sid =~ /^\d+$/ );

    $sid = sprintf("%05d",$sid);

    my $cdbfile;
    {
        local $^W; # To avoid File::Spec::Unix error
        $cdbfile = dist_file('Mobile-Data-SID', 'sid.cdb');
    }
    my %cdb;
    my $ref = tie %cdb, 'CDB_File', $cdbfile or die 'Cannot tie CDB file';

    my $name;
    foreach my $xid ( 0 .. 3 ) {
        my $key = substr( $sid, 0, 2 + $xid ) . ('X' x ( 3 - $xid));

        if ( $cdb{$key} ) {
            $name = $cdb{$key};
            last;
        }
    }
    return $name;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Mobile::Data::SID - Convert IFAST SID into country name


=head1 SYNOPSIS

    use Mobile::Data::SID;

    # Convert SID code to country name
    my $country = sid2country($sid);
  
  
=head1 DESCRIPTION

    This module provide function for converting IFAST SID (SYSTEM IDENTIFICATION NUMBER) to country name.
    To know about IFAST SID, please see the web site L<http://www.ifast.org/files/GuidelinesMay2007/IFAST%20SID%20Guidelines%20r2.2.pdf>.
    This module is based on conversion table shown on L<http://www.ifast.org/files/SIDNumeric.htm>.


=head1 EXPORT 

=over

=item C<< sid2country >>

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
