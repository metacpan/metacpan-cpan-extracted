package Net::DHCP::Control;

use vars qw($VERSION @ISA @EXPORT);
use warnings;
use strict;
use Scalar::Util;

require DynaLoader;
require Exporter;

our $STATUS;

@ISA = qw(Exporter DynaLoader);
our $VERSION = '0.09';

our %EXPORT_TAGS = (
    'all' => [ qw(  ) ],
    'types' => [ qw(TP_STRING TP_INT TP_UINT TP_BOOL TP_UNSPECIFIED) ],
);

our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}}, 'DHCP_PORT', 'errtext',
		   @{$EXPORT_TAGS{'types'}}, '$STATUS',
		   );


sub DHCP_PORT () { 7911 } 


#=============================================================================
#
# No touchy!
#

sub AUTOLOAD {
    no strict;
    (my $constname = $AUTOLOAD) =~ s/.*:://;
    die "&Fcntl::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) {
        my (undef,$file,$line) = caller;
        die "Undefined subroutine $AUTOLOAD called";
    }
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}


bootstrap Net::DHCP::Control $VERSION;
1;

