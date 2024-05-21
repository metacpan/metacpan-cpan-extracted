#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

use Cwd        qw( abs_path );
use Path::This qw( $THISDIR );
use Test::More;
use English qw( -no_match_vars );

if ( !$ENV{ 'TEST_AUTHOR' } ) {
    plan 'skip_all' => 'Author tests not required for installation';
}
else {
    # Ensure a recent version of Test::Pod
    my $min_tp = 1.22;               ## no critic (ProhibitMagicNumbers)
    eval "use Test::Pod $min_tp";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Test::Pod $min_tp required for testing POD";
    }

    my @poddirs = ( abs_path( $THISDIR ) . '/../' );

    all_pod_files_ok( all_pod_files( @poddirs ) );
}

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

90-pod.t

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
