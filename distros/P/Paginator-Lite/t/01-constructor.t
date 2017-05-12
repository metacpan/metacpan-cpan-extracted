#!perl

use strict;
use warnings;

use Test::More tests => 11;

use Try::Tiny;
use Paginator::Lite;

my $pag;


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => 1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( defined $pag, 'Testing with all arguments' );


try {
    $pag = Paginator::Lite->new({
        curr        => 1,
        frame_size  => 1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing base_url' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        frame_size  => 1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing curr' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing frame_size' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => 1,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing items' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => 1,
        items       => 0,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing page_size' );


try {
    $pag = Paginator::Lite->new;
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for missing all required arguments' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => -1,
        frame_size  => 1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for negative curr' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => -1,
        items       => 0,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for negative frame_size' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => 1,
        items       => -1,
        page_size   => 1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for negative items' );


try {
    $pag = Paginator::Lite->new({
        base_url    => '',
        curr        => 1,
        frame_size  => 1,
        items       => 0,
        page_size   => -1,
    });
}
catch {
    $pag = undef;
};

ok( ! defined $pag, 'Testing for negative page_size' );
