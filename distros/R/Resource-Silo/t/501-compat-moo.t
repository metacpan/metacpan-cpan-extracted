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

my $conn = 0;
{
    package My::Mixed;
    use Resource::Silo -class;
    use Moo;

    resource foo => sub {
        [++$conn];
    };
    has bar => is => 'lazy', default => sub { $_[0]->foo->[0] };
};

my $mixed = My::Mixed->new;

is $mixed->bar, 1, "both initialisations worked";
is $conn, 1, "Counter increased accrodingly";

# TODO
# my $witharg = My::Mixed->new( bar => 42 );
# this would die but it shouldn't

done_testing;
