package Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock;
use 5.008001;
use strict;
use warnings;
use parent 'Perl::Critic::Policy';
use List::Util qw(any);
use Perl::Critic::Utils qw(:severities);
use constant DESC => '"return" statement in "do" block.';
use constant EXPL => 'A "return" in "do" block causes confusing behavior.';

our $VERSION = "0.03";

sub supported_parameters { return (); }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw(bugs complexity); }
sub applies_to           { return 'PPI::Structure::Block'; }

sub violates {
    my ($self, $elem, undef) = @_;

    return if !_is_do_block($elem);
    return if _is_do_loop($elem);

    my @stmts = $elem->schildren;
    return if !@stmts;

    my @violations;

    for my $stmt (@stmts) {
        push @violations, $self->violation(DESC, EXPL, $stmt) if _is_return($stmt);
    }

    return @violations;
}

sub _is_do_block {
    my ($elem) = @_;

    return 0 if !$elem->sprevious_sibling;
    return $elem->sprevious_sibling->content eq 'do';
}

sub _is_do_loop {
    my ($elem) = @_;
    return 0 if !$elem->snext_sibling;
    return $elem->snext_sibling->content eq 'while' || $elem->snext_sibling->content eq 'until';
}

sub _is_return {
    my ($stmt) = @_;

    return any { $_->content eq 'return' } $stmt->schildren;
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock - Do not "return" in "do" block

=head1 AFFILIATION
 
This policy is a policy in the L<Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock> distribution.

=head1 DESCRIPTION

Using C<return> statement in C<do> block causes unexpected behavior. A C<return> returns from entire subroutine, not from C<do> block.

    sub foo {
        my ($x) = @_;
        my $y = do {
            return 2 if $x < 10; # not ok
            return 3 if $x < 100; # not ok
            4;
        };
        return $x * $y;
    }
    print foo(5); # prints 2, not 10;

If you want to do early-return, you should move the body of C<do> block to a new subroutine and call it.

    sub calc_y {
        my ($x) = @_;
        return 2 if $x < 10;
        return 3 if $x < 100;
        return 4;
    }

    sub foo {
        my ($x) = @_;
        my $y = calc_y($x);
        return $x * $y;
    }
    print foo(5); # prints 10

=head1 CONFIGURATION
 
This Policy is not configurable except for the standard options.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

