#!perl

use strict;
use warnings;
use 5.010;

use Test::More tests => 2;
use Perl::Critic::Config;
use Perl::Critic;
use Perl::Critic::Utils qw( :characters );
use Perl::Critic::TestUtils qw(
    pcritique
);

Perl::Critic::TestUtils::block_perlcriticrc();
# Pass in the default regex used to look for commented code. This
# should behave just as though no extra configuration were provided.
DEFAULTPROFILE: {
    my $code = <<'END_PERL';
my $one = 1;
my $two = '# $foo = "bar"';
# my $three = 'three';
# $four is an important variable.
END_PERL

    my $policy = 'Bangs::ProhibitCommentedOutCode';
    my $config = { commentedcoderegex => q(\$[A-Za-z_].*=) };

    is( pcritique( $policy, \$code, $config ), 1, $policy);
}


# To demonstrate that the config file works, change the regex used to
# look for commented code to only look for variables named 'bang'
# Bug submitted by Oystein Torget
CHANGEPROFILE: {
    my $code = <<'END_PERL';
my $one = 1;
my $two = '# $foo = "bar"';
# my $three = 'three';
# my $bang = 'three';
# $four is an important variable.
END_PERL

    my $policy = 'Bangs::ProhibitCommentedOutCode';
    my $config = { commentedcoderegex => q(\$bang.*=) };

    is( pcritique( $policy, \$code, $config ), 1, $policy);
}


exit 0;
