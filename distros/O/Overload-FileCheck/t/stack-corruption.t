#!/usr/bin/perl

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q/:all/;

my $CURRENT_FH = 0;
my @STAT_CALLED_WITH;
my $IS_MOCKED;
my $TOTAL_CALL = 0;

sub mystat {
    my ( $stat_or_lstat, $f ) = @_;

    note "call MYSTAT '", $stat_or_lstat, "' for file: ", $f, " def ? ", defined $f ? "defined" : "undef";
    push @STAT_CALLED_WITH, "$f";    # stringify
    ++$TOTAL_CALL;

    # if this our CURRENT_FH call return a file with a size
    return stat_as_file( size => 1234 ) if $f eq $CURRENT_FH;

    # otherwise return a null file
    return stat_as_file( size => 0 );
}

sub test {
    my @array;

    my $x = boom($0);
    push @array, $x;

    push @array, boom($0);    # Bizarre copy of ARRAY in list assignment
    push @array, boom($0);

    return \@array;
}

note "Test unmocked";

is test(), [ $0, $0, $0 ], "check - unmocked";

note "Mocking all FileCheck using mock_all_from_stat";
$IS_MOCKED = 1;
ok mock_all_from_stat( \&mystat ), "mocking stat";

my $a = test();
is scalar @$a, 3, "3 elements in array";
is $a, [ $0, $0, $0 ], "check - mocked - array with two elements as expected";

is $TOTAL_CALL, 3, "mystat was called 3 times";

done_testing;

sub boom {
    my ($path) = @_;

    open my $fh, '<', $path;

    $CURRENT_FH       = "$fh";    # stringify
    @STAT_CALLED_WITH = ();

    note "... -f fh && -s _", $fh;

    my $not_null = -f $fh && -s _;

    if ($IS_MOCKED) {
        is scalar @STAT_CALLED_WITH, 1, "only perform a single stat call";
        is \@STAT_CALLED_WITH, [$CURRENT_FH], "stat was called with our current GLOB";
    }

    return $not_null ? $path : undef;
}

__END__
