#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use Scalar::Util qw/reftype/;

use IOC;
use IOC::Registry;
use IOC::Service::Parameterized;

BEGIN {
    use_ok('MooseX::IOC');
}

{
    my $c = IOC::Container->new('MyApp');
    
    $c->register(IOC::Service->new('dbh' => sub { bless({} => 'MyDbh') }));
    
    $c->register(IOC::Service::Parameterized->new('logger' => sub { 
        my (undef, %params) = @_;
        bless(\%params => 'MyLogger') 
    }));    
    
    $c->register(IOC::Service::Parameterized->new('loc' => sub { 
        my (undef, %params) = @_;
        bless(\%params => 'Myi18n') 
    }));    
    
    my $r = IOC::Registry->new;
    $r->registerContainer($c);
}

{
    package MyApp;
    use Moose;
    
    has 'dbh' => (
        metaclass => 'IOC',
        is        => 'ro',
        isa       => 'MyDbh',
        service   => '/MyApp/dbh',
    );
    
    has 'logger' => (
        metaclass => 'IOC',        
        is        => 'ro',
        isa       => 'MyLogger',
        service   => [ '/MyApp/logger' => (log_file => 'foo.log') ],
    );  
    
    has 'loc' => (
        metaclass => 'IOC',        
        is        => 'ro',
        isa       => 'Myi18n',
        lazy      => 1,
        service   => sub {
            [ '/MyApp/loc' => (locale => $_[0]->default_locale) ]
        },
    );

    has missing => (
        metaclass => "IOC",
        is        => "ro",
        lazy      => 1,
        service   => "/MyApp/missing",
    );

    has not_missing => (
        metaclass => "IOC",
        is        => "ro",
        lazy      => 1,
        default   => "blah",
        service   => "/MyApp/missing",
    );

    has default_not_used => (
        metaclass => 'IOC',
        is        => 'ro',
        isa       => 'MyDbh',
        service   => '/MyApp/dbh',
        default   => sub { bless([],'MyDbh') },
    );
    
    
    sub default_locale { 'en' }   
}

# check meta-ness

isa_ok(MyApp->meta->get_attribute('dbh'), 'MooseX::IOC::Meta::Attribute');
isa_ok(MyApp->meta->get_attribute('logger'), 'MooseX::IOC::Meta::Attribute');

# check behavior

my $app = MyApp->new;
isa_ok($app, 'MyApp');

isa_ok($app->dbh, 'MyDbh');
isa_ok($app->logger, 'MyLogger');
isa_ok($app->loc, 'Myi18n');

is($app->logger->{log_file}, 'foo.log', '... parameters passed succcefully');
is($app->loc->{locale}, 'en', '... parameters passed succcefully');

throws_ok { $app->missing } qr/ServiceNotFound/, "can't get missing field";

lives_ok { $app->not_missing } "... unless it has a default";

is( eval { $app->not_missing }, "blah", "default value given" );

is( reftype($app->default_not_used), "HASH", "default not used" );

