#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use lib './lib';
use Riak::Light;
use Data::Dumper;
my $c =
  Riak::Light->new( host => "localhost", port => 8087,
    timeout_provider => undef );

use Benchmark qw(cmpthese);

cmpthese(
    1000000,
    {   foo => sub { print Dumper \@_; }, bar => sub { }
    }
);

print Dumper( $c->exists( foo => "foo" ) );
print Dumper( $c->get_raw( foo => "foo" ) );
print Dumper( $c->exists( foo => "bar" ) );
print Dumper( $c->get_raw( foo => "bar" ) );
