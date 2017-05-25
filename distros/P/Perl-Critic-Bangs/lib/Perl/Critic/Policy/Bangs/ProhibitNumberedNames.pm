package Perl::Critic::Policy::Bangs::ProhibitNumberedNames;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.12';

sub supported_parameters {
    return (
        {
            name           => 'exceptions',
            description    => 'Things to allow in variable and subroutine names.',
            behavior       => 'string list',
            default_string => 'base64 md5 rc4 sha0 sha1 sha256 utf8 x11 win32',
        },
        {
            name           => 'add_exceptions',
            description    => 'Additional things to allow in variable and subroutine names.',
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM        }
sub default_themes   { return qw( bangs maintenance ) }
sub applies_to       { return 'PPI::Statement::Variable', 'PPI::Statement::Sub' }

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitNumberedNames - Prohibit variables and subroutines with names that end in digits.

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

Both variable and subroutine names are checked.

See
L<http://www.oreillynet.com/onlamp/blog/2004/03/the_worlds_two_worst_variable.html>
for more of my ranting on this.

=head1 CONFIGURATION

This policy has two options: C<exceptions> and C<add_exceptions>.

=head2 C<exceptions>

This policy starts with a list of numbered names that are legitimate
to have ending with a number:

    base64 md5 rc4 sha0 sha1 sha256 utf8 x11 win32

The exceptions for the policy also apply to names based on the exceptions.
If C<$base64> is acceptable as an exception, so is C<$calculated_base64>.
The exception must be separated from the left part of the name by at
least one underscore to be recognized.

The exceptions are case-insensitive.  C<$UTF8> and C<$utf8> are both
seen the same as far as being exceptions.

To replace the list of exceptions, specify a value for the
C<exceptions> option.

    [Bangs::ProhibitNumberedNames]
    exceptions = logan7 babylon5

=head2 C<add_exceptions>

To add exceptions to the list, give a value for C<add_exceptions> in
your F<.perlcriticrc> file like this:

    [Bangs::ProhibitNumberedNames]
    add_exceptions = adam12 route66

=cut

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_exceptions} =
        { %{ $self->{_exceptions} }, %{ $self->{_add_exceptions} } };

    return $TRUE;
}

sub _init_exception_regexes {
    my $self = shift;

    my @regexes;
    for my $exception ( keys %{$self->{_exceptions}} ) {
        push( @regexes, qr/.*_\Q$exception\E$/ );
    }

    $self->{_exception_regexes} = \@regexes;

    return;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

    my $type = ref($elem);
    if ( $type eq 'PPI::Statement::Variable' ) {
        for my $symbol ( $elem->symbols ) {
            # make $basename be the variable name with no sigils or namespaces.
            my $fullname = $symbol->canonical;
            my $basename = $fullname;
            $basename =~ s/.*:://;
            $basename =~ s/^[\$@%]//;

            push( @violations, $self->_potential_violation( $symbol, $fullname, $basename, 'Variable' ) );
        }
    }
    elsif ( $type eq 'PPI::Statement::Sub' ) {
        my $fullname = $elem->name;
        my $basename = $fullname;
        $basename =~ s/.*:://;

        push( @violations, $self->_potential_violation( $elem, $fullname, $basename, 'Subroutine' ) );
    }
    elsif ( $type eq 'PPI::Statement::Scheduled' ) {
        # Ignore BEGIN, INIT, etc
    }
    else {
        die "Unknown type $type";
    }

    return @violations;
}

sub _potential_violation {
    my $self     = shift;
    my $symbol   = shift;
    my $fullname = shift;
    my $basename = shift;
    my $what     = shift;

    if ( $basename =~ /\D+\d+$/ ) {
        $basename = lc $basename;

        # Check to see if it's an exact match for an exception.
        # $md5 is excepted by "md5"
        return if $self->{_exceptions}{$basename};

        # Check to see if they match the end of the variable regexes.
        # $foo_md5 is excepted by "md5"
        $self->_init_exception_regexes unless $self->{_exception_regexes};
        for my $re ( @{$self->{_exception_regexes}} ) {
            return if $basename =~ $re; # We're OK via exception
        }

        my $desc = qq{$what named "$fullname"};
        my $expl = "$what names should not be differentiated only by digits";
        return $self->violation( $desc, $expl, $symbol );
    }

    return;
}

1;

__END__
=head1 AUTHOR

Andy Lester C<< <andy at petdance.com> >>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Andy Lester

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
