#!/usr/bin/env perl

=head1 DESCRIPTION

Make sure that normal resource allocation uses cache
but the C<fresh> method ignores it.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $counter = 0;
{
    package My::Resource;
    sub new {
        my ($class, $arg) = @_;
        bless { arg => $arg, id => ++$counter }, $class;
    };
    sub id  { $_[0]->{id} };
    sub arg { $_[0]->{arg}  };
};

use Resource::Silo;
resource noarg   => sub { My::Resource->new };
resource witharg =>
    argument        => sub { 1 },
    init            => sub { My::Resource->new( $_[2] ) };

is silo->noarg->id, 1, 'Cached object w/o argument';
is silo->noarg->id, 1, 'Cached object w/o argument = cached version';

is silo->ctl->fresh("noarg")->id, 2, 'Uncached object w/o argument';
is silo->ctl->fresh("noarg")->id, 3, 'Uncached object w/o argument - new id';

is silo->noarg->id, 1, "Cached object w/o argument didn't change";

done_testing;


