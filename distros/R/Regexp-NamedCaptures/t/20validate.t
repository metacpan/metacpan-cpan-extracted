#!perl
use Test::More tests => 22;

BEGIN {

    # At the time I wrote this code that checks for Params::Validate I'm sure
    # there was a good reason. I don't know anymore why this code exists. :-(
    #
    # It looks like I wanted to prevent Params::Validate from loading.
    $no_validate = sub { die if "@_" =~ /Params.+Validate/ };
    unshift @INC, $no_validate;
}
use Regexp::NamedCaptures;

BEGIN {
    @INC = grep $_ ne $no_validate, @INC;
}

$OPEN_NAME  = '<';
$CLOSE_NAME = '>';
do "t/basic";

$OPEN_NAME  = '\'';
$CLOSE_NAME = '\'';
do "t/basic";
