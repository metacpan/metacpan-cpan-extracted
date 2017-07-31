#!perl
use Test::DescribeMe qw(author);
use Test::More tests => 1;
use warnings;
use strict;

# Dist::Zilla::Plugin::Test::Pod::LinkCheck should find all errors,
# but App::PodLinkCheck finds even more errors (which is surprising,
# because die dzil-plugin uses Test::Pod::LinkCheck internally which again
# uses parts of App::PodLinkCheck...)

use App::PodLinkCheck;
use Capture::Tiny 'capture_stdout';

subtest 'check POD for broken links' => sub {

    my $stdout = capture_stdout {
	App::PodLinkCheck->new->check_tree('lib/');
    };
    
    my @lines = split $/, $stdout;
    my @errors = grep { ! /:$/ } @lines;

    diag $_ foreach @errors;
    is( @errors, 0, 'broken links' );
};
