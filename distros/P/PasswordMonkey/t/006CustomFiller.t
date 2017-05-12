######################################################################
# Test suite for PasswordMonkey
######################################################################
use warnings;
use strict;

use PasswordMonkey;

###########################################
package PasswordMonkey::Filler::CustomTest;
###########################################
use base qw(PasswordMonkey::Filler);

our $pre_fill_run  = 0;
our $post_fill_run = 0;

sub prompt {
    my($self) = @_;

    return qr(type here:);
}

sub pre_fill {
    my($self) = @_;

    $pre_fill_run++;
}

sub post_fill {
    my($self) = @_;

    $post_fill_run++;
}

###########################################
package main;
###########################################

use Test::More;
use PasswordMonkey;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

  # debug on
# $Expect::Exp_Internal = 1;

my $eg_dir = "$Bin/eg";

plan tests => 5;

my $custom = PasswordMonkey::Filler::CustomTest->new(
    password => "supersecrEt",
);

my $monkey = PasswordMonkey->new();
$monkey->expect->log_user( 0 );

$monkey->filler_add( $custom );

$monkey->spawn("$^X $eg_dir/type-here");

my $rc = $monkey->go();

is $rc, 1, "rc success";

is $monkey->is_success, 1, "success";
is $monkey->exit_status, 0, "exit status 0";
is $PasswordMonkey::Filler::CustomTest::pre_fill_run, 1, "prefill run";
is $PasswordMonkey::Filler::CustomTest::post_fill_run, 1, "postfill run";
