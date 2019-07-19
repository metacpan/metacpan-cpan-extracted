#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More;# tests => 27;

use PFT::Tree;
use PFT::Content;
use PFT::Header;
use PFT::Map;

use File::Spec;
use File::Temp;

use Encode::Locale;
use Encode;

my $root = File::Temp->newdir;
my $tree = PFT::Tree->new($root, {create=>1})->content;

# --- Populating  ------------------------------------------------------

sub enter {
    my $f = $tree->new_entry(shift)->open('a');
    print $f @_;
    close $f;
};

enter(
    PFT::Header->new(title => 'A page!'),
    <<'    EOF' =~ s/^    //rgms
    This is a page, referring [the blog page](:blog:back) will fail.
    I can however refer to [this page](:page:a-page).

    There's one picture:
    ![test](:pic:foo/bar.png)

    Here's an [attachment](:attach:badhorse/evil.mov)
    EOF
);

$tree->pic('foo', 'bar.png')->open('a');
$tree->attachment('badhorse', 'evil.mov')->open('a');

enter(
    PFT::Header->new(
        title => 'Hello 1',
        date => PFT::Date->new(2014, 1, 3),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is an entry where I refer to [some page][1]

    [1]: :page:a-page
    EOF
);
enter(
    PFT::Header->new(
        title => 'Hello 2',
        date => PFT::Date->new(2014, 1, 4),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is another entry where I refer to [previous one][1]

    All these entries are tagged with [the infamous tag1][t1]!

    [1]: :blog:back
    [t1]: :tag:tag1
    EOF
);
enter(
    PFT::Header->new(
        title => 'Hello 3',
        date => PFT::Date->new(2014, 1, 5),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is another entry where I refer to [previous one][1]
    And to the [first](:blog:back/2)

    [1]: :blog:back
    EOF
);
enter(
    PFT::Header->new(title => 'Another page'),
    <<'    EOF' =~ s/^    //rgms
    This is another page, referencing [the post of 2014/1/5][1]

    [1]: :blog:d/2014/1/5
    EOF
);

# -- Simulating multiple entries per day ---------------------------------

enter(
    PFT::Header->new(
        title => 'Hello 4',
        date => PFT::Date->new(2014, 1, 6),
    ),
    <<'    EOF' =~ s/^    //rgms
    The first entry of 2014/1/6
    EOF
);
enter(
    PFT::Header->new(
        title => 'Hello 5',
        date => PFT::Date->new(2014, 1, 6),
    ),
    <<'    EOF' =~ s/^    //rgms
    The the second entry of 2014/1/6. Links to this day *must* specify
    also the title, or will get an ambiguous selection of entry.
    EOF
);
enter(
    PFT::Header->new(
        title => 'A page testing multi-entry days',
        slug => 'multi-test',
    ),
    <<'    EOF' =~ s/^    //rgms
    The entry (which one?) of day [2014/1/6](:blog:d/2014/1/6)
    This should give me a error, as there's no such name: [here](:blog:d/2014/1/6/hello-9000)
    EOF
);

# --/ Populating  ------------------------------------------------------

my $map = PFT::Map->new($tree);

ok_corresponds('p:a-page',
    'p:a-page',
    'i:foo/bar.png',
    'a:badhorse/evil.mov',
);
ok_broken('p:a-page', qr/blog/ => ['back']);

ok_corresponds('b:2014-01-03:hello-1',
    'p:a-page',
);

ok_corresponds('b:2014-01-04:hello-2',
    'b:2014-01-03:hello-1',
    't:tag1',
);

ok_corresponds('b:2014-01-05:hello-3',
    'b:2014-01-04:hello-2',
    'b:2014-01-03:hello-1',
);

ok_corresponds('p:another-page',
    'b:2014-01-05:hello-3',
);

ok_corresponds('p:multi-test');
ok_broken('p:multi-test',
    qr/blog/ => ['d', 2014, 1, 6],
    qr/blog/ => ['d', 2014, 1, 6, 'hello-9000'],
);

sub ok_broken {
    # NOTE: because of side-effects of symbol resolutions, calling
    # ok_broken works onli if you called ok_corresponds first.

    my $nodeid = shift;
    my @unres = $map->id_to_node($nodeid)->symbols_unres;

    is(scalar(@unres), (@_ / 2),
        'Expected '.(@_/2)." unresolved for $nodeid, got ".scalar(@unres)
    );
    # Beware: if something is broken, the second element of each @unres is
    # going to be the error message!
    diag('Listing them all:');
    diag(' - ', join(' ', grep defined, @$_)) for @unres;

    foreach (@unres) {
        my($sym, $err) = @{$_};
        my $exp_kw = shift @_;
        my $exp_args = shift @_;

        ok($sym->keyword =~ $exp_kw, "Symbol $sym =~ $exp_kw");
        is_deeply([$sym->args], $exp_args,
            '  with args: [' . join(' ', $sym->args). "] is [@$exp_args]"
        )
    }
}

sub ok_corresponds {
    my $nodeid = shift;
    my @refs;

    my $node = $map->id_to_node($nodeid);

    # Returned html will contain "bogus href" as link to each node.
    $node->html(sub { push @refs, $_->id; "bogus href" });

    is_deeply(\@refs, \@_, 'Resolver for ' . $nodeid)
}

done_testing();
