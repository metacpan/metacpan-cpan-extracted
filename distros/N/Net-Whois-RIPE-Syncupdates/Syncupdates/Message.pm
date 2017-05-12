# Copyright (c) 1993 - 2002 RIPE NCC
#
# All Rights Reserved
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation, and that the name of the author not be
# used in advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
#
# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
# AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# $Id: Message.pm,v 1.16 2003/08/01 13:46:16 peter Exp $
#


=head1 NAME

Net::Whois::RIPE::Syncupdates::Message - Subclass to encapsulate Syncupdates messages

=head1 SYNOPSIS

  use Net::Whois::RIPE::Syncupdates::Message;

  Net::Whois::RIPE::Syncupdates::Message::Auth ->defaultPassword('myPassword');

  my $msg = Net::Whois::Syncupdates::Message->new;

  $msg->setOption(ORIGIN, 'client_ID');
  
  $msg->setOption(NEW, 1);

  $msg->setDBObject(<<END_OBJ);
  inetnum:      192.168.0.0 - 192.168.255.255
  netname:      IANA-CBLK-RESERVED1
  descr:        Class C address space for private internets
  descr:        See http://www.ripe.net/db/rfc1918.html for details
  country:      NL
  admin-c:      RFC1918-RIPE
  tech-c:       RFC1918-RIPE
  status:       ALLOCATED UNSPECIFIED
  mnt-by:       RIPE-NCC-HM-MNT
  changed:      rfc1918@ripe.net 20020129
  source:       RIPE
  END_OBJ

  $msg->setDBObject( $msg->getDBObject . "\nchanged:  test@provider.com 20030324" );
  
=head1 DESCRIPTION

C<Net::Whois::RIPE::Syncupdates::Message> is a subclass, primarily being used by
C<Net::Whois::RIPE::Syncupdates>, the RIPE NCC Syncupdates Perl interface.

See the C<Net::Whois::RIPE::Syncupdates> manpage for more information.

=head1 CONSTANTS

Variable names accepted by the syncupdates server:

    ORIGIN
    NEW
    HELP
    DATA

=head1 METHODS

=over 4

=cut

package Net::Whois::RIPE::Syncupdates::Message;

=head1 Net::Whois::RIPE::Syncupdates::Message

=cut

use strict;
use warnings;

use Exporter;
use Data::Dumper;

our $VERSION = '$Revision: 1.16 $ ' =~ /\$Revision:\s+([^\s]+)/;

our @ISA = qw(Exporter);

our @EXPORT;

my @VALID_OPTIONS = qw(NEW ORIGIN DATA HELP);
my @MANDATORY_OPTIONS = qw(DATA ORIGIN);

=over 4

=item new ( )

Constructor.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = { auth=> Net::Whois::RIPE::Syncupdates::Message::Auth->new() };
    bless $self, $class;
}

=item auth ( )

Returns associated Authorization object of type Net::Whois::RIPE::Syncupdates::Message::Auth

=cut

sub auth {
  my $self = shift;

  return $self->{auth}
}

=item getMessage( )

Return the message as a hashref, ready to be passed over to the syncupdates backend.
Although this method is public, its primary use is to be called by
C<Net::Whois::RIPE::Syncupdates::execute()>.

=cut

sub getMessage {
    my $self = shift;
    
    # The following almost works, but not quite.  For some reason, the second parameter 
    # is not being treated as optional.  
    
    #    my ($attr, $value) = validate_pos(@_, {
    #        { type => SCALAR, callbacks => { 'invalid option to setOption()' => sub { grep shift, @VALID_OPTIONS } } },
    #        { type => SCALAR, optional => 1 }
    #    });

    for my $opt (@MANDATORY_OPTIONS){
        die "incomplete message: missing mandatory option $opt" unless $self->_get($opt);
    }

    my $msg = [];

    for my $key (@VALID_OPTIONS) {
      push @$msg, $key, $self->{$key} if exists $self->{$key};
    }

    return $msg;
}

=item getDBObject( )

Return the database object stored within this instance, previously set via
setDBObject().  Empty string if the DB object has not yet been set.

=cut

sub getDBObject {
    my $self = shift;
    return $self->_get('DATA');
}

=item setDBObject ( OBJECT | RPSL_OBJECT )

Set the database object to be sent within this message.  Objects are accepted either as
string or as a C<Net::Whois::RIPE::RPSL> object.

The C<Message> object simply acts as a container, the supplied database object is being 
stored internally as a string.  If passed a non-scalar value, setDBObject() will try to 
call an as_string() method upon that object, and store the returned string internally.

=cut

