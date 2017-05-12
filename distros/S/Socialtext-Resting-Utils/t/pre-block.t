#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 4;
use lib 'lib';

BEGIN {
    use_ok 'Socialtext::WikiObject::PreBlock';
    use_ok 'Socialtext::Resting::Mock';
}

my $rester = Socialtext::Resting::Mock->new;

sub new_wikiobject {
    Socialtext::WikiObject::PreBlock->new( rester => $rester, @_ );
}

Simple_pre_block: {
    $rester->put_page('Foo', ".pre\nMonkey\n.pre\n");

    my $wo = new_wikiobject(page => 'Foo');
    is $wo->pre_block, "Monkey\n";
}

Pre_block_with_surrownding_content: {
    $rester->put_page('Foo', <<EOT);
Here is my pre block with special data:

.pre
Monkey
.pre

That's it!
EOT

    my $wo = new_wikiobject(page => 'Foo');
    is $wo->pre_block, "Monkey\n";
}
