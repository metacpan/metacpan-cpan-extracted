#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Readonly;

use Perl::Critic;

use Test::More;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitFileSize';

Readonly::Scalar my $SIZE_LIMIT_VALUE_1     => 1;
Readonly::Scalar my $SIZE_LIMIT_VALUE_38    => 38;
Readonly::Scalar my $SIZE_LIMIT_VALUE_99999 => 99_999;

plan 'tests' => 8;

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
    my ( $code_ref, $size_count_limit ) = @_;

    my @params;

    if ( $size_count_limit ) {
        @params = ( '-params' => { 'size_count_limit' => $size_count_limit } );
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
    my $code = '';

    my @violations = _check_perl_critic( \$code, $SIZE_LIMIT_VALUE_1 );

    ok !@violations, 'no violation with empty code';
    if ( @violations ) {
        my $desc = _get_description_from_violations( @violations );
        diag $desc;
    }
}

#####

{
    my $code = '#';

    my @violations = _check_perl_critic( \$code, $SIZE_LIMIT_VALUE_1 );

    ok !@violations, 'no violation with one character';
    if ( @violations ) {
        my $desc = _get_description_from_violations( @violations );
        diag $desc;
    }
}

#####

{
    my $code = <<'END_OF_STRING';
##
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $SIZE_LIMIT_VALUE_1 );

    ok !!@violations, 'violation with two characters, when only one allowed';

    my $desc = _get_description_from_violations( @violations );

    is $desc, 'File "__UNKNOWN__" with high char count (3)', 'violation description correct with __UNKNOWN__';
}

#####

{
    my $code = <<'END_OF_STRING';
# some one line comment
# second line
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $SIZE_LIMIT_VALUE_38 );

    ok !@violations, 'no violation with 38 Chars, when 38 Chars allowed';

    if ( @violations ) {
        my $desc = _get_description_from_violations( @violations );
        diag $desc;
    }
}

#####

{
    use Path::This qw( $THISDIR );
    use Cwd        qw( abs_path );

    my $test_script_path = abs_path( $THISDIR . '/test_data/Some-Script.pl' );

    my @violations = _check_perl_critic( $test_script_path, $SIZE_LIMIT_VALUE_99999 );

    ok !@violations, 'no violation with script file, when 99999 bytes allowed';

    if ( @violations ) {
        my $desc = _get_description_from_violations( @violations );
        diag $desc;
    }
}

#####

{
    use Path::This qw( $THISDIR );
    use Cwd        qw( abs_path );

    my $test_script_path = abs_path( $THISDIR . '/test_data/Some-Script.pl' );

    my @violations = _check_perl_critic( $test_script_path, $SIZE_LIMIT_VALUE_1 );

    ok !!@violations, 'violation with script file, when only one byte allowed';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/File\s".+[\/\\]Some-Script\.pl"\swith\shigh\sbyte\scount\s[(]720[)]/ixmso,
        'description correct count 720 bytes in Some-Script';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------
