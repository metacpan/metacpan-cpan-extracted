package Perl::Critic::Policy::ControlStructures::ProhibitMultipleSubscripts;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities :booleans ];
use Data::Alias;

use constant PBP_PAGE => 103;

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw[ pbp maintenance ] }
sub applies_to       { return 'PPI::Statement::Compound' }

sub violates {
    my ($self, $elem, $doc) = @_;
    return if $elem->type ne 'foreach';

    my $block = $elem->find_first(sub {    # do a flat search for a PPI::Structure::Block
        my ($s_doc, $s_elem) = @_;
        return $TRUE if $s_elem->isa('PPI::Structure::Block');
        return;    # don't descend into other structures
    });
    return if not $block;    # postfix loop

    my $iterator = $elem->find_first(sub {
        my ($s_doc, $s_elem) = @_;
        return $TRUE if $s_elem->isa('PPI::Token::Symbol');
        die if $s_elem->isa('PPI::Structure::List'); # no iterator, halt search
    });
    return if not $iterator;    # checking $_ is unreliable

    my $subscripts_ref = $block->find('PPI::Structure::Subscript');
    return if not $subscripts_ref;

    my (%used, @violations);
    foreach my $subscript (@$subscripts_ref) {
        my $source = $subscript->sprevious_sibling();
        if ($source->isa('PPI::Token::Operator') and $source eq '->') {
            $source = $source->sprevious_sibling();   # reference subscript
        }
        next if not $source->isa('PPI::Token::Symbol')   # variable
            and not $source->isa('PPI::Token::Word');    # constant

        # skip the topic variable since it can easily reference different things
        next if _eq_symbol($source, '$_');

        # skip delete statements since they require keys
        next if _is_delete_arg($source);

        my $source_is_iterator = _eq_symbol($source, $iterator);
        my $sub_expr = $subscript->find_first('PPI::Statement::Expression');
        foreach my $sub_value (_extract_values($sub_expr)) {
            next if $sub_value eq '$_';
            next    # only check subscripts utilising the current iterator
                if not $source_is_iterator
                and not $sub_value eq $iterator;

            alias my $used_cnt = $used{$source}{$sub_value};
            if ($used_cnt and $used_cnt > 2) {
                my $braced = $subscript->start . $sub_value . $subscript->finish;
                my $desc = "Subscript $braced of $source used multiple times in a block";
                push @violations, $self->violation($desc, PBP_PAGE, $subscript);
            }
            $used_cnt++;
        }
    }

    return @violations;
}

sub _eq_symbol {
    my ($elem, $symbol) = @_;
    return if not $elem->isa('PPI::Token::Symbol');
    return $elem eq $symbol;
}

sub _extract_values {
    my ($expr) = @_;

    my @children = $expr->children;
    return if not @children;

    if (@children == 1) {
        my $child = $children[0];
        return $child->literal if $child->isa('PPI::Token::QuoteLike::Words');
        return $child;
    }

    my @values = ([]);
    foreach my $child (@children) {
        next if $child->isa('PPI::Token::Whitespace');
        if ($child->isa('PPI::Token::Operator') and $child eq ',') {
            push @values, [];
            next;
        }
        push @{ $values[-1] },
              $child->isa('PPI::Token::QuoteLike::Words') ? $child->literal
            : $child->isa('PPI::Token::Quote')            ? $child->string
            :                                               $child;
    }
    return map { join '', map { ref() ? $_->content : $_ } @$_ } @values;
}

sub _is_delete_arg {
    my ($elem) = @_;

    my $maybe_del = $elem->sprevious_sibling();
    if (not $maybe_del) {    # might still be a delete() with parentheses
        my $expr = $elem->parent();
        return if not $expr or not $expr->isa('PPI::Statement');
        my $parens = $expr->parent();
        return if not $parens or not $parens->isa('PPI::Structure::List');

        $maybe_del = $parens->sprevious_sibling();
    }

    return if not $maybe_del;
    return if not $maybe_del->isa('PPI::Token::Word');
    return $maybe_del eq 'delete';
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitMultipleSubscripts - forbid using the same subscript multiple times in a loop

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

Conway suggests only extracting specific values of arrays and hashes in loops
exactly once and assigning them to variables for later access.
Not only does it make the code less cluttered with repeated lookups,
it is also more efficient in many cases.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
