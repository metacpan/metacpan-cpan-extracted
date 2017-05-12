package Openview::Message::cliopcmsg;  #fake it with cli interface
use strict;
use warnings;
require Exporter;
our ( @ISA , @EXPORT_OK ,@EXPORT );
our $VERSION = '0.02';

@ISA = qw( Exporter );
@EXPORT_OK = qw( OPC_SEV_NORMAL 
                 OPC_SEV_WARNING 
                 OPC_SEV_MINOR 
                 OPC_SEV_MAJOR 
                 OPC_SEV_CRITICAL 
                 opcmsg
                 );
@EXPORT = @EXPORT_OK;

print "Using CLI opcmsg\n" if $ENV{CLI_OPENVIEW_MESSAGE_DEBUG} ;

use constant OPC_SEV_NORMAL   => 'normal'  ;
use constant OPC_SEV_WARNING  => 'warning' ; 
use constant OPC_SEV_MINOR    => 'minor'   ; 
use constant OPC_SEV_MAJOR    => 'major'   ; 
use constant OPC_SEV_CRITICAL => 'critical'; 
sub opcmsg { return system( "opcmsg" ,@_ ); }

1;
__END__

=head1 NAME

Openview::Message::cliopcmsg - Command Line Wrapper sending OpenView messages.

=head1 SYNOPSIS

   #low level access to the opcmsg API:
   use Openview::Message::opcmsg ;
   #if the real opcmsg code can not be loading this will load instead
   opcmsg( OPC_SEV_MINOR 
          ,'application' 
          ,'object' 
          ,'msg_text' 
          ,'msg_group' 
          ,hostname 
         );

=head1 DESCRIPTION

Openview::Message::cliopcmsg provides low level access to the HP Openview
operations opcmsg command line command.  This modules exists because
HP would not help my employer with a problem we have linking the 
the opcmsg() library API on HP.  This module is loaded when the 
perl XS module can not be.  It implements the api using a wrapper
around the opcmsg command which is expeøted to be on path.

=head1 SEE ALSP

See L<Openview::Message::opcmsg> for more information on the exposed
API, and L<Openview::Message::Sender> for an OO interface.

=head1 AUTHOR

Lincoln A. Baxter E<lt>lbaxter@netreach.netE<gt>

=cut
