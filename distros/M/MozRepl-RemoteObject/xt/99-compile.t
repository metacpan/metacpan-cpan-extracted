#!perl -w

use warnings;
use strict;
use File::Find;
use Test::More;
BEGIN {
    eval 'use Capture::Tiny ":all"; 1';
    if ($@) {
        plan skip_all => "Capture::Tiny needed for testing";
        exit 0;
    };
};

plan 'no_plan';

my $last_version = undef;

my $have_anyevent = eval { require AnyEvent; 1 };

sub check {
    return if (! m{(\.pm|\.pl) \z}xmsi);
    return if /AnyEvent/ and not $have_anyevent;

    my ($stdout, $stderr, $exit) = capture(sub {
        system( $^X, '-Mblib', '-wc', $_ );
    });

    s!\s*\z!!
        for ($stdout, $stderr);

    if( $exit ) {
        diag $stderr;
        diag "Exit code: ", $exit;
        fail($_);
    } elsif( $stderr ne "$_ syntax OK") {
        diag $stderr;
        fail($_);
    } else {
        pass($_);
    };
}

find({wanted => \&check, no_chdir => 1},
     grep { -d $_ }
         'blib', 'scripts', 'examples', 'bin', 'lib'
     );
