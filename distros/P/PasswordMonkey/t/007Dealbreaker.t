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

sub prompt {
    my($self) = @_;

    return qr(wonk:);
}

sub init {
    my($self) = @_;

    $self->dealbreakers([
        ["type here:" => 255 ],
    ]);
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

plan tests => 3;

my $custom = PasswordMonkey::Filler::CustomTest->new(
    password => "supersecrEt",
);

my $monkey = PasswordMonkey->new();
$monkey->expect->log_user( 0 );

$monkey->filler_add( $custom );

$monkey->spawn("$^X $eg_dir/type-here");

my $rc = $monkey->go();

is $rc, 0, "rc no success";

is $monkey->is_success, 0, "no success";
is(($monkey->exit_status >> 8), 255, "exit status 255");
