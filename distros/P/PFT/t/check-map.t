#!/usr/bin/perl -w

use v5.16;
use utf8;

use strict;
use warnings;
use utf8;

use Test::More tests => 21;

use PFT::Content;
use PFT::Header;
use PFT::Map;

use File::Spec;
use File::Temp;

use Encode::Locale;
use Encode;

my $root = File::Temp->newdir();
my $tree = PFT::Content->new($root);

# Populating

$tree->pic('baz', 'foo_bar.png')->touch;
$tree->attachment('foo', 'bar.txt')->touch;
do {
    my $page = $tree->new_entry(PFT::Header->new(title => 'A page!'));
    my $f = $page->open('a+');
    binmode $f, 'utf8';
    print $f <<'    EOF' =~ s/^    //rgms;
    Hello.

    This is a picture of me:

    ![my ugly face](:pic:baz/foo_bar.png)
    ![my ugly cat](:pic:baz/bar_foo.png)

    Follows my horrible poetry: [click here][1]

    [1]: :attach:foo/bar.txt
    EOF
    close $f;
};
$tree->new_entry(PFT::Header->new(
    title => 'Another page?',
    tags => ['foo', 'bar'],
));
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.3',
    date => PFT::Date->new(2014, 1, 3),
    tags => ['bar'],
));
for (1 .. 2) {
    $tree->new_entry(PFT::Header->new(
        title => 'Blog post nr.'.$_,
        date => PFT::Date->new(2014, $_, $_ * $_),
    ));
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.($_ + 10),
        date => PFT::Date->new(2014, $_, $_ * $_ + 1),
        tags => ['foo'],
    ));
}
$tree->new_entry(PFT::Header->new(title => 'Month nr.2',
    date => PFT::Date->new(2014, 2),
));
$tree->new_entry(PFT::Header->new(title => 'Month nr.3',
    date => PFT::Date->new(2014, 3),
    tags => ['bar'],
));
$tree->new_tag(PFT::Header->new(title => 'Bar'));

my $map = PFT::Map->new($tree);
my @all_unres;
my @ids;
foreach ($map->nodes) {
    push @ids, $_->id;
    push @all_unres, $_->symbols_unres
}

is_deeply([sort @ids], [qw<
    a:foo/bar.txt
    b:2014-01-01:blog-post-nr-1
    b:2014-01-02:blog-post-nr-11
    b:2014-01-03:blog-post-nr-3
    b:2014-02-04:blog-post-nr-2
    b:2014-02-05:blog-post-nr-12
    i:baz/foo_bar.png
    m:2014-01-*
    m:2014-02-*
    p:a-page
    p:another-page
    t:bar
    t:foo
    >],
    "All content is present"
);

diag('Listing missing symbols:');
is_deeply([
        map {
            my $s = $_->[0];
            diag('    missing ', $s->keyword, ', reason ', $_->[1]);
            join '|', $s->keyword, $s->args
        } @all_unres
    ], ["pic|baz|bar_foo.png"],
    "Missing symbols differ"
);

my @dumped = $map->dump;

#use Data::Dumper;
#diag(Dumper \@dumped);

while (my($i, $node) = each @dumped) {
    exists $node->{'>'} and ok(($dumped[$node->{'>'}]->{'<'} == $i),
        'Next refers Prev for ' . $i
    );
    exists $node->{'<'} and ok(($dumped[$node->{'<'}]->{'>'} == $i),
        'Prev refers Next for ' . $i
    );
    if (defined(my $down = $node->{'v'})) {
        is(scalar(@$down), scalar(map{ $dumped[$_]->{'^'} == $i } @$down),
            'Down refers up for ' . $i
        );
    }
    if (defined(my $up = $node->{'^'})) {
        is(scalar(grep{ $_ == $i } @{$dumped[$up]->{'v'}}), 1,
            'Down refers up for ' . $i
        );
    }
    if (defined(my $down = $node->{'.'})) {
        is(scalar(@{$down}), scalar(grep {
                # The list of tags of the page indexed by $_ contains our
                # id exactly once.
                1 == grep { $_ == $i } @{$dumped[$_]->{t}}
            } @{$down}),
            'Taggee refers to tag ' . $i
        );
    }
}

done_testing();
