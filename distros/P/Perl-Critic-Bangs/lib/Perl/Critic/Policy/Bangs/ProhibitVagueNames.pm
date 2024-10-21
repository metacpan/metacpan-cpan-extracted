package Perl::Critic::Policy::Bangs::ProhibitVagueNames;

use strict;
use warnings;
use Perl::Critic::Utils qw( :booleans :severities );
use base 'Perl::Critic::Policy';

our $VERSION = '1.14';

#----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'names',
            description    => 'Words to prohibit as variable and subroutine names.',
            behavior       => 'string list',
            default_string => 'data info var obj object tmp temp',
        },
        {
            name           => 'add_names',
            description    => 'Additional words to prohibit as variable and subroutine names.',
            behavior       => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM        }
sub default_themes       { return qw( bangs readability ) }
sub applies_to           { return 'PPI::Statement::Variable', 'PPI::Statement::Sub' }

=for stopwords whitespace

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitVagueNames - Don't use generic variable and subroutine names.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Variables and subroutines should have descriptive names. Names like
C<$data> and C<$info> are completely vague.

   my $data = shift;      # not OK.
   my $userinfo = shift   # OK

See
L<http://www.oreillynet.com/onlamp/blog/2004/03/the_worlds_two_worst_variable.html>
for more of my ranting on this.

By default, the following names are bad: data, info, var, obj, object, tmp, temp

The checking of names is case-insensitive.  C<$info> and C<$INFO> are equally bad.

=head1 CONFIGURATION

This policy has two options: C<names> and C<add_names>.

=head2 C<names>

To replace the list of vague names, specify them as a whitespace
delimited set of prohibited names.

    [Bangs::ProhibitVagueNames]
    names = data count line next

=head2 C<add_names>

To add to the list of vague names, specify them as a whitespace
delimited set of prohibited names.

    [Bangs::ProhibitVagueNames]
    add_names = foo bar bat

=cut

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_names} = { %{ $self->{_names} }, %{ $self->{_add_names} } };

    return $TRUE;
}


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

    my $type = ref($elem);
    if ( $type eq 'PPI::Statement::Variable' ) {
        for my $symbol ( $elem->symbols ) {
            # Make $basename be the variable name with no sigils or namespaces.
            my $fullname = $symbol->canonical;
            my $basename = $fullname;
            $basename =~ s/^[\$@%]//;
            $basename =~ s/.*:://;

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

    $basename = lc $basename;

    foreach my $naughty ( keys %{ $self->{'_names'} } ) {
        if ( $basename eq lc $naughty ) {
            my $desc = qq{$what named "$fullname"};
            my $expl = "$what names should be specific, not vague";
            return $self->violation( $desc, $expl, $symbol );
        }
    }

    return;
}

1;

__END__
=head1 AUTHOR

Andy Lester C<< <andy at petdance.com> >> from code by
Andrew Moore C<< <amoore at mooresystems.com> >>.

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
Based on App::Fluff by Andy Lester, "<andy at petdance.com>"

=head1 COPYRIGHT

Copyright (c) 2006-2013 Andy Lester

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
