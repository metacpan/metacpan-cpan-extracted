#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Readonly;
use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };

use Test::More;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitConditionComplexity';

Readonly::Scalar my $MCC_VALUE_1 => 1;
Readonly::Scalar my $MCC_VALUE_2 => 2;
Readonly::Scalar my $MCC_VALUE_4 => 4;

plan 'tests' => 28;

#####

sub _get_perl_critic_object
{
    my @configs = @_;

    my $pc = Perl::Critic->new(
        '-profile'  => 'NONE',
        '-only'     => 1,
        '-severity' => 1,
        '-force'    => 0
    );

    $pc->add_policy( '-policy' => $POLICY_NAME, @configs );

    return $pc;
}

#####

sub _check_perl_critic
{
    my ( $code_ref, $max_mccabe ) = @_;

    my @params;
    if ( $max_mccabe ) {
        @params = ( '-params' => { 'max_mccabe' => $max_mccabe } );
    }

    my $pc = _get_perl_critic_object( @params );

    return $pc->critique( $code_ref );
}

#####

sub _get_description_from_violations
{
    my @violations = @_;

    if ( @violations ) {
        my $violation = shift @violations;
        my $desc      = $violation->description();

        if ( $desc ) {
            return $desc;
        }
    }

    return q{};
}

#####

{
    my $code = <<'END_OF_STRING';
# empty code
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'empty code block ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(1) {
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'if(1) no violation';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(1==1) {
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'if(1==1) no violation';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(!1) {
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'if(!1) no violation';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( ! 1 && 1 ) {
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok @violations, 'violation with logical and';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso, 'violation description correct with if';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( ! 1 && 1 ) {
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_2 );

    ok !@violations, 'no violation with logical and when mcc 2 allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex if mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scondition\s.*\scomplexity\sscore\s[(]3[)]/ixmso, 'description correct mcc value 3 not allowd';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_4 );

    ok !@violations, 'no violation if mcc value 3 allowed limit 4';
}

#####

{
    my $code = <<'END_OF_STRING';
        unless( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex unless mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"unless"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with unless';
}

#####

{
    my $code = <<'END_OF_STRING';
        while( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex while mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"while"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with while';
}

#####

{
    my $code = <<'END_OF_STRING';
        until( 1==1 || 2 == 3 && 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex until mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"until"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with until';
}

#####

{
    my $code = <<'END_OF_STRING';
        do {
            print 'test not reached';
        } while( 1 == 0 && 2 == 3 || 4 == 6 );
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex do-while mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"while"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with do-while';
}

#####

{
    my $code = <<'END_OF_STRING';
        for( my $i = 0; $i < 10 && 1 == 0 && 2 == 3 || 4 == 6 ; $i++) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex for mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"for"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso, 'violation description correct with for';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(0!=0) }{
            print 'test not reached';
        }
        elsif( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex elsif mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"elsif"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with elsif';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1==1 || 2 == 3 && 4 == 6 && ( 1==1 || 2 == 3 && 4 == 6 || ( 1==1 || 2 == 3 && 4 == 6 ) ) ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex if with sub-condition-blockes mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with if which includes sub-blocks';
}

#####

{
    my $code = <<'END_OF_STRING';
        my $test = ( 1 == 0 && 2 == 3 || 4 == 6 ) ? "true" : "false";
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'complex condition in assignment has no violation because no PPI::Structure::Condition';
}

#####

{
    my $code = <<'END_OF_STRING';
         print 'test not reached' if( 1==1 || 2 == 3 && 4 == 6 && ( 1==1 || 2 == 3 && 4 == 6 || ( 1==1 || 2 == 3 && 4 == 6 ) ) );
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'complex posix-if with sub-condition-blockes mcc value reached';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scondition\s.*\scomplexity\sscore\s[(]\d+[)]/ixmso,
        'violation description correct with posix-if which includes sub-blocks';
}

#####

{
    my $code = <<'END_OF_STRING';
         print 'test not reached' if 1==1 || 2 == 3 && 4 == 6;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'posix-if without parentheses never tested becaus it\'s not an PPI::Structure::Condition';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------
