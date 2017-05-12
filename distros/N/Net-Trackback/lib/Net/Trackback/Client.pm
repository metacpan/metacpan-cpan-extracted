# Copyright (c) 2003-2004 Timothy Appnel (cpan@timaoutloud.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
package Net::Trackback::Client;
use strict;
use base qw( Class::ErrorHandler );

use Net::Trackback;
use Net::Trackback::Data;
use Net::Trackback::Message;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{__timeout} = 15;
    $self->{__no_proxy} = [ qw(localhost, 127.0.0.1) ];
    $self->{__charset} = 'utf-8';
    $self;
}

sub init_agent {
    my $self = shift;
    require LWP::UserAgent;
    my $agent = LWP::UserAgent->new;
    $agent->agent("Net::Trackback/$Net::Trackback::VERSION");
    # $agent->parse_head(0);
    $agent->protocols_allowed( [ qw(http https) ] );
    $agent->proxy([qw(http https)], $self->{__proxy}) if $self->{__proxy};
    $agent->no_proxy(@{$self->{__no_proxy}}) if $self->{__no_proxy};
    $agent->timeout($self->{__timeout});
    $agent;
}

sub discover {
    my($self,$url) = @_;
    my $agent = $self->init_agent;
    my $req = HTTP::Request->new( GET => $url );
    my $res = $agent->request($req);
    return self->error($url.' '.$res->status_line) 
        unless $res->is_success;
    my $c = $res->content;
    my @data;
    # Theoretically this is bad namespace form and eventually should 
    # be fixed. If you stick to the standard prefixes you're fine.
    while ( $c =~ m!(<rdf:RDF.*?</rdf:RDF>)!sg ) {
        if (my $tb = Net::Trackback::Data->parse($url,$1)) {
            push( @data, $tb ); 
        }
    }
    @data ? \@data : $self->error('Nothing to discover.')
}

sub send_ping {
    my($self,$ping) = @_;
    my $ua = $self->init_agent;
    my $ping_url = $ping->ping_url or
        return $self->error('No ping URL');
    my $req;
    $ping->timestamp(time);
    if ( $ping_url =~ /\?/ ) {
        $req = HTTP::Request->new( GET=>join('&', $ping_url, $ping->to_urlencoded) );
    } else {
        $req = HTTP::Request->new( POST => $ping_url );
        $req->content_type('application/x-www-form-urlencoded; charset='
            .$self->{__charset});
        $req->content( $ping->to_urlencoded );
    }
    my $res = $ua->request($req);
    return Net::Trackback::Message->new( {
        code=>$res->code, message=>$res->message } )
            unless $res->is_success;
    Net::Trackback::Message->parse( $res->content );
}

sub timeout { $_[0]->{__timeout} = $_[1] if $_[1]; $_[0]->{__timeout}; }
sub proxy { $_[0]->{__proxy} = $_[1] if $_[1]; $_[0]->{__proxy}; }
sub no_proxy { $_[0]->{__no_proxy} = $_[1] if $_[1]; $_[0]->{__no_proxy}; }
sub charset { $_[0]->{__charset} = $_[1] if $_[1]; $_[0]->{__charset}; }

1;

__END__

=begin

=head1 NAME

Net::Trackback::Client - a class for implementing Trackback client 
functionality. 

=head1 SYNOPSIS

 use Net::Trackback::Client;
 my $client = Net::Trackback::Client->new();
 my $url ='http://www.foo.org/foo.html';
 my $data = $client->discover($url);
 if (Net::Trackback->is_message($data)) {
    print $data->to_xml;
 } else {
    require Net::Trackback::Ping;
    my $p = {
        ping_url=>'http://www.foo.org/cgi/mt-tb.cgi/40',
        url=>'http://www.timaoutloud.org/archives/000206.html',
        title=>'The Next Generation of TrackBack: A Proposal',
        description=>'I thought it would be helpful to draft some 
            suggestions for consideration for the next generation (NG) 
            of the interface.'
    };
 my $ping = Net::Trackback::Ping->new($p);
 my $msg = $client->send_ping($ping);
 print $msg->to_xml;

=head1 METHODS

=item Net::Trackback::Client->new

Constructor method. Returns a Trackback client instance.

=item $client->discover($url)

A method that fetches the resource and searches for Trackback ping
data. If the given resource can not be retreived or Trackback data
was not found, C<undef> is returned. Use the C<errstr> method to
get the HTTP status code and message. If successful, returns a
reference to an array of L<Net::Trackback::Data> objects.

=item $client->send_ping($ping)

Executes a ping according to the L<Net::Trackback::Ping> object 
passed in and returns a L<Net::Trackback::Message> object with the 
results,

=item $client->timeout([$seconds])

An accessor to the LWP agent timeout in seconds. Default is 15 
seconds. If an optional parameter is passed in the value is set.

=item $client->proxy($proxy)

The URI of the proxy server to route all requests through. The default
is C<undef> -- no proxy.

=item $client->no_proxy([\@noproxy])

An ARRAY reference of domains to B<not> request through the proxy. 
If an optional parameter is passed in the value is set. The default 
list includes I<localhost> and I<127.0.0.1>.

=item $client->charset([$charset])

The charset header parameter to use when sending pings. If an
optional parameter is passed in the value is set. The default is
'utf-8'.

=head2 Errors

This module is a subclass of L<Class::ErrorHandler> and inherits
two methods for passing error message back to a caller.

=item Class->error($message) 

=item $object->error($message)

Sets the error message for either the class Class or the object
$object to the message $message. Returns undef.

=item Class->errstr 

=item $object->errstr

Accesses the last error message set in the class Class or the
object $object, respectively, and returns that error message.

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end