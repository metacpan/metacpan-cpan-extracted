#!/usr/bin/env perl

=head1 DESCRIPTION

Check interoperability with Moo

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'No Moo found'
        unless eval { require Moo };
};

my %conn;
my $id;
{
    package My::Mixed;
    use Resource::Silo -class;
    use Moo;

    has prefix => is => 'ro', default => sub { 'foo' };
    resource conn =>
        init => sub {
            my $key = join "_", $_[0]->prefix, ++$id;
            $conn{$key}++;
            return $key;
        },
        cleanup => sub {
            my $key = shift;
            delete $conn{$key};
        };
    resource over => sub { };
};

subtest 'no parameters' => sub {
    my $mixed = My::Mixed->new;

    is $mixed->conn, 'foo_1', "both initializers worked";
    is_deeply \%conn, { foo_1 => 1 }, "Counter increased accrodingly";

    undef $mixed;
    is_deeply \%conn, {}, "Cleanup worked";
};

subtest 'with parameter' => sub {
    my $mixed = My::Mixed->new( prefix => 'bar', over => 42 );

    is $mixed->conn, 'bar_2', "both initializers worked";
    is $mixed->over, 42, "normal override worked, too";
    is_deeply \%conn, { bar_2 => 1 }, "Counter increased accrodingly";

    undef $mixed;
    is_deeply \%conn, {}, "Cleanup worked";
};

done_testing;
