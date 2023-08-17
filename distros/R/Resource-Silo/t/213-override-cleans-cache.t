#!/usr/bin/env perl

=head1 DESCRIPTION

Make sure that overriding a resource resets correcponding cache entry.

=cut

use strict;
use warnings;
use Test::More;

my %connect;

{
    package My::Conn;
    my $seq;
    sub new {
        my ($class, $arg) = @_;
        my $id = ++$seq;
        $connect{$id} = $arg;
        return bless { id => $id, arg => $arg }, $class;
    };
    sub result { my $self = shift; "$self->{id}-$self->{arg}" };
    sub DESTROY {
        my $self = shift;
        delete $connect{$self->{id}};
    };
};

use Resource::Silo;

resource foo =>
    argument    => qr/\d+/,
    init        => sub {
        My::Conn->new($_[2]);
    };

is silo->foo(42)->result, "1-42", "connection established";
is silo->foo(42)->result, "1-42", "connection cached";
is silo->foo(137)->result, "2-137", "different connection";
is_deeply \%connect, { 1 => 42, 2 => 137 }, "side effects recorded";

silo->ctl->override( foo => undef );
is_deeply \%connect, {}, "side effects removed";

is silo->foo(42)->result, "3-42", "new connection established";

done_testing;
