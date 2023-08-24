#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure circular dependencies don't go wild

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::Project;
    use Resource::Silo -class;

    resource foo => sub { $_[0]->bar };
    resource bar => sub { $_[0]->foo };
}

subtest 'throws like it should' => sub {
    my $file = quotemeta __FILE__;
    my $line;

    throws_ok {
        # force fatal warnings
        local $SIG{__WARN__} = sub { die $_[0] };
        my $inst = My::Project->new;
        $line = __LINE__; $inst->foo;
    } qr/[Cc]ircular dependency/, 'circularity detected';

    like $@, qr($file line $line), 'error attributed correctly';

    note $@;
};

subtest 'ok if resource is substituted' => sub {
    lives_and {
        # force fatal warnings
        local $SIG{__WARN__} = sub { die $_[0] };
        my $inst = My::Project->new( bar => 42 );
        is $inst->foo, 42, 'foo deduced from bar';
    };
};


done_testing;
