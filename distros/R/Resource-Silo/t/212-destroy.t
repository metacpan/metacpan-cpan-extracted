#!/usr/bin/env perl

=head1 DESCRIPTION

Make sure that custom destrurction is executed correctly.

=cut

use strict;
use warnings;
use Test::More;

my $conn_id;
my %active;
{
    package My::App;
    use Resource::Silo -class;
    resource foo =>
        init        => sub {
            my $n = ++$conn_id;
            $active{$n}++;
            return $n;
        },
        cleanup     => sub {
            my $item = shift;
            delete $active{ $item };
        };
}

subtest 'alone' => sub {
    my $res = My::App->new;

    is $res->foo, 1, 'new instance created';
    is_deeply \%active, { 1 => 1 }, "active connection exists";

    undef $res;
    is_deeply \%active, {}, "cleanup worked";
};

my @order;
{
    package My::Res;
    sub new {
        my ($class, $name) = @_;
        return bless \$name, $class;
    };
    sub DESTROY {
        my $self = shift;
        push @order, $$self;
    };
}

{
    package My::Ordered;
    use Resource::Silo -class;

    resource main  =>
        cleanup_order   => -1,
        init            => sub {
            $_[0]->$_
                for (qw(logger dbh huey louie dewey));
            My::Res->new( $_[1] )
        };
    resource huey  =>
        init            => sub { My::Res->new( $_[1] ) };
    resource louie =>
        init            => sub { My::Res->new( $_[1] ) };
    resource dewey =>
        init            => sub { My::Res->new( $_[1] ) };
    resource dbh =>
        cleanup_order   => 1,
        init            => sub { My::Res->new( $_[1] ) };
    resource logger =>
        cleanup_order   => 100,
        init            => sub { My::Res->new( $_[1] ) };
};

subtest "cleanup order" => sub {
    my $app = My::Ordered->new;
    my $unused = $app->main;
    undef $unused;
    is_deeply \@order, [], "Nothing got destroyed yet";
    undef $app;
    is $order[0], 'main', "Main got axed first";
    is $order[-1], 'logger', "Logger stayed till the end";
    is $order[-2], 'dbh', "dbh after others";
    is scalar @order, 6, "3 ducklings finalized somewhere in the middle";
};

done_testing;
