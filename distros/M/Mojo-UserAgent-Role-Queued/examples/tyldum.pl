#!/usr/bin/env perl
use v5.22;
use DDP;
use Mojo::UserAgent;
use Mojo::URL;

package testbase;
use DDP;
use Mojo::Base -base, -signatures;

has ua => sub { Mojo::UserAgent->new; };
sub new {
  my $self = shift->SUPER::new(@_);
  return $self;
}
sub poll($self) {
  $self->ua->get(
    "https://untrusted-root.badssl.com/" => sub {
      my ($ua, $tx) = @_; 
      p $tx->res->error if $tx->res->error;
    }); 
}

package testbase::insecure;
use Mojo::Base 'testbase';

package testbase::secure;
use Mojo::Base 'testbase';


package main;

my $insecure = testbase::insecure->new(ua => Mojo::UserAgent->new->insecure(1));
my $secure = testbase::secure->new(ua => Mojo::UserAgent->new);


my $insecure_q = testbase::insecure->new(ua => Mojo::UserAgent->new->with_roles('+Queued')->insecure(1));
my $secure_q = testbase::secure->new(ua => Mojo::UserAgent->new->with_roles('+Queued'));

say "There should be two failures below:";

# Works. $insecure works, $secure fails as expected.
$insecure->poll;
$secure->poll;

# Both these succeed, one should fail
$insecure_q->poll;
$secure_q->poll;

Mojo::IOLoop->start;
