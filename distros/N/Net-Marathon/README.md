# NAME

Net::Marathon - An object-oriented Mapper for the Marathon REST API, fork of Marathon module

# SYNOPSIS

Net::Marathon 0.1.0 is a fork of Marathon 0.9 with a fix on Events API (applied this patch https://github.com/geidies/perl-Marathon/pull/1).
Otherwise it is the same, more differences may come in future versions.

This module is a wrapper around the \[Marathon REST API\](http://mesosphere.github.io/marathon/docs/rest-api.html), so it can be used without having to write JSON by hand.

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

# SUBROUTINES/METHODS

## new

Creates a Marathon object. You can pass in the URL to the marathon REST interface:

    use Net::Marathon;
    my $marathon = Net::Marathon->new( url => 'http://169.254.47.11:8080', verbose => 0 );

The "verbose" parameter makes the module more chatty on STDERR.

## get\_app( $id )

Returns a Net::Marathon::App as identified by the single argument "id". In case there is no such app, will return undef.

    my $app = $marathon->get_app('such-1');
    print $app->id . "\n";

## new\_app( $config )

Returns a new Net::Marathon::App as described in the $config hash. Example:

    my $app = $marathon->new_app({ id => 'very-1', mem => 4, cpus => 0.1, cmd => "while [ 1 ]; do echo 'wow.'; done" });

This will not (!) start the app in marathon. To do so, call create() on the returned object:

    $app->create();

## get\_group( $id )

Works like get\_app, just for groups.

## new\_group( $config )

Creates a new group. You can either specify the apps in-line:

    my $group = $marathon->new_group( { id => 'very-1', apps: [{ id => "such-2", cmd => ... }, { id => "such-3", cmd => ... }] } );

Or add them to the created group later:

    my $group = $marathon->new_group( { id => 'very-1' } );
    $group->add( $marathon->new_app( { id => "such-2", cmd => ... } );
    $group->add( $marathon->new_app( { id => "such-3", cmd => ... } );

In any case, new\_group will just return a Net::Marathon::Group object, it will not commit to marathon until you call create() on the returned object:

    $group->create();

## events()

Returns a Net::Marathon::Events objects. You can register callbacks on it and start listening to the events stream. 

## get\_tasks( $status )

Returns an array of currently running tasks. If $status is "running" or "staging", will filter and return only those tasks.

## kill\_tasks({ tasks => $@ids, scale => bool })

Kills the tasks with the given @ids. Scales if the scale param is true.

## get\_deployments

Returns a list of Net::Marathon::Deployment objects with the currently running deployments.

## kill\_deployment( $id, { force => bool } )

Stop the deployment with given id.

## metrics

returns the metrics returned by the /metrics endpoint, converted from json to perl.

## help

returns the HTML returned by the /help endpoint.

## logging

returns the HTML returned by the /logging endpoint.

## ping

returns 1 if the master responds to a ping request.

# AUTHOR

Sebastian Geidies `<seb at geidi.es>` (original Marathon module)

Miroslav Tynovsky
