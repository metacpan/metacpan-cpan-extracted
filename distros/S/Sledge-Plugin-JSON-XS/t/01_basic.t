use strict;
use warnings;
use Test::More tests => 12;
use Encode;

# -------------------------------------------------------------------------
# test util codes.

package MockRequest;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/param content_type print/);
our $REQ_HASH = {};
sub param { $REQ_HASH->{$_[1]} }

our $HEADER = {};
sub header_in { $HEADER->{$_[1]} }

package Your::Pages;
use base qw/Class::Accessor/;
use Sledge::Plugin::JSON::XS;
our $SRC = {foo => 'bar'};
our $DEBUG_LEVEL;

__PACKAGE__->mk_accessors(qw/r set_content_length send_http_header finished/);

sub new { bless {r => bless({}, 'MockRequest')}, shift }
sub invoke_hook { }
sub debug_level { $DEBUG_LEVEL }

sub dispatch_index {
    my $self = shift;

    $self->output_json_xs($SRC);
}

package main;

our $page;
our $name;
sub test($&&) {
    $name = shift;
    my ($setup, $test) = @_;

    my $encoding = $Sledge::Plugin::JSON::XS::ENCODING;
    local $Sledge::Plugin::JSON::XS::ENCODING = $encoding;
    my $tmp = $Sledge::Plugin::JSON::XS::ConformToRFC4627;
    local $Sledge::Plugin::JSON::XS::ConformToRFC4627 = $tmp;

    local $REQ_HASH = {};
    local $HEADER = {};
    local $DEBUG_LEVEL = 0;

    $setup->();

    local $page = Your::Pages->new;
    $page->dispatch_index;

    $test->($page);
}

sub is_ex($$) {
    is $_[0], $_[1], $name;
}

# -------------------------------------------------------------------------
# test cases.

test(
    'basic',
    sub { },
    sub {
        is_ex $page->{finished}, 1;
        is_ex $page->r->{'print'}, '{"foo":"bar"}';
        is_ex $page->r->{'content_type'}, 'application/javascript; charset=utf-8';
    }
);

test(
    'debug server',
    sub {
        $DEBUG_LEVEL = 1;
    },
    sub {
        is_ex $page->r->{'content_type'}, 'application/javascript; charset=utf-8';
    }
);

test(
    'debug mode',
    sub {
        $REQ_HASH = { debug => 1 };
        $DEBUG_LEVEL = 1;
    },
    sub {
        is_ex $page->r->{'content_type'}, 'text/plain; charset=utf-8';
    }
);

test(
    'opera',
    sub {
        $HEADER = { 'User-Agent' => 'Opera/7.0 (Windows XP; U) [en]'};
    },
    sub {
        is_ex $page->r->{'content_type'}, 'application/x-javascript; charset=utf-8';
    }
);

test(
    'ConformToRFC4627', sub {
        $Sledge::Plugin::JSON::XS::ConformToRFC4627 = 1;
    },
    sub {
        is_ex $page->r->{'content_type'}, 'application/json; charset=utf-8';
    }
);

test(
    'change encoding',
    sub {
        $Sledge::Plugin::JSON::XS::ENCODING = 'euc-jp';
    },
    sub {
        is_ex $page->r->{'content_type'}, 'application/javascript; charset=euc-jp';
    }
);

test(
    'callback',
    sub {
        $REQ_HASH = { callback => 'hoge' };
    },
    sub {
        is_ex $page->r->{'print'}, 'hoge({"foo":"bar"});';
    },
);

test(
    'callback violation',
    sub {
        $REQ_HASH = { callback => '@@@!"""' };
    },
    sub {
        is_ex $page->r->{'print'}, '{"foo":"bar"}';
    },
);

test(
    'callback_flagged_utf8',
    sub {
        $REQ_HASH = { callback => decode_utf8('hoge') };
    },
    sub {
        is_ex $page->r->{'print'}, 'hoge({"foo":"bar"});';
        ok( (!Encode::is_utf8($page->r->{'print'})), 'not flagged');
    },
);

