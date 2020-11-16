package Perl::Critic::Policy::ProhibitOrReturn;
use 5.008001;
use strict;
use warnings;
use parent 'Perl::Critic::Policy';
use constant DESC => '`or return` in source file';
use constant EXPL => '`or return` is prohibited. Use equivalent conditional statement instead.';

use Perl::Critic::Utils qw( :severities );

our $VERSION = "0.02";

sub supported_parameters { return (); }
sub default_severity     { return $SEVERITY_MEDIUM; }
sub default_themes       { return qw(bugs complexity maintenance); }
sub applies_to           { return 'PPI::Token::Word'; }

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem->content ne 'return';

    my $sprev = $elem->sprevious_sibling;
    return if !$sprev;
    return if $sprev->content ne 'or';

    return $self->violation(DESC, EXPL, $elem->parent);
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ProhibitOrReturn - Do not use `or return`

=head1 AFFILIATION
 
This policy is a policy in the L<Perl::Critic::Policy::ProhibitOrReturn> distribution.

=head1 DESCRIPTION

Avoid using C<or return>. Consider using equivalent C<if> (or C<unless>) statement instead.

    # not ok
    sub foo {
        my ($x) = @_;
        $x or return;
        ...
    }

    # ok
    sub foo {
        my ($x) = @_;
        return if !$x;
        ...
    }

=head1 CONFIGURATION
 
This Policy is not configurable except for the standard options.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

