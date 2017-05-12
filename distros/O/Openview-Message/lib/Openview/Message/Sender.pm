package Openview::Message::Sender;

#use 5.6.0;
use strict;
use warnings;
require Exporter;

our @ISA = ( 'Exporter' );
our @EXPORT_OK = qw(
   OPC_SEV_NORMAL
   OPC_SEV_WARNING
   OPC_SEV_MINOR
   OPC_SEV_MAJOR
   OPC_SEV_CRITICAL
); 
our @EXPORT = ();
our $VERSION = '0.02';

use Openview::Message::opcmsg;

sub new
{
   die "Usage: expected at least one argument" if @_ < 1;
   my ( $class ,$ah ) = @_;
   my $self =  { application=>undef
                ,object=>undef
                ,text=>undef
                ,group=>undef
                ,host=>$ENV{'HOSTNAME'} 
                ,severity=>'unknown'
               };
   if ( ref $ah eq 'HASH' )
   {
      foreach my $key ( keys %$ah )
      {
         if ( not exists( $self->{$key} ) )
         {
            warn "Undefined attribute=$key in Openview::Message::new()" ;
            next;
         }
         else
         {
            $self->{$key} = $ah->{$key};
         }
      }
   }
   return bless $self ,$class;
}
sub send($;@)
{
   my $self = shift @_;
   #print "\@_=". join( "|" ,@_ )."\n" ; 
   my $h = {};
   if ( ! @_ )
   {
      $h->{'text'} = undef;
   }
   elsif ( @_ == 1 )
   {
      ( $h->{'text'} ) = @_;
   }
   else
   {
      %$h = @_;
   }
   opcmsg( $self->_severity( $h->{'severity'} )
          ,$self->_application( $h->{'application'} )
          ,$self->_object( $h->{'object'} )
          ,$self->_text( $h->{'text'} )
          ,$self->_group( $h->{'group'} )
          ,$self->_host( $h->{'host'} )
         ); 
}


sub _severity 
{ 
   my ($self,$sev ) = @_; 
   $sev = $self->{'severity'} if not defined $sev;
   return $sev if $sev =~ m/^\d+$/;
   return _str_to_severity($sev);
}
sub _value
{
   my ( $self ,$key ,$value ) = @_;
   return $value if defined $value;
   return defined $self->{$key} ? $self->{$key} : "$key not provided" ;
}
sub _application { my $s = shift @_; $s->_value( 'application' ,@_ ); }
sub _object      { my $s = shift @_; $s->_value( 'object'      ,@_ ); }
sub _text        { my $s = shift @_; $s->_value( 'text'        ,@_ ); }
sub _group       { my $s = shift @_; $s->_value( 'group'       ,@_ ); }
sub _host        { my $s = shift @_; $s->_value( 'host'        ,@_ ); }

#my $_sevmap = {
#       'normal'    => OPC_SEV_NORMAL()
#      ,'warning'   => OPC_SEV_WARNING()
#      ,'minor'     => OPC_SEV_MINOR()
#      ,'major'     => OPC_SEV_MAJOR()
#      ,'critical'  => OPC_SEV_CRITICAL()
#      #,'unknown'   => OPC_SEV_UNKNOWN()
#      #,'unchanged' => OPC_SEV_UNCHANGED()
#      #,'none'      => OPC_SEV_NONE()
#   };

sub _str_to_severity
{
   my $str = shift @_;
   return OPC_SEV_NORMAL() if ( $str eq 'normal' );
   return OPC_SEV_WARNING() if ( $str eq 'warning' );
   return OPC_SEV_MINOR() if ( $str eq 'minor' );
   return OPC_SEV_MAJOR() if ( $str eq 'major' );
   return OPC_SEV_CRITICAL() if ( $str eq 'critical' );
   die( "Undefined severity=$str" );
}

1;
__END__

=head1 NAME

Openview::Message::Sender - OO interface to sending HP OpenView messages.

=head1 SYNOPSIS

   use Openview::Message::Sender; 
   my $ovs = new Openview::Message::Sender { application=>'name'
                             ,object=>'name'
                             ,text=>'msg_text"
                             ,group=>'msg_group'
                             ,host=>$ENV{'HOSTNAME'} 
                            };
   #take defaults from attributes of $ovs :
   $ovs->send( "your message text" ); 
   #or
   $ovs->send( text=>"your message text" ); 
 
   #providing call specific argments overriding the 
   #some of the defaults provided by the attributes of $ovs :
   $ovs->send( text=>"your message text" 
                   ,severity=>'minor' 
                   ,group=>'MsgGroup' [... etc]  );


=head1 DESCRIPTION

Openview::Message::Sender also provides an OO interface which maintains
default values for most of the the arguments to the Openview opcmsg()
API.  The defaults are provided at the time the object is constructed.  
This provides for considerably for less code clutter, and no pollution
of your namespace.


=head2 EXPORTS

Nothing is exported by default.

=head2 METHODS 

The OO interface provides the following methods:

=head2 new()

Called off the Package.  The constructor returns a blessed instance of an
Openview::Message::Sender object.  This method takes a objection argument
which is a hash reference of default values which will be used to call
opcmsg().

See L<ATTRIBUTES> for a definition of the attributes recognized.

=head2 send()

Sends an Openview opcmsg() using arguments either taken from the hash provided
to the call to send(), or from the attributes of the Openview object.

See L<ATTRIBUTES> for a definition of the attributes recognized.

=head2 ATTRIBUTES

=over

=item application

This attribute is used for the opcmsg 'application' argument.
This attribute defaults to the string 'application not provided'.

=item object

This attribute is used for the opcmsg 'object' argument.

This attribute defaults to string 'object not provided'.

=item severity

This attribute is used for the opcmsg 'severity' argument.
The values this takes are lowercase strings which are internally mapped
to the Openview severity constants prefixed with 'OVC_SEV_'.  As in:

   unknown
   unchanged
   none
   normal
   warning
   minor
   major
   critical

This attribute defaults to 'unknown' (OPC_SEV_UNKNOWN).

If one wants to use the OPC_SEV_* constants they can be imported into your
name space if desired, and may be slightly more efficient, then the strings.

=item text

This attribute is used for the opcmsg 'msg_text' argument.
This attribute defaults to the string 'text not provided'.

=item group

This attribute is used for the opcmsg 'msg_group' argument.
This attribute defaults to the string 'undefined'.

=item host

This attribute is used for the opcmsg hostname argument.
It defaults to the value of the HOSTNAME environment variable
or "host not provided".

=back

=head1 AUTHOR

Lincoln A. Baxter E<lt>lab@lincolnbaxter.comE<gt>

=cut
