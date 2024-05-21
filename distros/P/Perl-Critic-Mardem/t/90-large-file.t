#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

use Readonly;

use Perl::Critic;

use Test::More;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitLargeFile';

Readonly::Scalar my $LINE_LIMIT_VALUE_1   => 1;
Readonly::Scalar my $LINE_LIMIT_VALUE_2   => 2;
Readonly::Scalar my $LINE_LIMIT_VALUE_3   => 3;
Readonly::Scalar my $LINE_LIMIT_VALUE_999 => 999;

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
    my ( $code_ref, $line_count_limit ) = @_;

    my @params;

    if ( $line_count_limit ) {
        @params = ( '-params' => { 'line_count_limit' => $line_count_limit } );
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

    my @violations = _check_perl_critic( \$code, $LINE_LIMIT_VALUE_1 );

    ok !@violations, 'no violation with empty code';
}

#####

{
    my $code = <<'END_OF_STRING';
# some one line comment
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $LINE_LIMIT_VALUE_1 );

    ok !@violations, 'no violation with one line comment';
}

#####

{
    my $code = <<'END_OF_STRING';
# some one line comment
# second line
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $LINE_LIMIT_VALUE_1 );

    ok !!@violations, 'violation with two line comment, when only one allowed';

    my $desc = _get_description_from_violations( @violations );

    is $desc, 'File "__UNKNOWN__" with high line count (2)', 'violation description correct with __UNKNOWN__';
}

#####

{
    my $code = <<'END_OF_STRING';
# some one line comment
# second line
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $LINE_LIMIT_VALUE_2 );

    ok !@violations, 'no violation with two line comment, when two lines allowed';
}

#####

{
    use Path::This qw( $THISDIR );
    use Cwd        qw( abs_path );

    my $test_script_path = abs_path( $THISDIR . '/test_data/Some-Script.pl' );

    my @violations = _check_perl_critic( $test_script_path, $LINE_LIMIT_VALUE_999 );

    ok !@violations, 'no violation with script file, when 999 lines allowed';
}

#####

{
    use Path::This qw( $THISDIR );
    use Cwd        qw( abs_path );

    my $test_script_path = abs_path( $THISDIR . '/test_data/Some-Script.pl' );

    my @violations = _check_perl_critic( $test_script_path, $LINE_LIMIT_VALUE_1 );

    ok !!@violations, 'violation with script file, when only one line allowed';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/File\s".+[\/\\]Some-Script\.pl"\swith\shigh\sline\scount\s[(]49[)]/ixmso,
        'description correct count 49 lines in Some-Script';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

90-large-file

=head1 DESCRIPTION

Test-Script

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Mardem>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=cut
