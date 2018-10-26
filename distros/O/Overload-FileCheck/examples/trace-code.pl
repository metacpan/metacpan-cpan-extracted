#!perl

use strict;
use warnings;

use Carp;
use Overload::FileCheck q{:all};

mock_all_file_checks( \&my_custom_check );

sub my_custom_check {
    my ( $check, $f ) = @_;

    local $Carp::CarpLevel = 2;    # do not display Overload::FileCheck stack
    printf( "# %-10s called from %s", "-$check '$f'", Carp::longmess() );

    # fallback to the original Perl OP
    return FALLBACK_TO_REAL_OP;
}

-d '/root';
-l '/root';
-e '/';
-d '/';

unmock_all_file_checks();

__END__

# The ouput looks similar to

-d '/root' called from  at t/perldoc_mock-all-file-check-trace.t line 26.
-l '/root' called from  at t/perldoc_mock-all-file-check-trace.t line 27.
-e '/'     called from  at t/perldoc_mock-all-file-check-trace.t line 28.
-d '/'     called from  at t/perldoc_mock-all-file-check-trace.t line 29.
