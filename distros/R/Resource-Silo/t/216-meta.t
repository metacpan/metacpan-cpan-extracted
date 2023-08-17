#!/usr/bin/env perl

=head1 DESCRIPTION

Fetching resource metadata from the container.

=cut

use strict;
use warnings;
use Test::More;

{
    package My::Foo;
    use Resource::Silo -class;

    resource one => sub {1};
}
{
    package My::Bar;
    use Resource::Silo -class;

    resource two => sub {2};
}

my $metafoo = My::Foo->new->ctl->meta;

is ref $metafoo, 'Resource::Silo::Metadata', "correct metaclass ref";
is_deeply [$metafoo->list], ['one'], "just one resource";
is_deeply scalar $metafoo->list, ['one'], "ditto in scalar context";

done_testing;
