#!/usr/bin/env perl

package Quiq::ApplicationPaths::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ApplicationPaths');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(9) {
    my $self = shift;

    $0 = '/opt/myapp/bin/prog';

    my $app = Quiq::ApplicationPaths->new;
    $self->is(ref($app),'Quiq::ApplicationPaths');

    my $name = $app->name;
    $self->is($name,'myapp');

    my $prefix = $app->prefix;
    $self->is($prefix,'');

    my $homeDir = $app->homeDir;
    $self->is($homeDir,'/opt/myapp');

    $homeDir = $app->homeDir('lib/perl5');
    $self->is($homeDir,'/opt/myapp/lib/perl5');

    my $etcDir = $app->etcDir;
    $self->is($etcDir,'/etc/opt/myapp');

    $etcDir = $app->etcDir('disclaimer.txt');
    $self->is($etcDir,'/etc/opt/myapp/disclaimer.txt');


    my $varDir = $app->varDir;
    $self->is($varDir,'/var/opt/myapp');

    $varDir = $app->varDir('import.log');
    $self->is($varDir,'/var/opt/myapp/import.log');
}

sub test_unitTest_depth2: Test(9) {
    my $self = shift;

    $0 = '/opt/myapp/www/public/index.cgi';

    my $app = Quiq::ApplicationPaths->new(2);
    $self->is(ref($app),'Quiq::ApplicationPaths');

    my $name = $app->name;
    $self->is($name,'myapp');

    my $prefix = $app->prefix;
    $self->is($prefix,'');

    my $homeDir = $app->homeDir;
    $self->is($homeDir,'/opt/myapp');

    $homeDir = $app->homeDir('lib/perl5');
    $self->is($homeDir,'/opt/myapp/lib/perl5');

    my $etcDir = $app->etcDir;
    $self->is($etcDir,'/etc/opt/myapp');

    $etcDir = $app->etcDir('disclaimer.txt');
    $self->is($etcDir,'/etc/opt/myapp/disclaimer.txt');

    my $varDir = $app->varDir;
    $self->is($varDir,'/var/opt/myapp');

    $varDir = $app->varDir('import.log');
    $self->is($varDir,'/var/opt/myapp/import.log');
}

sub test_unitTest_prefix: Test(9) {
    my $self = shift;

    $0 = '/home/user/opt/myapp/bin/prog';

    my $app = Quiq::ApplicationPaths->new;
    $self->is(ref($app),'Quiq::ApplicationPaths');

    my $name = $app->name;
    $self->is($name,'myapp');

    my $prefix = $app->prefix;
    $self->is($prefix,'/home/user');

    my $homeDir = $app->homeDir;
    $self->is($homeDir,'/home/user/opt/myapp');

    $homeDir = $app->homeDir('lib/perl5');
    $self->is($homeDir,'/home/user/opt/myapp/lib/perl5');

    my $etcDir = $app->etcDir;
    $self->is($etcDir,'/home/user/etc/opt/myapp');

    $etcDir = $app->etcDir('disclaimer.txt');
    $self->is($etcDir,'/home/user/etc/opt/myapp/disclaimer.txt');

    my $varDir = $app->varDir;
    $self->is($varDir,'/home/user/var/opt/myapp');

    $varDir = $app->varDir('import.log');
    $self->is($varDir,'/home/user/var/opt/myapp/import.log');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ApplicationPaths::Test->runTests;

# eof
