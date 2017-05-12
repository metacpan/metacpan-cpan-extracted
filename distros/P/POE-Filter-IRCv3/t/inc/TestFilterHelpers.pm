package TestFilterHelpers;
use strict; use warnings FATAL => 'all';

require Carp;
require Scalar::Util;

=pod

=head1 NAME

TestFilterHelpers - POE::Filter::IRC(d,v3) test helpers

=head1 SYNOPSIS

  use Test::More;
  use lib 't/inc';
  use TestFilterHelpers;

  my $line = ':test foo';
  get_ok $filter, $line =>
    +{
        raw_line => $line,
        command  => 'FOO',
        prefix   => 'test',
    },
    'my get test ok' ;

  put_ok $filter, $line =>
    +{ command => 'foo', prefix => 'test' },
    'my put test ok' ;

  get_command_ok $filter, $line => $cmd, $name;

  get_prefix_ok $filter, $line => $prefix, $name;

  get_params_ok $filter, $line => [@params], $name;

  get_rawline_ok $filter, $line, $name;

  get_tags_ok $filter, $line => +{%tags}, $name;

  done_testing;

=head1 DESCRIPTION

A simple set of L<Test::Deep> and L<Test::Builder> based helpers for testing
L<POE::Filter::IRCv3> (and L<POE::Filter::IRCD>).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut


use Test::Deep::NoTest qw/
  cmp_deeply

  cmp_details
  deep_diag
/;

use base 'Exporter';
our @EXPORT = qw/
  get_ok
  put_ok

  get_command_ok
  get_prefix_ok
  get_params_ok
  get_rawline_ok
  get_tags_ok
/;

my $Test = Test::Builder->new;
sub import {
  my $self = shift;
  if (@_) {
    my $pkg = caller;
    $Test->exported_to( $pkg );
    $Test->plan( @_ );
  }
  $self->export_to_level( 1, $self, $_ ) for @EXPORT;
}


sub _looks_ok {
  my ($got, $expected, $name) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ($ok, $stack) = cmp_details($got, $expected);

  unless ( $Test->ok($ok, $name) && return 1 ) {
    if (ref $got && ref $expected) {
      $Test->diag( "Structures:\n",
        "Expected ->\n",
        $Test->explain($expected),
        "Got ->\n",
        $Test->explain($got),
      )
    }

    $Test->diag( deep_diag($stack) )
  }

  return
}


sub put_ok {
  my ($filter, $line, $ref, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "put_ok expected blessed filter obj"
  }

  unless (defined $line && !ref($line) && ref $ref eq 'HASH') {
    Carp::croak "put_ok expected a line to compare and a HASH to process"
  }

  my $arr = $filter->put([ $ref ]);
  Carp::croak "filter did not return ARRAY for $ref"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return line for $ref"
    unless defined $arr->[0];

  $name = 'line looks ok' unless defined $name;

  _looks_ok( $arr, [ $line ], $name ) ? 
    $arr->[0] : ()
}


sub get_ok {
  my ($filter, $line, $ref, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_ok expected blessed filter obj"
  }

  unless (defined $line && ref $ref eq 'HASH') {
    Carp::croak "get_ok expected a line to process and HASH to compare"      
  }

  $ref->{raw_line} = $line unless exists $ref->{raw_line};

  my $arr = $filter->get([ $line ]);

  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';

  $name = 'struct looks ok' unless defined $name;
  _looks_ok( $arr, [$ref], $name ) ? 
    $arr->[0] : ()
}


sub get_command_ok {
  my ($filter, $line, $cmd, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_command_ok expected blessed filter obj"
  }

  unless (defined $line && defined $cmd) {
    Carp::croak "get_command_ok expected a line to process and command to compare"
  }

  my $arr = $filter->get([ $line ]);

  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return event for $line"
    unless ref $arr->[0] eq 'HASH';

  $name = 'command looks ok' unless defined $name;
  _looks_ok( $arr->[0]->{command}, $cmd, $name ) ? 
    $cmd : ()
}

sub get_prefix_ok {
  my ($filter, $line, $pfx, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_prefix_ok expected blessed filter obj"
  }

  # undef prefix is a valid comparison:
  unless (defined $line) {
    Carp::croak "get_prefix_ok expected a line to process and prefix to compare"
  }

  my $arr = $filter->get([ $line ]);
  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return event for $line"
    unless ref $arr->[0] eq 'HASH';

  $name = 'prefix looks ok' unless defined $name;
  _looks_ok( $arr->[0]->{prefix}, $pfx, $name ) ? 
    $pfx : ()
}

sub get_params_ok {
  my ($filter, $line, $pref, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_params_ok expected blessed filter obj"
  }

  # pref => undef is legit
  unless (defined $line) {
    Carp::croak "get_params_ok expected a line to process and params to compare"
  }

  my $arr = $filter->get([ $line ]);
  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return event for $line"
    unless ref $arr->[0] eq 'HASH';

  $name = 'params look ok' unless defined $name;
  _looks_ok( $arr->[0]->{params}, $pref, $name ) ? 
    $arr->[0]->{params} : ()
}

sub get_rawline_ok {
  my ($filter, $line, $name) = @_;
  
  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_rawline_ok expected blessed filter obj"
  }

  unless (defined $line) {
    Carp::croak "get_rawline_ok expected a line to process"
  }

  my $arr = $filter->get([ $line ]);
  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return event for $line"
    unless ref $arr->[0] eq 'HASH';

  $name = 'raw_line looks ok' unless defined $name;
  _looks_ok( $arr->[0]->{raw_line}, $line, $name ) ? 
    $line : ()
}

sub get_tags_ok {
  my ($filter, $line, $tags, $name) = @_;

  unless (Scalar::Util::blessed $filter) {
    Carp::croak "get_tags_ok expected blessed filter obj"
  }

  unless (defined $line) {
    Carp::croak "get_tags_ok expected a line to process and a tags HASH to compare"
  }

  my $arr = $filter->get([ $line ]);
  Carp::croak "filter did not return ARRAY for $line"
    unless ref $arr eq 'ARRAY';
  Carp::croak "filter did not return event for $line"
    unless ref $arr->[0] eq 'HASH';

  $name = 'tags look ok' unless defined $name;
  _looks_ok( $arr->[0]->{tags}, $tags, $name ) ?
    $arr->[0]->{tags} : ()
}


1;
