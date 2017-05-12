#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta

our $other_test_dir;

# include Useful Stuff
BEGIN {
    use Test::Aggregate;
    use FindBin qw($Bin);
    # set our aggregate location
    $other_test_dir = 't_aggregate/schematests/';
}

# load the module that provides all of the common test functionality
BEGIN {
    use lib "$Bin/../$other_test_dir";
    use SchemaTest;
}


my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
});
$tests->run;
