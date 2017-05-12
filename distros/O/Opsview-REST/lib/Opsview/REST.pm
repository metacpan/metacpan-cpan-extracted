package Opsview::REST;
{
  $Opsview::REST::VERSION = '0.013';
}

use Moo;
use Carp;
use Opsview::REST::Config;
use Opsview::REST::Exception;

with 'Opsview::REST::APICaller';

has [qw/ user base_url /] => (
    is       => 'ro',
    required => 1,
);

has [qw/ pass auth_tkt /] => (
    is  => 'ro',
);

{
    # install methods in the namespace for configurable objects
    my @config_objects = qw/
        contact host role servicecheck hosttemplate attribute timeperiod
        hostgroup servicegroup notificationmethod hostcheckcommand keyword
        monitoringserver
    /;

    for my $obj_type (@config_objects) {
        no strict 'refs';

        my $general_url = Opsview::REST::Config->new($obj_type);

        # Single object get (get_contact, get_host, ...)
        # URL: /rest/config/{object_type}/{id}
        # GET - get object details
        *{__PACKAGE__ . "::get_$obj_type"} = sub {
            my $self = shift;
            my $id   = shift;
            croak "Required id" unless defined $id;

            my $uri = Opsview::REST::Config->new($obj_type, $id);
            return $self->get($uri->as_string);
        };

        # Multiple object get (get_contacts, get_hosts, ...)
        # URL: /rest/config/{object_type}
        # GET - list object type. Can pass in search attributes
        *{__PACKAGE__ . '::get_' . $obj_type . 's'} = sub {
            my $self = shift;
            require JSON;
            my $uri = Opsview::REST::Config->new(
                $obj_type,
                json_filter => JSON::encode_json({@_}),
            );
            return $self->get($uri->as_string);

        };

        # Create object
        # URL: /rest/config/{object_type}
        # POST - add a new object or a list of object type
        *{__PACKAGE__ . "::create_$obj_type"} = sub {
            my $self = shift;
            my $uri  = Opsview::REST::Config->new($obj_type);
            my $to_post;
            if (ref $_[0] && ref $_[0] eq 'ARRAY') {
                $to_post = { list => shift };
            } else {
                $to_post = { @_ };
            }
            return $self->post($uri->as_string, $to_post);
        };

        # Alias to call last method in plural
        *{__PACKAGE__ . "::create_${obj_type}s"} =
            *{__PACKAGE__ . "::create_$obj_type"};

        # Clone object
        # URL: /rest/config/{object_type}/{id}
        # POST - clone this object with merged incoming data to create
        # new object
        *{__PACKAGE__ . "::clone_$obj_type"} = sub {
            my $self = shift;
            my $id   = shift;
            croak "Required id" unless defined $id;

            my $uri = Opsview::REST::Config->new($obj_type, $id);
            return $self->post($uri->as_string, { @_ });
        };

        # Create or update
        # URL: /rest/config/{object_type}
        # PUT - create or update (based on unique keys) object or a list
        # of objects
        *{__PACKAGE__ . "::create_or_update_$obj_type"} = sub {
            my $self = shift;
            my $uri  = Opsview::REST::Config->new($obj_type);
            my $to_post;
            if (ref $_[0] && ref $_[0] eq 'ARRAY') {
                $to_post = { list => shift };
            } else {
                $to_post = { @_ };
            }
            return $self->put($uri->as_string, $to_post);
        };
        # Alias to call last method in plural
        *{__PACKAGE__ . "::create_or_update_${obj_type}s"} =
            *{__PACKAGE__ . "::create_or_update_$obj_type"};


        # Update
        # URL: /rest/config/{object_type}/{id}
        # PUT - update this object's details
        *{__PACKAGE__ . "::update_$obj_type"} = sub {
            my $self = shift;
            my $id   = shift;
            croak "Required id" unless defined $id;

            my $uri = Opsview::REST::Config->new($obj_type, $id);
            return $self->put($uri->as_string, { @_ });
        };

        # Delete
        # URL: /rest/config/{object_type}/{id}
        # DELETE - delete object
        *{__PACKAGE__ . "::delete_$obj_type"} = sub {
            my $self = shift;
            my $id   = shift;
            croak "Required id" unless defined $id;

            my $uri = Opsview::REST::Config->new($obj_type, $id);
            return $self->delete($uri->as_string, { @_ });
        };
    }
}

