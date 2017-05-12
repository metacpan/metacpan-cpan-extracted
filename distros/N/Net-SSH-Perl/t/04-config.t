#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;

use vars qw( $CFG_FILE );

use lib 't';

require 'test-common.pl';

use Net::SSH::Perl;
use Net::SSH::Perl::Config;

my $cfg = Net::SSH::Perl::Config->new("foo");

{
    ok( $cfg, 'created config object' );
    $cfg->read_config($CFG_FILE);

    is( $cfg->get('port'), 10000, 'port is 10000' );

    $cfg->set('port', 5000);
    is( $cfg->get('port'), 5000, 'port was set to 5000' );
}

{
    ## Test identity file special case.
    my $if = $cfg->get('identity_files');
    ok( $if, 'got identity_files config' );
    is( scalar @$if, 2, 'got two entries' );
    is( $if->[0], 'identity', 'first entry is "identity"' );
    is( $if->[1], 'identity2', 'second entry is "identity2"' );
}

{
    ## Test "Cipher" config directive, which was broken in versions
    ## prior to 0.64.
    $cfg->merge_directive("Cipher idea");
    is( $cfg->get('cipher'), 'IDEA', 'cipher is IDEA after merge' );
}

my $cfg2 = Net::SSH::Perl::Config->new( "foo", port => 22 );
{
    ## Test whether options given in constructor override config file.
    ok( $cfg2, 'create a new config with an overridden option' );
    $cfg2->read_config($CFG_FILE);
    is( $cfg2->get('port'), 22, 'port is 22' );
}

{
    ## Test whether we can use merge_directive to merge in a directive
    ## in a string.
    $cfg2->merge_directive("RhostsAuthentication no");
    ok( ! $cfg2->get('auth_rhosts'), 'auth_rhosts is false' );
}

my $cfg3 = Net::SSH::Perl::Config->new("dummy");

{
    ## Test grabbing a different Host record from the config file.
    is( $cfg3->{host}, "dummy" ,'host is "dummy"' );
    $cfg3->read_config($CFG_FILE);
    is( $cfg3->get('port'), 5000, 'port is 5000' );
    ok( $cfg3->get('interactive'), 'interactive is true' );
}

{
    ## Test that config file gets read correctly when passed to
    ## Net::SSH::Perl constructor.
    my $ssh = Net::SSH::Perl->new( 'foo', user_config => $CFG_FILE, _test => 1 );
    ok( $ssh, 'make a new SSH object' );
    ok( $ssh->config, 'object has config' );
    is( $ssh->config->get('port'), 10000, 'port for object is 10000' );

    ## Test that Net::SSH::Perl uses the HostName directive to
    ## override the host passed to the constructor.
    is( $ssh->config->get('hostname'), 'foo.bar.com', 'hostname is foo.bar.com' );
    is( $ssh->{host}, 'foo.bar.com', 'host key in object is foo.bar.com' );
}

{
    ## And that constructor overrides work here, as well.
    my $ssh = Net::SSH::Perl->new( 'foo', user_config => $CFG_FILE, port => 22, _test => 1 );
    is( $ssh->config->get('port'), 22, 'port is 22 after override in SSH constructor' );
}

{
    ## And now test whether we can set additional options through
    ## Net::SSH::Perl constructor; and that they override config
    ## file.
    my $ssh = Net::SSH::Perl->new( 'foo', user_config => $CFG_FILE,
                                   options => [ "Port 22",
                                                "RhostsAuthentication no",
                                                "BatchMode no" ],
                                   _test => 1 );

    is( $ssh->config->get('port'), 22, 'port is 22 after override via "options"' );
    ok( ! $ssh->config->get('auth_rhosts'), 'auth_rhosts is false' );
    ok( $ssh->config->get('interactive'), 'interactive is true' );

}

{
    ## Test whether a user we pass in through constructor properly
    ## overrides the absence of a user passed in through login method.
    my $ssh = Net::SSH::Perl->new( 'foo', options => [ "User bar" ], _test => 1 );
    is( $ssh->config->get('user'), 'bar', 'user is "bar"' );
    $ssh->login;
    is( $ssh->config->get('user'), 'bar', 'user is "bar" after ->login' );
}
