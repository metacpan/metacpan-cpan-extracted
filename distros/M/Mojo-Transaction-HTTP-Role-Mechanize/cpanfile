# -*- mode: perl; -*-
requires 'perl' => '5.10.0';
# requires 'perl' => '5.24.1'; # see issues#2
requires 'Class::Method::Modifiers' => '2.00';
requires 'Mojolicious' => '8.10';
requires 'Role::Tiny' => '2.000001';

test_requires 'Test::More' => '0.80';

on develop => sub {
  requires 'Devel::Cover' => 0;
  requires 'IO::Socket::SSL' => '2.009';
  requires 'Test::Pod' => 0;
  requires 'Test::Pod::Coverage' => 0;
  requires 'Test::CPAN::Changes' => 0;
  requires 'Devel::Cover::Report::Coveralls' => '0.11';
  requires 'Devel::Cover::Report::Kritika' => '0.05';
};

if ($ENV{AUTHOR_RELEASE}) {
  requires 'App::git::ship';
}