sub setDBObject {
    my $self = shift;
    my $object = shift;

    if(ref($object) eq 'ARRAY') {
      for my $obj (@$object) {
        $self->_appendDBObject($obj);
      }
    }

    elsif(ref($object) eq 'HASH') {
      for my $obj (keys %$object) {
        $self->_appendDBObject($object->{$obj});
      }
    }

    else {
      $self->_appendDBObject($object);
    }
}

=item getOption ( OPTION )

=cut

sub getOption {
    my $self = shift;
    my $attr = shift;

    return unless $attr and grep( $attr, @VALID_OPTIONS );
    $self->_get($attr);
}

=item setOption ( OPTION [, VALUE ] )

=cut

sub setOption {
    my $self = shift;
    my $attr = shift;
    my $value = shift;

    return unless $attr and grep( $attr, @VALID_OPTIONS );
    $self->_set($attr, $value);
}

=item changedBy ( Email )

=cut

sub changedBy {
    my $self = shift;
    my $attr = '_changedBy';

    return $self->_get($attr) unless @_;

    my $value = shift;
    $self->_set($attr, $value);
}

=item appendChangedBy ( OBJ )

It only works on text objects. No error conditions defined.

TODO: Use RPSL if you can

=cut

sub appendChangedBy {
    my $self = shift;
    my $obj = shift;
    my $user_email = shift;

    $obj =~ s/(.*\nchanged:[^\n]+)/$1\nchanged:      $user_email/s;

    return $obj;
}

# Private methods follow

sub import {
    my $class = shift;

    for my $opt (@VALID_OPTIONS){
        eval "use constant $opt => '$opt';";
        push @EXPORT, $opt;
    }
    Exporter::export_to_level($class, 1);
}

sub _autoSerialiseObject {
  my $self = shift;
  my $obj = shift;
  my $obj_ser = '';

  # RPSL Object
  if(ref($obj) and UNIVERSAL::can($obj, 'text')){
    $obj_ser = $obj->text;
  }
  else {
    $obj_ser = $obj;
  }

  # Add changed attrib
  $obj_ser = $self->appendChangedBy($obj_ser, $self->changedBy())
    if $self->changedBy();

  return $obj_ser;
}

sub _appendDBObject {
  my $self = shift;
  my $object = shift;
  my $obj_separator = "\n\n";
  my $object_ser = '';

  $object_ser = $self->_autoSerialiseObject($object);

  $object_ser = $self->auth()->sign($object_ser);

  my $current_obj = $self->_get('DATA') || '';

  $self->_set('DATA', $current_obj . $obj_separator . $object_ser);
}

sub _get {
    my $self = shift;
    my $attr = shift;

    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}

=back

=cut

package Net::Whois::RIPE::Syncupdates::Message::Auth;

=head1 Net::Whois::RIPE::Syncupdates::Message::Auth

=cut

=item new ( )

Constructor

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = bless {}, $class;

  $self->{auth_hook} = $self->defaultAuthHook();

  return $self;
}

{
  my $_default_password = '';

  sub defaultPassword {
    my $self = shift;

    $_default_password = shift if @_;

    return $_default_password;
  }
}

=item defaultAuthHook

Change default Authorization hook.
Default is 'simple_sign'.

=cut

{
  my $_default_auth_hook = \&simple_sign;
  
  sub defaultAuthHook {
    my $self = shift;

    $_default_auth_hook = shift if @_;

    return $_default_auth_hook;
  }
}

=item sign ( )

Calls the defined authorization hook, supplying the Whois object as parameter.

=cut

sub sign {
  my $self = shift;
  my $object = shift;

  return $self->authHook()->($object);
}

=item authHook ( [CODEREF] )

Returns or sets the authorization hook.  Expects and returns a CODE reference.

=cut

sub authHook {
  my $self = shift;
  $self->{auth_hook} = shift if @_;

  return $self->{auth_hook};
}

=item simple_sign ( OBJECT )

The default authorization hook, which adds a password: line to the object. 
Custom hooks should do same sort of operations on Whois object.

  sub simple_sign {
    my $object = shift;

    return $object unless defaultPassword();

    return $object . 'password: '. defaultPassword() ."\n";
  }

=cut

sub simple_sign {
  my $object = shift;

  return $object unless defaultPassword();

  return $object . 'password: '. defaultPassword() ."\n";
}

1;


__END__

=back 4

=head1 AUTHOR

Peter Banik E<lt>peter@ripe.netE<gt>, Ziya Suzen E<lt>peter@ripe.netE<gt>

=head1 SEE ALSO

C<Net::Whois::RIPE::Syncupdates>

=head1 VERSION

$Id: Message.pm,v 1.16 2003/08/01 13:46:16 peter Exp $

=head1 BUGS

Please report bugs to E<lt>swbugs@ripe.netE<gt>.

=head1 COPYRIGHT

Copyright (c) 1993 - 2003 RIPE NCC

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.

THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut



