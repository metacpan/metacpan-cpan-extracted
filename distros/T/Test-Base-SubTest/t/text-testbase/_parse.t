use Project::Libs;
use t::Utils;
use Test::More;

use Text::TestBase::SubTest;

subtest indent => sub {
    {
        my $hunk = <<'...';
### foo
### bar
### baz
...
        my $root = Text::TestBase::SubTest->new->parse($hunk);

        is $root->child_subtests(0)->name, 'foo';
        is $root->child_subtests(1)->name, 'bar';
        is $root->child_subtests(2)->name, 'baz';
    }
    {
        my $hunk = <<'...';
### foo
    ### bar
        ### baz
    ### foobar
...
        my $root = Text::TestBase::SubTest->new()->parse($hunk);

        is $root->child_subtests(0)->name, 'foo';
        ok $root->child_subtests(0)->child_subtests(0)->is_subtest;
        is $root->child_subtests(0)->child_subtests(0)->name, 'bar';
        is $root->child_subtests(0)->child_subtests(0)->child_subtests(0)->name, 'baz';
        ok $root->child_subtests(0)->child_subtests(1)->is_subtest;
        is $root->child_subtests(0)->child_subtests(1)->name, 'foobar';
    }
};

subtest 'subtest + block'   => sub {
        my $hunk = <<'...';
### foo
    === hogehoge
    --- input
    xxx
    --- expected
    yyy

    === fugafuga
    --- input
    xxx
    --- expected
    yyy

### bar
    ### baz
        === hogehoge
        --- input
        xxx
        --- expected
        yyy

    ### foobar
        === fugafuga
        --- input
        xxx
        --- expected
        yyy
...
        my $root = Text::TestBase::SubTest->new()->parse($hunk);

        is $root->child_subtests(0)->name, 'foo';
        is $root->child_subtests(0)->child_blocks(0)->name, 'hogehoge';
        is $root->child_subtests(0)->child_blocks(1)->name, 'fugafuga';
        is $root->child_subtests(1)->name, 'bar';
        is $root->child_subtests(1)->child_subtests(0)->name, 'baz';
        is $root->child_subtests(1)->child_subtests(0)->child_blocks(0)->name, 'hogehoge';
        is $root->child_subtests(1)->child_subtests(1)->name, 'foobar';
        is $root->child_subtests(1)->child_subtests(1)->child_blocks(0)->name, 'fugafuga';
};

done_testing;
