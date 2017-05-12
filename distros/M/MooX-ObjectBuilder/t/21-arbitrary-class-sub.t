#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Test C<< make_builder($coderef, %args) >>.

=head1 AUTHOR

Torbjørn Lindahl.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Torbjørn Lindahl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use t::lib::TestUtils;

my $stdout = undef;
my $org = 'Organization'->new(
    name       => 'Catholic Church',
    boss_name  => 'Francis',
    boss_title => 'Pope',
    boss_class => sub { $stdout = 'Hi there!'; return },
    hq_name    => 'Rome',
);

isa_ok( $org, 'Organization' );
$org->boss;
is($stdout, 'Hi there!', 'class code executed');
ok( ! defined($org->boss), 'boss not built' );

done_testing;