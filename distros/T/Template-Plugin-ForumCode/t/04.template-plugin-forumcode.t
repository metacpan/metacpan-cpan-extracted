#!/usr/bin/perl
use strict;
use warnings;

# load the module that provides all of the common test functionality
use FindBin qw($Bin);
use lib qq{$Bin/testlib};
use ForumCodeTest;

my @forum_tests;

BEGIN {
    # a list of tests for forumcode()
    @forum_tests = ForumCodeTest::markup_tests();

    # test count is a fixed number of tests + the length of the @tests array
    use Test::More;
    plan tests => ( 3 + scalar(@forum_tests) );

    use_ok( 'Template::Plugin::ForumCode' );
};

# create a new thingy
my $tt_forum = Template::Plugin::ForumCode->new();
isnt(undef, $tt_forum, 'Plugin object is defined');
isa_ok($tt_forum, 'Template::Plugin::ForumCode');

# now some formatting tests for forumcode()
foreach my $test (@forum_tests) {
    my $text = $tt_forum->forumcode($test->{in});
    if (defined $test->{diag}) {
        diag("$test->{out} - $test->{diag}");
    }
    is($text, $test->{out}, qq{forumcode('$test->{in}')});
}
