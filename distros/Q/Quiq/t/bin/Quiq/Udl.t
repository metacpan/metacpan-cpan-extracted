#!/usr/bin/env perl

package Quiq::Udl::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Udl');
}

# -----------------------------------------------------------------------------

sub test_new_empty : Test(9) {
    my $self = shift;

    my $obj = Quiq::Udl->new;
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'');
    $self->is($obj->dbms,'');
    $self->is($obj->db,'');
    $self->is($obj->user,'');
    $self->is($obj->password,'');
    $self->is($obj->host,'');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{});
}

sub test_new_string : Test(9) {
    my $self = shift;

    my $udlStr = 'dbi#oracle:xyz%xyz_admin:koala3@pluto.gaga.de;'.
        'file=/tmp/xyz;name=gaga';
    my $obj = Quiq::Udl->new($udlStr);
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'dbi');
    $self->is($obj->dbms,'oracle');
    $self->is($obj->db,'xyz');
    $self->is($obj->user,'xyz_admin');
    $self->is($obj->password,'koala3');
    $self->is($obj->host,'pluto.gaga.de');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{file=>'/tmp/xyz',name=>'gaga'});
}

sub test_new_metachar_in_password : Test(9) {
    my $self = shift;

    my $udlStr = 'dbi#oracle:xyz%xyz_admin:ko\@la3@pluto.gaga.de;'.
        'file=/tmp/xyz;name=gaga';
    my $obj = Quiq::Udl->new($udlStr);
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'dbi');
    $self->is($obj->dbms,'oracle');
    $self->is($obj->db,'xyz');
    $self->is($obj->user,'xyz_admin');
    $self->is($obj->password,'ko@la3');
    $self->is($obj->host,'pluto.gaga.de');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{file=>'/tmp/xyz',name=>'gaga'});
}

sub test_new_string_order : Test(9) {
    my $self = shift;

    # % und @ vertauscht

    my $udlStr = 'dbi#oracle:xyz@pluto.gaga.de%xyz_admin:koala3;'.
        'file=/tmp/xyz;name=gaga';
    my $obj = Quiq::Udl->new($udlStr);
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'dbi');
    $self->is($obj->dbms,'oracle');
    $self->is($obj->db,'xyz');
    $self->is($obj->user,'xyz_admin');
    $self->is($obj->password,'koala3');
    $self->is($obj->host,'pluto.gaga.de');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{file=>'/tmp/xyz',name=>'gaga'});
}

sub test_new_string_backw : Test(9) {
    my $self = shift;

    my $udlStr = 'dbi#xyz_admin:koala3%oracle:xyz@pluto.gaga.de;'.
        'file=/tmp/xyz;name=gaga';
    my $obj = Quiq::Udl->new($udlStr);
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'dbi');
    $self->is($obj->dbms,'oracle');
    $self->is($obj->db,'xyz');
    $self->is($obj->user,'xyz_admin');
    $self->is($obj->password,'koala3');
    $self->is($obj->host,'pluto.gaga.de');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{file=>'/tmp/xyz',name=>'gaga'});
}

sub test_new_keyVal : Test(9) {
    my $self = shift;

    my $obj = Quiq::Udl->new(
        api => 'dbi',
        dbms => 'oracle',
        db => 'xyz',
        user => 'xyz_admin',
        password => 'koala3',
        host => 'pluto.gaga.de',
        options => 'file=/tmp/xyz;name=gaga',
    );
    $self->is(ref($obj),'Quiq::Udl');
    $self->is($obj->api,'dbi');
    $self->is($obj->dbms,'oracle');
    $self->is($obj->db,'xyz');
    $self->is($obj->user,'xyz_admin');
    $self->is($obj->password,'koala3');
    $self->is($obj->host,'pluto.gaga.de');
    $self->is($obj->port,'');
    $self->isDeeply($obj->options,{file=>'/tmp/xyz',name=>'gaga'});
}

# -----------------------------------------------------------------------------

sub test_options : Test(4) {
    my $self = shift;

    my $obj = Quiq::Udl->new;

    my $hash = $obj->options;
    $self->isDeeply($hash,{});

    $hash = $obj->options('a=1;b=2');
    $self->isDeeply($hash,{a=>1,b=>2});

    $hash = $obj->options({c=>3,d=>4});
    $self->isDeeply($hash,{c=>3,d=>4});

    $hash = $obj->options(e=>5,f=>6);
    $self->isDeeply($hash,{e=>5,f=>6});
}

# -----------------------------------------------------------------------------

sub test_apiClass : Test(1) {
    my $self = shift;

    my $obj = Quiq::Udl->new('dbi#oracle:xyz');
    my $val = $obj->apiClass;
    $self->is($val,'Quiq::Database::Api::Dbi::Connection');
}

# -----------------------------------------------------------------------------

sub test_asString_empty : Test(1) {
    my $self = shift;

    my $obj = Quiq::Udl->new;
    my $str = $obj->asString;
    $self->is($str,'');
}

sub test_asString_string : Test(2) {
    my $self = shift;

    my $udlStr1 = 'dbi#oracle:xyz%admin:koala3@pluto.gaga.de;file=/tmp/xyz';
    my $udlStr2 = 'dbi#oracle:xyz%admin:*@pluto.gaga.de;file=/tmp/xyz';

    my $obj = Quiq::Udl->new(
        api => 'dbi',
        dbms => 'oracle',
        db => 'xyz',
        user => 'admin',
        password => 'koala3',
        host => 'pluto.gaga.de',
        options => 'file=/tmp/xyz',
    );

    my $str = $obj->asString;
    $self->is($str,$udlStr1);

    $str = $obj->asString(-secure=>1);
    $self->is($str,$udlStr2);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Udl::Test->runTests;

# eof
