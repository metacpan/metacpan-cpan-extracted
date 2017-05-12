package t::ChkUtil;

use strict;

use Test::More;


use vars qw( @ISA @EXPORT @EXPORT_OK );
require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( dualvar_or_skip );
@EXPORT_OK = qw( dualvar_or_skip );

sub dualvar_or_skip ($)
{
    my( $skip ) = @_;
    my $have_dualvar;
    eval {
        local $SIG{__DIE__} = 'DEFAULT';
        require "Scalar/Util.pm";
        my $t = Scalar::Util::dualvar( 10, 'ten' );
        # I assume the above will die if dualvar isn't available
        $have_dualvar = 1 if $t and $t == 10 and $t eq 'ten';
    };
    return if $have_dualvar;
    SKIP: {
        skip "Missing Scalar::Util::dualvar", $skip;
    }
    exit 0;
}

1;
