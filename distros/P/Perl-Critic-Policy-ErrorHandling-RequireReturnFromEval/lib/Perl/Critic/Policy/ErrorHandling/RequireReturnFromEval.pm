package Perl::Critic::Policy::ErrorHandling::RequireReturnFromEval;

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :ppi };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.00';

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(style) }
sub applies_to       { return 'PPI::Structure::Block' }

sub violates {
    my ($self, $elem, undef) = @_;

    my $prev = $elem->sprevious_sibling();
    if (!$prev) {
        return;
    }
    if (!$prev->isa('PPI::Token::Word')) {
        return;
    }
    if ($prev->content() ne 'eval') {
        return;
    }

    my @children = $elem->children();
    if (!@children) {
        return;
    }

    my @statements = grep { $_->isa('PPI::Statement') } @children;
    if (!@statements) {
        return;
    }

    foreach my $stmt (@statements) {
        my @stmt_children = $stmt->children();
        if (!@stmt_children) {
            next;
        }

        my $first = $stmt_children[0];
        if (!$first->isa('PPI::Token::Word')) {
            next;
        }
        if ($first->content() eq 'return') {
            return;
        }
    }

    return $self->violation('Eval block should use explicit return', '', $elem);
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireReturnFromEval - Require explicit return in eval blocks

=head1 SYNOPSIS

    # Bad
    my $result = eval { some_function() };

    # Good
    my $result = eval { return some_function() };

=head1 DESCRIPTION

When using C<eval> as an expression to capture a return value, the eval block
should use an explicit C<return> statement. This makes the intent clear and
avoids confusion about what the eval block returns.

This policy catches eval blocks that lack an explicit C<return>.

    # Violation
    my $params = eval { JSON::decode_json($content) };

    # No violation
    my $params = eval { return JSON::decode_json($content) };

This policy only applies to C<eval { ... }> blocks, not C<eval "string">.

=head1 CONFIGURATION

This policy is not configurable. It has no options.

=head1 METHODS

=head2 default_severity

Returns C<$SEVERITY_MEDIUM>.

=head2 default_themes

Returns C<style>.

=head2 applies_to

Returns C<PPI::Structure::Block>.

=head2 violates

Checks if an eval block uses an explicit C<return> statement.

=head1 AUTHOR

Blaine Motsinger E<lt>blaine@renderorange.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Blaine Motsinger

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
