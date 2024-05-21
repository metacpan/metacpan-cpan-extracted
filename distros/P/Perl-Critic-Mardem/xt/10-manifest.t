#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

use Test::More;
use English qw( -no_match_vars );

if ( !$ENV{ 'RELEASE_TESTING' } && !$ENV{ 'TEST_AUTHOR' } ) {
    plan 'skip_all' => 'Release and Author tests not required for installation';
}
else {
    my $min_tcm = 0.9;                          ## no critic (ProhibitMagicNumbers)
    eval "use Test::CheckManifest $min_tcm";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Test::CheckManifest $min_tcm required";
    }

    ok_manifest( { 'filter' => [ qr/ignore[.]txt/ixmso, qr/[.]gitignore/ixmso ] } );
}

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

00-manifest.t

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