sub BUILD {
    my ($self) = @_;
    
    my $r;
    if (defined $self->pass) {
        $r = $self->post('/login', {
            username => $self->user,
            password => $self->pass,
        });

    } elsif (defined $self->auth_tkt) {
        $self->headers->{'Cookie'} = 'auth_tkt=' . $self->auth_tkt . ';';
        $r = $self->post('/login_tkt', { username => $self->user });

        # Clean the cookie as this is not required anymore
        delete $self->headers->{'Cookie'};

    } else {
        croak "Need either a pass or an auth_tkt";
    }

    $self->headers->{'X-Opsview-Username'} = $self->user;
    $self->headers->{'X-Opsview-Token'}    = $r->{token};

}

# Status
sub status {
    my $self = shift;

    require Opsview::REST::Status;
    my $uri = Opsview::REST::Status->new(@_);

    return $self->get($uri->as_string);
}

# Event
sub events {
    my $self = shift;

    require Opsview::REST::Event;
    my $uri = Opsview::REST::Event->new(@_);

    return $self->get($uri->as_string);
}

# Downtime
sub _downtime {
    my $self = shift;

    require Opsview::REST::Downtime;
    my $uri = Opsview::REST::Downtime->new(@_);

    return $uri->as_string;
}

sub downtimes {
    my $self = shift;
    return $self->get($self->_downtime(@_));
}

sub create_downtime {
    my $self = shift;
    return $self->post($self->_downtime(@_));
}

sub delete_downtime {
    my $self = shift;
    return $self->delete($self->_downtime(@_));
}

# Reload
sub reload {
    my $self = shift;
    return $self->post('/reload');
}

sub reload_info {
    my $self = shift;
    return $self->get('/reload');
}

# Acknowledge
sub _ack {
    my $self = shift;

    require Opsview::REST::Acknowledge;
    my $uri = Opsview::REST::Acknowledge->new(@_);

    return $uri->as_string;
}

sub acknowledge_list {
    my $self = shift;
    return $self->get($self->_ack(@_));
}

sub acknowledge {
    my $self = shift;
    return $self->post($self->_ack(@_));
}

