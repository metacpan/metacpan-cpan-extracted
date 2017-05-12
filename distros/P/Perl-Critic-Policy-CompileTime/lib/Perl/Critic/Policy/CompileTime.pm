# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Perl::Critic::Policy::CompileTime;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use base qw(Perl::Critic::Policy);

use PPIx::PerlCompiler::Element         ();
use PPIx::PerlCompiler::Statement       ();
use PPIx::PerlCompiler::Structure::List ();

our $VERSION = '0.03';

my $POLICY = 'Global side effects at compile time';

sub supported_parameters {
    return ();
}

sub default_severity {
    return $SEVERITY_HIGH;
}

sub default_themes {
    return qw(more);
}

sub applies_to {
    return 'PPI::Statement::Scheduled';
}

sub violates {
    my ( $self, $node, $doc ) = @_;

    return unless $node->isa_prerun_block;

    my @violations;

    $node->find(
        sub {
            my ( $begin_block, $statement ) = @_;

            return 0 unless $statement->isa('PPI::Statement');

            push @violations,
              $self->violation(
                'Performs process image operations',
                $POLICY, $statement
              ) if $statement->performs_process_ops;

            push @violations,
              $self->violation(
                'Assignment to special var',
                $POLICY, $statement
              ) if $statement->mutates_special_var;

            push @violations, $self->violation( 'System I/O', $POLICY, $statement )
              if $statement->performs_system_io;

            return 0;
        }
    );

    return @violations;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::CompileTime - Provide Perl::Critic support for hunting
down compile-time side effects

=head1 SUMMARY

Perl::Critic::Policy::CompileTime and PPIx::PerlCompiler: A dynamic duo for
finding abberant code with bad compile-time side effects!

=head1 SYNOPSIS

    ~$ cat ~/.perlcriticrc
    include = CompileTime

=head1 DESCRIPTION

Perl::Critic::Policy::CompileTime is a Perl::Critic module which allows one to
quickly find code in a large codebase or installation which may not run the way
one expects when compiled by the Perl compiler, B::C.  With the help of the
underlying code in PPIx::PerlCompiler, it does so by performing some rudimentary
pattern matching against statements and subexpressions in specific instances.

=head2 FEATURES

PPIx::PerlCompiler provides the ability to check compile time code blocks,
BEGIN, UNITCHECK, and CHECK, for code that may likely have system-wide side
effects, or may perform I/O that may invalidate dependent state of compiled
binaries when they run.

Perl::Critic::Policy::CompileTime issues severity level 40 advisories regarding
the aforementioned features in Perl code.  To use this module with Perl::Critic,
simply add something like the following to your .perlcriticrc file:

    include = CompileTime

=head1 SEE ALSO

=over

=item L<Perl::Critic>

=back

=head1 AUTHOR

Xan Tronix <xan@cpan.org>
