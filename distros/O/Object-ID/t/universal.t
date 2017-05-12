#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

{
    package My::Class;

    sub new {
        my $class = shift;
        bless {}, $class;
    }
}

use UNIVERSAL::Object::ID;

# Is it universal?
{
    my $obj = new_ok "My::Class";
    ok $obj->object_id;
}

# What about a totally unrelated module?
{
    use DirHandle;
    my $dh = DirHandle->new(".");
    ok $dh->object_id;

    my $dh2 = DirHandle->new(".");
    ok $dh2->object_id;

    isnt $dh->object_id, $dh2->object_id;
}

# A regex object?
{
    my $re = qr/foo/;
    ok $re->object_id;

    my $re2 = qr/foo/;
    isnt $re->object_id, $re2->object_id;
}


done_testing;
