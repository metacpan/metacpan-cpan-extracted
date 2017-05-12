
package Net::MarkLogic::XDBC;

=head1 NAME

Net::MarkLogic::XDBC - XDBC connectivity for MarkLogic CIS servers.

=head1 SYNOPSIS

  use Net::MarkLogic::XDBC
 
  $xdbc = Net::MarkLogic::XDBC->new( "user:pass@localhost:9000" );
  
  $xdbc = Net::MarkLogic::XDBC->new(host     => $host,
                                    port     => $port,
                                    username => $user,
                                    password => $pass, );

  $result = $agent->query($xquery);

  print $result->content;

  @items = $result->items;
  print $item->content;

=head1 DESCRIPTION

Alpha. API will change.

Connect to a CIS XDBC server and execute xquery code.

=cut

use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent;
use Class::Accessor;
use Class::Fields;
use URI::Escape;
use Template;

use Net::MarkLogic::XDBC::Result;

our $VERSION     = 0.11;

our @BASIC_FIELDS = qw(host port username password uri);
our @REQUIRED_FIELDS = qw(host port username password);

use base qw(Class::Accessor Class::Fields);
use fields @BASIC_FIELDS, qw(ua header template);
Net::MarkLogic::XDBC->mk_accessors( @BASIC_FIELDS );


=head1 METHODS

=head2 new()

  $xdbc = Net::MarkLogic::XDBC->new( "user:pass@localhost:9000" );

  $xdbc = Net::MarkLogic::XDBC->new( host     => $hostname,
                                     port     => $port,
                                     username => $user,
                                     password => $pass, );


Connect using a connection string or named host, port, username, and password parameters. 
=cut

sub new
{
    my $class = shift;
    
    my %args;
    
    if (scalar @_ == 1)
    {
        $_[0] =~ m/
            ^  ([^:]+)    # username 
            :  ([^\s\@]+) # password
            \@ ([\w\-\.]+)  # hostname
            :  (\d+) $    # port
        /x or die "Bad connection string: $_[0]";

        $args{username} = $1;
        $args{password} = $2;
        $args{host}     = $3;
        $args{port}     = $4;
    }
    else { %args = @_; }
    
    foreach my $key (@REQUIRED_FIELDS) {
        die "Invalid connection info. Missing $key." unless $args{$key};
    }

    my $self = bless ({}, ref ($class) || $class);

    $self->host($args{host});
    $self->port($args{port});
    $self->username($args{username});
    $self->password($args{password});

    return ($self);
}


=head2 query()

    $result = $xdbc->query($xquery);

Execute XQUERY code on XDBC server.

=cut

sub query 
{
    my $self   = shift;
    my $xquery = shift;

    die "Need xquery argument" unless $xquery = uri_escape($xquery);


    my $request = HTTP::Request->new("POST", $self->server_uri, 
                                     $self->header, "xquery=$xquery");

    my $http_response = $self->ua->request($request);

    my $result = Net::MarkLogic::XDBC::Result->new( 
            response => $http_response 
            );

    return $result;
}

=head2 query_from_template()

    $result = $xdbc->query_from_template($template, $args);

Generate XQUERY code from a template toolkit template and arguments, then execute on XDBC server.

This might be overkill, but it's definitely a feature you're not going to find
in the Java API.

=cut

sub query_from_template 
{
    my $self     = shift;
    my $template = shift;
    my $args     = shift;
 
    my $t = Template->new();

    my $xquery;
    $t->process($template, $args, \$xquery);

    return $self->query($xquery);  
} 
# server_uri()
# The XDBC uri, either generated from defaults based on the given host and port
# or generated from a supplied uri.
sub server_uri 
{
    my $self = shift;

    if ($self->uri) { return $self->uri; }
    else { return "http://" . $self->host . ":" . $self->port . "/eval"; }
}

=head1 ATTRIBUTE METHODS 

These methods function as setter/getters for the objects attributes.

$get = $xdbc->foo();
$xdbc->foo($set);

These shouldn't be important unless you need to finetune the behavior or tweak
the settings.


=head2 ua()

LWP::UserAgent, just in case anyone needs to tweak settings.

=cut

sub ua 
{
    my $self = shift;
                                                                                
    $self->{ua} = $_[0] if $_[0];

    unless ($self->{ua}) 
    {
        my $ua = LWP::UserAgent->new( agent => 
                     "Net::MarkLogic::XDBC/$VERSION MarkXDBC/2.2-1",);
        $self->{ua} = $ua;
    }                                                                                 
    return $self->{ua};
}

=head2 header()

HTTP::Headers, sent on every request to the XDBC server.

=cut

sub header 
{
    my $self = shift;
    
    $self->{header} = $_[0] if $_[0];

    unless ($self->{header}) 
    {
        my $header = HTTP::Headers->new();
        $header->authorization_basic( $self->username, $self->password );
        $self->{header} = $header;
    }
   
    return $self->{header};
}

=head2 host()

Name or IP address of the XDBC server host.

=head2 port()

Port number of XDBC server.

=head2 username()

User used for authentication.

=head2 password()

Password used for authentication.

=head2 uri()

Set a custom URI to connect to the XDBC server. Default connection go to
"http://$host:$port/eval".


=head1 BUGS

Big time. Watch out for changing APIs.


=head1 AUTHOR

    Tony Stubblebine
    tonys@oreilly.com

=head1 ACKNOWLEDGEMENTS

    Code contributions from: Michael Blakeley
 
    Advice and comments from Raffaele Sena, Ryan Grimm, Andy Bruno.

=head1 COPYRIGHT

Copyright 2004 Tony Stubblebine 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 SEE ALSO

MarkLogic Documentation:
http://xqzone.marklogic.com/

=cut

1; #this line is important and will help the module return a true value
__END__

