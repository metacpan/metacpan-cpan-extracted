package Openview::Message::opcmsg;

#use 5.6.0;
use strict;
use warnings;

require Exporter;
require DynaLoader;
#require AutoLoader;
use Carp;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

   #OPC_SEV_UNKNOWN
   #OPC_SEV_UNCHANGED
   #OPC_SEV_NONE
our @EXPORT_OK = qw(
   opcmsg   
   OPC_SEV_NORMAL
   OPC_SEV_WARNING
   OPC_SEV_MINOR
   OPC_SEV_MAJOR
   OPC_SEV_CRITICAL
);
our @EXPORT = grep( !/_UN|_NONE/ ,@EXPORT_OK );
our $VERSION = '0.03';

if ( $ENV{CLI_OPENVIEW_SENDER} )
{
   require Openview::Message::cliopcmsg;
   import Openview::Message::cliopcmsg;
}
else
{
   eval { bootstrap Openview::Message::opcmsg $VERSION; };
   if ( $@ )
   {
      #HP will not tell us how to link with opcmsg() API
      #on HP so...  we fake it with the opcmsg command
      #print "\n\nFaking it\n\n" ;
      require Openview::Message::cliopcmsg;
      import Openview::Message::cliopcmsg;
   }
}

1;

__END__

=head1 NAME

Openview::Message::opcmsg - Perl extension for sending OpenView messages.

=head1 SYNOPSIS

   #low level access to the opcmsg API:
   use Openview::Message::opcmsg ;
   opcmsg( OPC_SEV_MINOR 
          ,'application' 
          ,'object' 
          ,'msg_text' 
          ,'msg_group' 
          ,hostname 
         );

=head1 DESCRIPTION

Openview::Message::opcmsg provides low level access to the HP OpenView
Operations opcmsg() library API.  This enables perl scripts to send
Openview messages without having to use system() calls or fork sub-
processes which is much more efficient than using the opcmsg command.

=head2 EXPORTS

The following symbols are exported by default:

   opcmsg
   OPC_SEV_NORMAL
   OPC_SEV_WARNING
   OPC_SEV_MINOR
   OPC_SEV_MAJOR
   OPC_SEV_CRITICAL


The following symbols may attitionally be imported, but are probably
not very useful:

   OPC_SEV_UNKNOWN
   OPC_SEV_UNCHANGED
   OPC_SEV_NONE

=head1 SEE ALSO

Openview::Message::Sender for an OO interface to this function,
which does not export symbols into the user's namespace.

=head1 BUGS

Apparently, the HP Openview library is "not fork-safe".  This creates
problems for forking servers.  A work-around for this is to 'pre-fork'
an opcmsg server that implements this function, and have your forking
servers send it messages. 

Alternatively, you can set CLI_MESSAGE_SENDER=1 in your environment,
we this module will use the CLI interface instead.

HP refused to offer support to the author's employer 
for linking with opcmsg() on their own platforms (HP), so
we fake it with L<Openview::Message::cliopcmsg>.

=head1 AUTHOR

Lincoln A. Baxter E<lt>lab@lincolnbaxter.comE<gt>

=cut
