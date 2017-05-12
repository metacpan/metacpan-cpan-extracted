package Perl::Critic::Policy::Bangs::ProhibitNumberedNames;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.10';

sub supported_parameters {
    return (
        {
            name           => 'exceptions',
            description    => 'Things to allow in variable names.',
            behavior       => 'string list',
            default_string => 'md5 x11 utf8',
        },
        {
            name           => 'add_exceptions',
            description    => 'Additional things to allow in variable names.',
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM        }
sub default_themes   { return qw( bangs maintenance ) }
sub applies_to       { return 'PPI::Token::Symbol'    }

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitNumberedNames - Prohibit variables differentiated by trailing numbers.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Similar variables should be meaningfully different.  A lazy way to
differentiate similar variables is by tacking a number at the end.

    my $total = $price * $quantity;
    my $total2 = $total + ($total * $taxrate);
    my $total3 = $total2 + $shipping;

The difference between C<$total> and C<$total3> is not described
by the silly "3" at the end.  Instead, it should be:

    my $merch_total = $price * $quantity;
    my $subtotal = $merch_total + ($merch_total * $taxrate);
    my $grand_total = $subtotal + $shipping;

See
L<http://www.oreillynet.com/onlamp/blog/2004/03/the_worlds_two_worst_variable.html>
for more of my ranting on this.

=head1 CONFIGURATION

This policy has two options: C<exceptions> and C<add_exceptions>.

=head2 C<exceptions>

This policy starts with a list of numbered names that are legitimate
to have ending with a number:

    md5, x11, utf8

To replace the list of exceptions, specify a value for the
C<exceptions> option.

    [Bangs::ProhibitNumberedNames]
    exceptions = logan7 babylon5

=head2 C<add_exceptions>

To add exceptions to the list, give a value for C<add_exceptions> in
your F<.perlcriticrc> file like this:

    [Bangs::ProhibitVagueNames]
    add_names = adam12 route66

=cut

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_exceptions} =
        { %{ $self->{_exceptions} }, %{ $self->{_add_exceptions} } };

    return $TRUE;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # make $basename be the variable name with no sigils or namespaces.
    my $canonical = $elem->canonical();
    my $basename = $canonical;
    $basename =~ s/.*:://;
    $basename =~ s/^[\$@%]//;

    if ( $basename =~ /\D+\d+$/ ) {
        $basename =~ s/.+_(.+)/$1/; # handle things like "partial_md5"
        $basename = lc $basename;
        return if $self->{_exceptions}{$basename};

        my $desc = qq(Variable named "$canonical");
        my $expl = 'Variable names should not be differentiated only by digits';
        return $self->violation( $desc, $expl, $elem );
    }
    return;
}

1;

=head1 AUTHOR

Andy Lester C<< <andy at petdance.com> >>

=head1 COPYRIGHT

Copyright (c) 2006-2011 Andy Lester

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
