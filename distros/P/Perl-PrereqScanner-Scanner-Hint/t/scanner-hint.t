#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hint.t
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Perl-PrereqScanner-Scanner-Hint.
#
#   perl-Perl-PrereqScanner-Scanner-Hint is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Perl-PrereqScanner-Scanner-Hint is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Perl-PrereqScanner-Scanner-Hint. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use lib 't';
use strict;
use warnings;

use Perl::PrereqScanner;
use Test::Deep qw{ cmp_deeply re };
use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Test::Warn;

has source => (         # Source code to scan.
    isa         => 'Str',
    is          => 'ro',
);

has scanners => (       # Scanner to use.
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    default     => sub { [ 'Hint' ] },
);

has extra_scanners => ( # Extra scanners.
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    default     => sub { [] },
);

has expected => (       # Expected outcome.
    isa         => 'HashRef',
    is          => 'ro',
    required    => 1,
);

has warnings => (
    isa         => 'ArrayRef',
    is          => 'ro',
    default     => sub { [] },
);

test 'Test' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    my $scanner = Perl::PrereqScanner->new( {
        scanners        => $self->scanners,
        extra_scanners  => $self->extra_scanners,
    } );
    my $prereqs;
    my $exception;
    warnings_like(
        sub { $exception = exception { $prereqs = $scanner->scan_string( $self->source ); }; },
        $expected->{ warnings }
    );
    if ( defined( $expected->{ exception } ) ) {
        cmp_deeply( $exception, $expected->{ exception }, 'scan must fail' );
    } else {
        is( $exception, undef, 'scan must success' );
        cmp_deeply( $prereqs->as_string_hash, $expected->{ prereqs }, 'prereqs' );
    };
};

run_me 'No hints' => {
    source   => q{
        package Assa;   # No hints.
        1;
    },
    expected => {
        prereqs => {},  # No requirements.
    },
};

run_me 'Hints' => {
    source   => q{
        package Assa;

        ##REQUIRE:strict                     # Standalone hint.
        my $var; ## REQUIRES: warnings       # Hint in a trailing comment.
        ## REQUIRE : Assa 0.001
        ##  REQUIRES  :  Another::Module  v0.7.1  # comments allowed.
        ## REQUIRE:   Class::X == 0.7
        ## REQUIRE:   Class::Y  >= 1.2 , != 1.5, < 2.0

        ### REQUIRE:  Class::Z   # Ignored: triple hash.
        ## require:   Class::Z   # Ignored: not uppercase.
        ## REQUIRE    Class::Z   # Ignored: no colon.

        1;
    },
    expected => {
        prereqs => {
            'strict'            => 0,
            'warnings'          => 0,
            'Assa'              => 0.001,
            'Another::Module'   => 'v0.7.1',
            'Class::X'          => '== 0.7',
            'Class::Y'          => '>= 1.2, < 2.0, != 1.5',
        },
    },
};

# Comments in regular expressions are not recognized.
run_me 'Regexp' => {
    source   => q{
        package Assa;
        ## REQUIRE: Assa1                            # Hint
        my $RE = qr{
            Regular Expression ## REQUIRE: Assa2     # *Not* a hint
        }x;
        1;
    },
    expected => {
        prereqs => {
            'Assa1' => 0,
        },
    },
};

run_me 'Bad module name' => {
    source   => q{
        package Assa;
        ## REQUIRE: Bad:Module:Name
        1;
    },
    expected => {
        exception => "'Bad:Module:Name' is not a valid module name at (*UNKNOWN*) line 3.\n",
    },
};

run_me 'Bad version' => {
    source   => q{
        package Assa; ## REQUIRE: Good::Module::Name oops
        1;
    },
    expected => {
        exception => re( qr{.*'oops'.*\Q at (*UNKNOWN*) line 2.\E} ),
    },
};

# Check `#line` directive is respected.
run_me 'Line directive' => {
    # Hash staring a directive must be in the first column.
    source   => q{#line 10 Assa.pm
        package Assa;
        ## REQUIRE: Bad:Module:Name
        1;
    },
    expected => {
        exception => "'Bad:Module:Name' is not a valid module name at Assa.pm line 11.\n",
    },
};

run_me 'Deprecation warning' => {
    source   => q{          # 1
        package Assa;       # 2
        # REQUIRE: strict   # 3
        1;                  # 4
    },
    expected => {
        prereqs => {
            'strict'            => 0,
        },
        warnings => [
            qr{^Starting a hint with one hash is deprecated.* at .* line 3\.$},
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
