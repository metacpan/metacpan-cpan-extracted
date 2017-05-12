package Tests::MooseX::Role::Net::OpenSSH::Base;
use strict;
use warnings;

#use Test::Class::Most attributes => [qw/ /];
use Test::Class::Most;
use Data::Dumper;

sub startup : Tests(startup) {
}

sub setup : Tests(setup) {
}

sub teardown : Tests(teardown) {
}

sub shutdown : Tests(shutdown) {
}

1;
