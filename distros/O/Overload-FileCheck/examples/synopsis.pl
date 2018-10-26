#!perl

use strict;
use warnings;

use strict;
use warnings;

use Test::More;
use Overload::FileCheck q{:all};

my @exist     = qw{cherry banana apple};
my @not_there = qw{not-there missing-file};

mock_all_file_checks( \&my_custom_check );

sub my_custom_check {
    my ( $check, $f ) = @_;

    if ( $check eq 'e' || $check eq 'f' ) {
        return CHECK_IS_TRUE  if grep { $_ eq $f } @exist;
        return CHECK_IS_FALSE if grep { $_ eq $f } @not_there;
    }

    return CHECK_IS_FALSE if $check eq 'd' && grep { $_ eq $f } @exist;

    # fallback to the original Perl OP
    return FALLBACK_TO_REAL_OP;
}

foreach my $f (@exist) {
    ok( -e $f,  "-e $f is true" );
    ok( -f $f,  "-f $f is true" );
    ok( !-d $f, "-d $f is false" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "-e $f is false" );
    ok( !-f $f, "-f $f is false" );
}

unmock_all_file_checks();

done_testing;
