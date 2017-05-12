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
# $Id: Syncupdates.pm,v 1.16 2003/08/01 14:50:35 peter Exp $
#

=head1 NAME

Net::Whois::RIPE::Syncupdates - Perl Syncupdates client interface

=head1 SYNOPSIS

  use Net::Whois::RIPE::Syncupdates;

  Net::Whois::RIPE::Syncupdates::Message::Auth
    ->defaultPassword('myPassword');

  my $sup = Net::Whois::Syncupdates->new(
      url => 'http://backend.server.com/syncupdates',
  );

  my $message = $sup->message;

  $message->setOption(ORIGIN, 'client_ID');
  $message->setOption(NEW, 1);

  $message->setDBObject(<<END_OBJ);

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

  $sup->execute($message);

=cut

=head1 DESCRIPTION

B<Net::Whois::RIPE::Syncupdates> is a Perl interface to the RIPE NCC 
synchronous updates service.

=head1 METHODS

=over 4

=cut

package Net::Whois::RIPE::Syncupdates;

use strict;
use warnings;

use vars qw($AUTOLOAD);

use Net::Whois::RIPE::Syncupdates::Message;
use Net::Whois::RIPE::Syncupdates::Response;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Params::Validate qw(:all);

use Data::Dumper;

our $VERSION = '1.1';

Params::Validate::validation_options(
    on_fail => sub{die"@_\n"},
    stack_skip=>2
);

=item new ( [ url =E<gt> BACKEND_URL ] )

Connects to the RIPE TEST database syncupdates server by default.  
DB people, please let me know if this is a bad idea.

=cut

sub new {
    my $class = shift;
    my %arg = validate(@_, {
        url => 0
    });

    # The following default URL comes from Makefile.PL, if you want to
    # change (disable) it, reinstall the package.
    my $url = $arg{url} || '__DEFAULT_URL__';

    die "$class: There was no backend URL specified to new()\n" unless $url;

    my $self = {
        _url => $url,
        _useragent => '',
        message => '',
        response => '',
    };
    bless $self, $class;

    $self->_useragent( LWP::UserAgent->new );

    my $class_id = sprintf('%s/%s', $class, $self->_version);
    $class_id =~ s/::/_/g;
    $self->_default_origin($class_id);

    return $self;
}

=item execute ( [ MESSAGE ] )

Send update to backend.  If no argument specified,
sends $self-E<gt>message by default.  This internal C<Message>
object can be directly populated with data by using the 
message() accessor.
        
execute() returns the server's response as a
C<Net::Whois::RIPE::Syncupdates::Response> object.  See the 
manpage of that class for details.

=cut

sub execute {
    my $self = shift;
    my $msg = shift || $self->message;

    die "Net::Whois::RIPE::Syncupdates::execute() got wrong input type" 
        unless ref($msg) eq 'Net::Whois::RIPE::Syncupdates::Message';

    $self->message($msg);

    my $req = POST($self->_url, $msg->getMessage);
    my $sup_response = $self->_useragent->request($req);

    die "Cannot connect to the syncupdates server: ".$sup_response->status_line()."\n" if $sup_response->is_error;

    my $r = Net::Whois::RIPE::Syncupdates::Response->new($sup_response->as_string);
    $self->response($r);
    
    return $self->response;
}

=item ping ( )

Sends a HELP query to the backend.  The primary use of this is to check
if the backend is alive and well.  Returns the help text from the server 
in case of success.

=cut

sub ping {
    my $self = shift;

    my $msg = Net::Whois::RIPE::Syncupdates::Message->new;
    
    $msg->setDBObject('PLACEHOLDER');
   
    $msg->setOption(ORIGIN, $self->_default_origin);
    $msg->setOption(HELP, 'yes');
    
    $self->execute($msg);
    return $self->response->asString;
}


=item message ( )

Accessor method for the internal C<Net::Whois::RIPE::Syncupdates::Message>
object.  This object gets created "lazily", ie it's instantiated upon the
first call to message() .

=cut

sub message {
    my $self = shift;
    
    if(@_){
        
        $self->_set('message', shift);
        
    } elsif( ! $self->_get('message') ){
        
        $self->_set('message', Net::Whois::RIPE::Syncupdates::Message->new);
        
    }
    $self->_get('message');
}

=item response ( )

Accessor method to a C<Net::Whois::RIPE::Syncupdates::Response> object,
which represents the result of the last execute()'d syncupdates query.

For more information on the Response class, see the 
C<Net::Whois::RIPE::Syncupdates::Response> manpage.

=cut

sub response {
    my $self = shift;
    my $r = shift;
    
    if($r){
        $self->_set('response', $r);
    }
    $self->_get('response');
}


# Private methods

sub _version {
    $VERSION;
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

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;

    $attr =~ s/.*:://;

    if(@_){
        $self->_set($attr, shift);
    }
    return $self->_get($attr);
}

sub DESTROY {

}



1;


__END__

=back 4

=head1 PREREQUISITES

C<HTTP::Request::Common>

C<LWP::UserAgent>

=head1 AUTHOR

Peter Banik E<lt>peter@ripe.netE<gt>, Ziya Suzen E<lt>peter@ripe.netE<gt>

=head1 SEE ALSO

C<Net::Whois::RIPE::Syncupdates::Message>

C<Net::Whois::RIPE::Syncupdates::Response>

=head1 VERSION

$Id: Syncupdates.pm,v 1.16 2003/08/01 14:50:35 peter Exp $

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

