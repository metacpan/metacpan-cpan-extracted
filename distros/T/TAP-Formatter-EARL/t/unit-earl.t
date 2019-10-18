
=encoding utf-8

=head1 PURPOSE

Simple unit test for TAP::Formatter::EARL

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;
use Test::Modern;
use Test::More;
use Test::Output;

use_ok("TAP::Formatter::EARL");

my $t = object_ok(
						sub { TAP::Formatter::EARL->new() }, '$t',
						isa => [qw(TAP::Formatter::Console)],
						can => [qw(model ns graph_name base _test_time software_prefix result_prefix assertion_prefix open_test summary)]);

my $s = $t->open_test('foobar.t');

isa_ok($s, 'TAP::Formatter::EARL::Session');


stdout_like(sub {$t->summary}, qr/doap:name \"foobar\.t\"/, "contains correct script name");

done_testing;
