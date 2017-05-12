package Net::Marathon;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;
use Net::Marathon::App;
use Net::Marathon::Group;
use Net::Marathon::Events;
use Net::Marathon::Deployment;

=head1 NAME

Net::Marathon - An object-oriented Mapper for the Marathon REST API, fork of Marathon module

=cut

our $VERSION = '0.1.0';
our $verbose = 0;


=head1 SYNOPSIS

Net::Marathon 0.1.0 is a fork of Marathon 0.9 with a fix on Events API (applied this patch https://github.com/geidies/perl-Marathon/pull/1).
Otherwise it is the same, more differences may come in future versions.

This module is a wrapper around the [Marathon REST API](http://mesosphere.github.io/marathon/docs/rest-api.html), so it can be used without having to write JSON by hand.

For the most common tasks, there is a helper method in the main module. Some additional methods are found in the Net::Marathon::App etc. submodules.

To start, create a marathon object:

    my $m = Net::Marathon->new( url => 'http://my.marathon.here:8080' );

    my $app = $m->get_app('hello-marathon');

    $app->instances( 23 );
    $app->update();
    print STDERR Dumper( $app->deployments );

    sleep 10;

    $app->instances( 1 );
    $app->update( {force => 'true'} ); # should work even if the scaling up is not done yet.


=head1 SUBROUTINES/METHODS

=head2 new

Creates a Marathon object. You can pass in the URL to the marathon REST interface:

    use Net::Marathon;
    my $marathon = Net::Marathon->new( url => 'http://169.254.47.11:8080', verbose => 0 );

The "verbose" parameter makes the module more chatty on STDERR.

=cut

sub new {
    my ($class, %conf) = @_;
    my $url = delete $conf{url} || 'http://localhost:8080/';
    $Net::Marathon::verbose = delete $conf{verbose} || 0;
    my $ua = LWP::UserAgent->new;
    my $self = bless {
      _ua     => $ua,
    };
    $self->_set_url($url);
    return $self;
}

sub _set_url { # void
  my ($self, $url) = @_;
  unless ( $url =~ m,^https?\://, ) {
      $url = 'http://' . $url;
  }
  unless ( $url =~ m,/$, ) {
      $url .= '/';
  }
  $self->{_url} = $url;
}

=head2 get_app( $id )

Returns a Net::Marathon::App as identified by the single argument "id". In case there is no such app, will return undef.

    my $app = $marathon->get_app('such-1');
    print $app->id . "\n";

=cut

sub get_app { # Net::Marathon::App
    my ( $self, $id ) = @_;
    my $api_response = $self->_get_obj('/v2/apps/' . $id);
    return undef unless defined $api_response;
    return Net::Marathon::App->new( $api_response->{app}, $self );
}

=head2 new_app( $config )

Returns a new Net::Marathon::App as described in the $config hash. Example:

    my $app = $marathon->new_app({ id => 'very-1', mem => 4, cpus => 0.1, cmd => "while [ 1 ]; do echo 'wow.'; done" });

This will not (!) start the app in marathon. To do so, call create() on the returned object:

    $app->create();

=cut

sub new_app {
    my ($self, $config) = @_;
    return Net::Marathon::App->new( $config, $self );
}

=head2 get_group( $id )

Works like get_app, just for groups.

=cut

sub get_group { # Net::Marathon::App
    my ( $self, $id ) = @_;
    return Net::Marathon::Group->get( $id, $self );
}

=head2 new_group( $config )

Creates a new group. You can either specify the apps in-line:

    my $group = $marathon->new_group( { id => 'very-1', apps: [{ id => "such-2", cmd => ... }, { id => "such-3", cmd => ... }] } );

Or add them to the created group later:

    my $group = $marathon->new_group( { id => 'very-1' } );
    $group->add( $marathon->new_app( { id => "such-2", cmd => ... } );
    $group->add( $marathon->new_app( { id => "such-3", cmd => ... } );

In any case, new_group will just return a Net::Marathon::Group object, it will not commit to marathon until you call create() on the returned object:

    $group->create();

=cut

sub new_group {
    my ($self, $config) = @_;
    return Net::Marathon::Group->new( $config, $self );
}

=head2 events()

Returns a Net::Marathon::Events objects. You can register callbacks on it and start listening to the events stream. 

=cut

sub events {
    my $self = shift;
    return Net::Marathon::Events->new( $self );
}

=head2 get_tasks( $status )

Returns an array of currently running tasks. If $status is "running" or "staging", will filter and return only those tasks.

=cut

sub get_tasks {
    my ($self, $status) = @_;
    $status = '' unless $status && $status =~ m/^running|staging$/;
    if ( $status ) {
        $status = '?status='.$status;
    }
    my $task_obj = $self->_get_obj_from_json('/v2/tasks'.$status);
    my $task_arrayref = ( defined $task_obj && exists $task_obj->{tasks} && $task_obj->{tasks} ) || [];
    return wantarray ? @{$task_arrayref} : $task_arrayref;
}

=head2 kill_tasks({ tasks => $@ids, scale => bool })

Kills the tasks with the given @ids. Scales if the scale param is true.

=cut

sub kill_tasks {
    my ($self, $args) = @_;
    my $param = $args && $args->{scale} && $args->{scale} && $args->{scale} !~ /false/i ? '?scale=true' : ''; #default is false
    return $self->_put_post_delete( 'POST', '/v2/tasks/delete'.$param, { ids => $args->{tasks} } );
}

=head2 get_deployments

Returns a list of Net::Marathon::Deployment objects with the currently running deployments.

=cut

sub get_deployments {
    my $self = shift;
    my $deployments = $self->_get_obj('/v2/deployments');
    my @depl_objs = ();
    foreach ( @{$deployments} ) {
        push @depl_objs, Net::Marathon::Deployment->new( $_, $self );
    }
    return wantarray ? @depl_objs : \@depl_objs;
}

=head2 kill_deployment( $id, { force => bool } )

Stop the deployment with given id.

=cut

sub kill_deployment {
    my ($self, $id, $args) = @_;
    my $param = $args && $args->{force} && $args->{force} && $args->{force} !~ /false/i ? '?force=true' : ''; #default is false
    return $self->_put_post_delete( 'DELETE', '/v2/deployments/' . $id . $param );
}

sub get_endpoint {
    my ( $self, $path ) = @_;
    my $url = $self->{_url} . $path;
    $url =~ s,/+,/,g;
    $url =~ s,^http:/,http://,;
    return $url;
}

=head2 metrics

returns the metrics returned by the /metrics endpoint, converted from json to perl.

=cut

sub metrics {
    my $self = shift;
    return $self->_get_obj('/metrics');
}

=head2 help

returns the HTML returned by the /help endpoint.

=cut

sub help { # string (html)
    my $self = shift;
    return $self->_get_html('/help');
}

=head2 logging

returns the HTML returned by the /logging endpoint.

=cut

sub logging { # string (html)
    my $self = shift;
    return $self->_get_html('/logging');
}

=head2 ping

returns 1 if the master responds to a ping request.

=cut

sub ping { # string (plaintext)
    my $self = shift;
    return $self->_get_html('/ping') =~ m,pong, ? 'pong' : undef;
}

sub _get { # HTTP::Response
    my ( $self, $path ) = @_;
    my $url = $self->get_endpoint( $path );
    my $response = $self->{_ua}->get( $url );
    $self->_response_handler( 'GET', $response );
    return $response;
}

sub _get_html { # string (html) or undef on error
    my ( $self, $path ) = @_;
    my $response = $self->_get($path);
    if ( $response->is_success ) {
        return $response->decoded_content;
    }
    return '';
}

sub _get_obj { # hashref
    my ( $self, $path ) = @_;
    my $response = $self->_get_html($path);
    if ($response) {
        return decode_json $response;
    }
    return undef;
}

sub _get_obj_from_json { # hashref
    my ( $self, $path ) = @_;
    my $response = $self->_put_post_delete('GET', $path);
    if ($response) {
        return decode_json $response;
    }
    return undef;
}

sub _post {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'POST', $path, $payload );
}

sub _put {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'PUT', $path, $payload );
}

sub _delete {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'DELETE', $path, $payload );
}

sub _put_post_delete {
    my ($self, $method, $path, $payload) = @_;
    my $req = HTTP::Request->new( $method, $self->get_endpoint($path) );
    $req->header( 'Accept' => 'application/json' );
    if ( $payload ) {
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( encode_json $payload );
    }
    my $response = $self->{_ua}->request( $req );
    $self->_response_handler( $method, $response );
    return $response->is_success ? $response->decoded_content : undef;
}

sub _response_handler {
    my ( $self, $method, $response ) = @_;
    if ( $verbose ) {
        unless ( $response->is_success ) {
            print STDERR 'Error doing '.$method.' against '. $response->base.': ' . $response->status_line . "\n";
            print STDERR $response->decoded_content ."\n";
        } else {
            print STDERR $response->status_line . "\n"
        }
    }
    return $response;
}

=head1 AUTHOR

Sebastian Geidies C<< <seb at geidi.es> >> (original Marathon module)

Miroslav Tynovsky

=cut

1;