# Recheck
sub recheck {
    my $self = shift;

    require Opsview::REST::Recheck;
    my $uri = Opsview::REST::Recheck->new(@_);

    return $self->post($uri->as_string);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME
    
Opsview::REST - Interface to the Opsview REST API

=head1 SYNOPSIS

    use Opsview::REST;

    my $ops = Opsview::REST->new(
        base_url => 'http://opsview.example.com/rest',
        user     => 'username',
        pass     => 'password',
    );

    # Check status
    my $status = $ops->status(
        'hostgroup',
        'hostgroupid' => [1, 2],
        'filter'      => 'unhandled',
    );

    # Configuration methods
    my $host1 = $ops->create_host(
        ip                  => '192.168.0.1',
        name                => 'monitoring-slave',
        hostgroup           => { name => 'Monitoring Servers' },
        notification_period => { name => '24x7' },
    );

    $ops->clone_host(
        $host1->{object}->{id},
        name => 'another-host',
        ip   => '192.168.0.2',
    );

    # Search methods support complex SQL::Abstract queries
    my $hosts = $ops->get_hosts(
        -or => [
            name => { -like => '%.example.com' },
            ip   => { -like => '10.25.%' },
        ],
    );

    # Update several objects at once
    map { $_->{check_attempts} = 4 } @{ $hosts->{list} };
    my $response = $ops->create_or_update_hosts($hosts->{list});

    # ... or only one
    my $response = $ops->create_or_update_host(
        name         => 'host1.example.com',
        snmp_version => '2c',
    );

    # Reload after make changes in config
    $ops->reload;

=head1 DESCRIPTION

Opsview::REST is a set of modules to access the Opsview REST API, which is the
recommended method for scripting configuration changes or any other form of
integration since version 3.9.0

=head1 METHODS

=head2 new

Return an instance of the Opsview::REST.

=head3 Required Arguments

=over 4

=item base_url

Base url where the REST API resides. By default it is under C</rest>.

=item user

Username to login as.

=back

=head3 Other Arguments

=over 4

=item pass

=item auth_tkt

Either the pass or the auth_tkt MUST be passed. It will die horribly if none
of these are found.

=item ua

A user agent object can be provided here. It should be an L<HTTP::Tiny>
subclass.

=back

=head2 get($url)

Makes a "GET" request to the API. The response is properly deserialized and
returned as a Perl data structure.

=head2 status( $endpoint, [ %args ] )

Convenience method to request the "status" part of the API. C<$endpoint> is
the endpoint to send the query to. C<%args> is a hash which will get properly
translated to URL arguments.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:status>

=head2 downtimes

=head2 create_downtime( %args )

=head2 delete_downtime( [ %args ] )

Downtime related methods.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:downtimes>

=head2 events( [ %args ] )

Get events. An event is considered to be either:

=over 4

=item *

a host or service changing state

=item *

a host or service result during soft failures

=item *

a host or service in a failure state where 'alert every failure' is enabled

=back

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:event>

=head2 acknowledge( [ %args ] )

Acknowledge problems.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:acknowledge>

=head2 acknowledge_list

Lists the problems which the current logged in user has permission to
acknowledge.

=head2 reload

Initiates a synchronous reload. Be careful: if your opsview reload takes more
than 60 seconds to run, this call will time out. The returned data contains
the info of the reload.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi#initiating_an_opsview_reload>

=head2 reload_info

Get status of reload.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi#initiating_an_opsview_reload>

=head2 recheck( [ %args ] )

Recheck services or hosts asynchronously. It returns info about the number of
hosts and services that will be rechecked.

More info: L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:recheck>

=head2 Config methods for single objects

=head3 get_*

=head3 create_*

=head3 clone_*

=head3 create_or_update_*

=head3 delete_*

This methods will be generated for the following types of objects: C<contact>,
C<role>, C<servicecheck>, C<hosttemplate>, C<attribute>, C<timeperiod>,
C<hostgroup>, C<servicegroup>, C<notificationmethod>, C<hostcheckcommand>,
C<keyword>, C<monitoringserver>.

They all except C<create>, require the object's id. Additionally, C<create>,
C<clone> and C<create_or_update> accept a list of key-value pairs:

    my $host1 = $ops->create_host(
        name => 'host1',
        ip   => '192.168.10.27',
    );

    $ops->clone_host(
        $host1->{object}->{id},
        name => 'host2',
        ip   => '192.168.10.28',
    );

    $host->delete($id);

=head2 Config methods for multiple objects

=head3 get_*

=head3 create_*

=head3 create_or_update_*

This methods will be generated for the following types of objects: C<contacts>,
C<roles>, C<servicechecks>, C<hosttemplates>, C<attributes>, C<timeperiods>,
C<hostgroups>, C<servicegroups>, C<notificationmethods>, C<hostcheckcommands>,
C<keywords>, C<monitoringservers>.

C<get> accepts complex queries in L<SQL::Abstract> format.

C<create_or_update> is specially useful when you want to update several objects
with a single call:

    # First get a list of objects you want to modify
    my $dbhosts = $ops->get_hosts(
        name    => { -like => 'db%' },
    );

    # $dbhosts = {
    #   summary => { ... },
    #   list => [ { name => 'db1.example.com , ... }, ... ],
    # };

    # Modify them as you need
    map { $_->{check_attempts} = 4 } @{ $dbhosts->{list} };

    # Make the call
    $ops->create_or_update($dbhosts->{list});


To know which fields are accepted for each type of object, the format of the
responses, and additional info:

L<http://docs.opsview.com/doku.php?id=opsview-core:restapi:config>

=head1 SEE ALSO

=over 4

=item *

L<http://www.opsview.org/>

=item *

L<Opsview REST API Documentation|http://docs.opsview.com/doku.php?id=opsview-core:restapi>

=back

=head1 AUTHOR

=over 4

=item *

Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut


