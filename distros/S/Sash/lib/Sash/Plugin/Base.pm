package Sash::Plugin::Base;

use strict;
use warnings;

our $VERSION = '1.01';

use Carp;

my $_client;
my $_username;
my $_password;
my $_endpoint;
my $_vendor;
my $_database;
my $_hostname;

sub enable {
    my $class = shift;
    my $args = shift;
    
    # Make sure we have the correct parameters defined so that we can connect
    # to salesforce
    croak $class . '->enable Invalid Invocation - args must be a hash ref' unless ref $args eq 'HASH';

    croak $class . '->enable Invalid Invocation - missing username, password, endpoint or terminal'
        unless defined $args->{username} && defined $args->{password} && defined $args->{endpoint};
    
    # Define our highlander constants that are referenced by the show command.
    $_username = $args->{username};
    $_password = $args->{password};
    $_endpoint = $args->{endpoint};
    
    eval {
        $class->connect( $args );
    }; if ( $@ ) {
        croak "Unable to connect to datasource: $@";
    }
}

sub connect {
    croak __PACKAGE__ . '->connect - Can not invoke abstract class method directly';
}

sub username {
    my $class = shift;
    return $_username = ( shift || $_username );
}

sub password {
    my $class = shift;
    return $_password = ( shift || $_password );
}

sub endpoint {
    my $class = shift;
    return $_endpoint = ( shift || $_endpoint );
}

sub client {
    my $class = shift;
    return $_client = ( shift || $_client );
}

sub vendor {
    my $class = shift;
    return $_vendor = ( shift || $_vendor );
}

sub database {
    my $class = shift;
    return $_database = ( shift || $_database );
}

sub hostname {
    my $class = shift;
    return $_hostname = ( shift || $_hostname );
}


1;
