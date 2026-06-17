#!/bin/false
# ABSTRACT: Prohibit method calls in string concatenation
# PODNAME: Perl::Critic::Policy::Misc::ProhibitMethodsInStringConcat

use strict;
use warnings;

package Perl::Critic::Policy::Misc::ProhibitMethodsInStringConcat;
$Perl::Critic::Policy::Misc::ProhibitMethodsInStringConcat::VERSION = '0.01';
use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(:severities);

use namespace::clean;

sub default_severity { return $SEVERITY_MEDIUM; }
sub default_themes   { return qw(misc); }
sub applies_to       { return 'PPI::Token::Operator'; }

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne q{.};

    my $stmt = $elem->parent();
    while ( $stmt && !$stmt->isa('PPI::Statement') ) {
        $stmt = $stmt->parent();
    }
    return if !$stmt;

    my $found = $stmt->find(
        sub {
            my $node = $_[1];
            return 0 if !$node->isa('PPI::Token::Operator');
            return 0 if $node->content() ne '->';
            my $next = $node->snext_sibling();
            return 0 if !$next || !$next->isa('PPI::Token::Word');
            return 1;
        }
    );

    return if !$found;

    return $self->violation(
        'Method call used in string concatenation',
        'Assign the method result to a variable first, or use printf/sprintf instead.  '
            . 'Method calls in string concatenation lose the variable name in undef warnings -- '
            . 'Perl can only say "uninitialized value" without naming which call returned undef, '
            . 'making debugging harder.',
        $elem,
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::Misc::ProhibitMethodsInStringConcat - Prohibit method calls in string concatenation

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This policy flags method calls used as operands to the C<.> (string
concatenation) operator.

=head2 Why?

When Perl concatenates strings and an operand is C<undef>, it emits a
warning.  The quality of that warning depends on the operand's form:

    my $result = "Name: " . $obj->name() . " Age: " . $obj->age();

produces:

    Use of uninitialized value in concatenation (.) or string at ... line N

No indication of I<which> method returned C<undef>.  On a long
concatenation line the developer must manually bisect to find the
offending call.

By contrast, assigning the result to a variable first:

    my $name = $obj->name();   # warns: Use of uninitialized value $name ...
    my $age  = $obj->age();
    my $result = "Name: " . $name . " Age: " . $age;

Perl names the variable:

    Use of uninitialized value $name in concatenation (.) or string at ... line N

The variable name pinpoints the source of C<undef> immediately.

This difference matters because method calls are opaque -- the call
expression has no name that Perl can surface in the diagnostic.  A
scalar variable, on the other hand, carries its identifier through to
the warning.

Using C<printf> / C<sprintf> avoids the problem altogether by
separating the template from the value list, making each argument a
distinct expression on its own line or position.

=head2 Remediation

    # Instead of -- method call hidden inside concat:
    my $result = "Name: " . $obj->name() . " Age: " . $obj->age();

    # Option 1 -- unload to a variable first:
    my $name = $obj->name();
    my $age  = $obj->age();
    my $result = "Name: " . $name . " Age: " . $age;

    # Option 2 -- use sprintf (separates template from data):
    my $result = sprintf 'Name: %s Age: %s', $obj->name(), $obj->age();

=head1 EXAMPLES

    my $x = "Hello " . $obj->name();      # not ok

    my $x = $obj->name() . "Hello";       # not ok

    my $x = 'hello' . ( $foo->bar / 2 ) . 'there';  # not ok (method in parens)

    my $name = $obj->name();              # ok -- unload to variable first
    my $x    = "Hello " . $name;

    my $x = sprintf 'Hello %s', $obj->name();  # ok -- use sprintf

The policy traverses into parentheses, so method calls nested inside
parenthesized sub-expressions within a concatenation are also flagged.

=head2 C<.=> (concat-assign)

The C<.=> operator is not flagged when used with a single method call:

    $x .= $obj->method();   # ok -- single method, clear intent

However, when the right side of C<.=> itself contains C<.> concatenation
with method calls, those inner C<.> operators are flagged:

    $x .= $obj->method() . $obj->other();   # not ok (inner .)
    $x .= "Name: " . $obj->method();          # not ok (inner .)

=head1 CONFIGURATION

This policy does not accept any configuration parameters.

=head1 SEE ALSO

L<Perl::Critic>, L<perldiag/"Use of uninitialized value %s">

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
