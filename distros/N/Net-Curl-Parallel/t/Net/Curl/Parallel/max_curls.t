use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

subtest 'set_max_curls' => sub {
  my $f = Net::Curl::Parallel->new;
  my $f2 = Net::Curl::Parallel->new;

  is $f->max_curls_in_pool, 50, 'Default is 50';
  is $f->max_curls_in_pool(20), 20, 'Setting returns the set value';
  is $f->max_curls_in_pool, 20, 'And the value is set';
  is $f2->max_curls_in_pool, 20, 'And the value is set for all NCPs';
};

done_testing;
