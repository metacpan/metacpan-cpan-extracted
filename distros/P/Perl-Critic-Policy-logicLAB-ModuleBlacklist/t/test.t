
use strict;
use warnings;

use Env qw($TEST_VERBOSE);
use Data::Dumper;
use Test::More qw(no_plan);

use_ok 'Perl::Critic::Policy::logicLAB::ModuleBlacklist';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => 't//example.conf',
    '-single-policy' => 'logicLAB::ModuleBlacklist'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy ModuleBlacklist' );

    my $policy = $p[0];

    if ($TEST_VERBOSE) {
        diag Dumper $policy;
    }
}

#Basic use
{
    my $str = q{package Acme::ContainsBlacklisted;
    use Contextual::Return;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use alternative implementation or module instead of Contextual::Return} );
        like( $violation->description,
            qr{Blacklisted: Contextual::Return is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}

#Basic require
{
    my $str = q{package Acme::ContainsBlacklisted;
    require Contextual::Return;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use alternative implementation or module instead of Contextual::Return} );
        like( $violation->description,
            qr{Blacklisted: Contextual::Return is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}


#With recommendation for use
{
    my $str = q{package Acme::ContainsBlacklisted;
    use Try::Tiny;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use recommended module: TryCatch instead of Try::Tiny} );
        like( $violation->description,
            qr{Blacklisted: Try::Tiny is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}

#With recommendation for require
{
    my $str = q{package Acme::ContainsBlacklisted;
    require Try::Tiny;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use recommended module: TryCatch instead of Try::Tiny} );
        like( $violation->description,
            qr{Blacklisted: Try::Tiny is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}

#Multiple violations for use
{
    my $str = q{package Acme::ContainsBlacklisted;
    use IDNA::Punycode;
    use Contextual::Return;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 2 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use (recommended module: [\w:]+|alternative implementation or module) instead of [\w:]+} );
        like( $violation->description,
            qr{Blacklisted: [\w:]+ is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}

#Multiple violations for require
{
    my $str = q{package Acme::ContainsBlacklisted;
    require IDNA::Punycode;
    require Contextual::Return;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 2 );

    foreach my $violation (@violations) {
        like( $violation->explanation,
            qr{Use (recommended module: [\w:]+|alternative implementation or module) instead of [\w:]+} );
        like( $violation->description,
            qr{Blacklisted: [\w:]+ is not recommended by required standard} );
    }

    if ($TEST_VERBOSE) {
        diag Dumper \@violations;
    }
}

#No violations for use
{
    my $str = q{package Acme::ContainsNoBlacklisted;
    use strict;
    use warnings;
    use Net::IDN::Encode qw(:all);
    use TryCatch;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

#No violations for require and use
{
    my $str = q{package Acme::ContainsNoBlacklisted;
    use strict;
    use warnings;
    use Net::IDN::Encode qw(:all);
    require TryCatch;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

#no statement [issue #1]
{
    my $str = q{package Acme::ContainsNoBlacklisted;
    no warnings;
    };

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}
