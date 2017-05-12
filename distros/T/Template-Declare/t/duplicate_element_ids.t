
use warnings;
use strict;

package Template::FarAway;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template with_no_dup_id => sub {
    with( id => 'id' ), div {
        p {'This is my content'}
    }
};

template with_with_two_blocks => sub {
    with( id => 'id' ), div {
        p {'This is my content'}
    }
    div {
        p {'another paragraph'}
    }
};

template with_dup_id => sub {
    with( id => 'foo' ), p {'This is my content'};
    with( id => 'id' ),  p {'another paragraph'};
    show('with_with_two_blocks');
    with( id => 'foo' ), p {'This is also my content'};
};

template with_dup_id_in_uppercase => sub {
    with( ID => 'id' ), p {'another paragraph'};
    show('with_with_two_blocks');
};

template with_dup_id2 => sub {
    show('with_with_two_blocks');
    show('with_with_two_blocks');
};

1;

package main;
use Test::More tests => 8;
use Test::Warn;

Template::Declare->init(dispatch_to => ['Template::FarAway']);



{
    warnings_like { Template::Declare->show('with_dup_id') }
    [ qr/duplicate\b/i, qr/duplicate\b/i ], "Duplicate id should be warned";
    Template::Declare->buffer->clear;
}

{
    warnings_like { Template::Declare->show('with_dup_id2') }
    [ qr/duplicate\b/i ], "Duplicate id should be warned";
    Template::Declare->buffer->clear;
}

{
    warning_like { Template::Declare->show('with_dup_id_in_uppercase') }
    qr/duplicate\b/i, "Duplicate id given in different case should be warned";

    Template::Declare->buffer->clear;
}

{
    warning_is { Template::Declare->show('with_no_dup_id') } "",
        "Should not duplicate id warnings if there are none.";
    Template::Declare->buffer->clear;
}

use Template::Declare::Tags;

{
    warnings_like { show('with_dup_id') }
    [ qr/duplicate\b/i, qr/duplicate\b/i ], "Duplicate id should be warned";
    Template::Declare->buffer->clear;
}

{
    warnings_like { show('with_dup_id2') }
    [ qr/duplicate\b/i ], "Duplicate id should be warned";
    Template::Declare->buffer->clear;
}

{
    warning_like { show('with_dup_id_in_uppercase') }
    qr/duplicate\b/i, "Duplicate id given in different case should be warned";

    Template::Declare->buffer->clear;
}

{
    warning_is { show('with_no_dup_id') } "",
        "Should not duplicate id warnings if there are none.";
    Template::Declare->buffer->clear;
}

