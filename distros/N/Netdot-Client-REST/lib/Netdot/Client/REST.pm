package Netdot::Client::REST;

use warnings;
use strict;
use Carp;
use LWP;
use XML::Simple;
use Data::Dumper;
use vars qw($VERSION);
$VERSION = '1.03';

1;

=head1 NAME

Netdot::Client::REST - RESTful API for Netdot

=head1 SYNOPSIS

 use Netdot::Client::REST;
 use Data::Dumper;

 my $netdot = Netdot::Client::REST->new(
     server=>'http://localhost.localdomain/netdot',
     username=>'admin',
     password=>'xxxxx',
     );

 # Get all devices
 my @devs = $netdot->get('/Device');

 print Dumper(@devs);

 # Get Device id 1
 my $dev = $netdot->get('/Device/1');

 # Get Device id 1 and foreign objects one level away
 my $dev = $netdot->get('/Device/1?depth=1');

 # Update Device 1
 $dev = $netdot->post('/Device/1', {community=>'public'});

 # Delete Device 1
 $netdot->delete('/Device/1');


See examples/ directory for a sample script

=head1 DESCRIPTION

Netdot::Client::REST can be used in Perl scripts that need access to the Netdot application
database. Communication occurs over HTTP/HTTPS, thus avoiding the need to open SQL access on the machine running Netdot.  

=head1 CLASS METHODS
=cut

############################################################################

=head2 new - Constructor and login method

  Arguments:
    server    - Netdot installation URL (e.g. http://host.localdomain/netdot)
    username  - Netdot username
    password  - Netdot password
    retries   - Number of retries (default: 3)
    timeout   - seconds (default: 10)
    format    - Representation format (default: xml)
                Currently only XML is supported
  Returns:
    Netdot::Client::REST object
  Examples:
    my $netdot = Netdot::Client::REST->new(
         server   =>'http://host.localdomain/netdot',
         username => 'myuser',
         password => 'mypass',
    );

=cut

sub new { 
    my ($proto, %argv) = @_;
    my $class = ref( $proto ) || $proto;

    my $self = {};
    foreach my $key ( qw(server username password) ){
	$self->{$key} = $argv{$key} || croak "Missing required parameter: $key";
    }
    $self->{timeout}  = $argv{timeout} || 10;
    $self->{retries}  = $argv{retries} || 3;
    $self->{format}   = 'xml';

    if ( $self->{format} eq 'xml' ){
	# Instantiate the XML::Simple class
	$self->{xs} = XML::Simple->new(
	    ForceArray => 1,
	    XMLDecl    => 1, 
	    KeyAttr    => 'id',
	    );
    }else{
	croak "Only XML formatting is supported at this time";
    }
    
    my %headers = (
	'Accept'     => 'text/'.$self->{format}.'; version=1.0',
	'User_Agent' => "Netdot::Client::REST/$VERSION",
	);
    
    my $h = HTTP::Headers->new(%headers);
    my $ua = LWP::UserAgent->new();
    $ua->default_headers($h);
    $ua->cookie_jar({});
    push (@{ $ua->requests_redirectable }, 'POST');
    
    my $login_url =  $self->{server}.'/NetdotLogin';

    my $attempt = 1;
    while ( $attempt <= $self->{retries} ){
	my $r = $ua->post($login_url, {
	    destination        => 'index.html',	
	    credential_0      => $self->{username},
	    credential_1      => $self->{password},
	    permanent_session => 1 }
	    );
	if ( $r->is_success ){
	    $self->{ua} = $ua;
	    $self->{base_url} = $self->{server}.'/rest';
	    bless $self, $class;
	    return wantarray ? ( $self, '' ) : $self; 
	}else{
	    $attempt++;
	    warn $r->status_line;
	}
    }
    croak 'Error: Could not log into '.$self->{server};
}


=head1 INSTANCE METHODS
=cut

############################################################################

=head2 get - Get all attributes from one or more Netdot objects

  Arguments:
    Resource  - string containing RESTful resource

    In addition to the object's class and (optional) ID, the HTTP argument "depth"
    allows the user to fetch all foreign objects recursively, limited by the
    value of the depth argument.  Foreign objects include relational records 
    referenced by the given object and records that reference the given object (both
    sides of the one-to-many relationship).  The performance impact of the given depth
    is a balance between fewer queries with large datasets and more queries with smaller
    datasets. The default depth is 0 (only return the given object plus references
    to objects directly related).

  Returns:
    hashref with object's attributes
    
    A special attribute is added for each foreign key that allows the programmer
    to request that resource more easily.  For example, if a record has a field
    called 'foo' which is a foreign key pointing to a record of class 'Bar', 
    with id '1', then the result hashref will include a keys like:

       foo => 'Foo bar name',
       foo_xlink => 'Bar/1',

    where 'foo_xlink' can be passed to this method to get the full Bar/1 resource.

  Examples:
    my $dev = $netdot->get('Device/1');
    my $dev = $netdot->get('Device/1?depth=1');
    my @alldevs = $netdot->get('Device');
    my @mydevs = $netdot->get('Device?sysname=mydev');
 
=cut

sub get { 
    my ($self, $resource) = @_;
    croak "Missing required arguments" unless ( $resource );
    
    my $data = {};
    my $url = $self->{base_url}.'/'.$resource;
    my $resp = $self->{ua}->get($url);
    if ( $resp->is_success ){
	$data = $self->{xs}->XMLin($resp->content);
    }else{
	croak "Error: could not get $url: ".$resp->status_line;
    }
}

############################################################################

=head2 post - Update or Insert a Netdot object

  Arguments:
    Resource  - string containing RESTful resource
    data      - Hashref containing key/value pairs
  Returns:
    hashref with object's attributes
  Examples:
    $netdot->post('Device/1', \%data);
    $netdot->post('Device', \%data);
 
=cut

sub post { 
    my ($self, $resource, $data) = @_;
    croak "Missing required arguments" unless ( $resource && $data );
    
    my $url = $self->{base_url}.'/'.$resource;
    my $resp = $self->{ua}->post($url, $data);
    if ( $resp->is_success ){
	$data = $self->{xs}->XMLin($resp->content);
    }else{
	croak "Error: could not post to $url: ".$resp->status_line;
    }
}

############################################################################

=head2 delete - Delete a Netdot object

  Arguments:
    Resource  - string containing RESTful resource
  Returns:
    True if successful
  Examples:
    $netdot->delete('Device/1');
 
=cut

sub delete { 
    my ($self, $resource) = @_;
    croak "Missing required arguments" unless ( $resource );
    
    my $url = $self->{base_url}.'/'.$resource;
    my $req = HTTP::Request->new(DELETE => $url);
    my $resp = $self->{ua}->request($req);
    if ( $resp->is_success ){
	return 1;
    }else{
	croak "Error: could not delete $url: ".$resp->status_line;
    }
}

=head1 AUTHOR

Carlos Vicente  <cvicente@cpan.org>

=head1 SEE ALSO

The Network Documentation Tool <http://netdot.uoregon.edu>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

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
=cut
