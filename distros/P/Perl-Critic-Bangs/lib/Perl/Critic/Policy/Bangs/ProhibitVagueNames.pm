package Perl::Critic::Policy::Bangs::ProhibitVagueNames;

use strict;
use warnings;
use Perl::Critic::Utils qw( :booleans :severities );
use base 'Perl::Critic::Policy';

our $VERSION = '1.10';

#----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'names',
            description    => 'Words to prohibit as variable names.',
            behavior       => 'string list',
            default_string => 'data info var obj object tmp temp',
        },
        {
            name           => 'add_names',
            description    => 'Additional words to prohibit as variable names.',
            behavior       => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM        }
sub default_themes       { return qw( bangs readability ) }
sub applies_to           { return 'PPI::Token::Symbol'    }

=for stopwords whitespace

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitVagueNames - Don't use generic variable names.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Variables should have descriptive names. Names like C<$data> and
C<$info> are completely vague.

   my $data = shift;      # not OK.
   my $userinfo = shift   # OK

See
L<http://www.oreillynet.com/onlamp/blog/2004/03/the_worlds_two_worst_variable.html>
for more of my ranting on this.

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

    # make $basename be the variable name with no sigils or namespaces.
    my $canonical = $elem->canonical();
    my $basename = $canonical;
    $basename =~ s/.*:://;
    $basename =~ s/^[\$@%]//;

    foreach my $naughty ( keys %{ $self->{'_names'} } ) {
        if ( $basename eq $naughty ) {
            my $desc = qq(Variable named "$canonical");
            my $expl = 'Variable names should be specific, not vague';
            return $self->violation( $desc, $expl, $elem );
        }
    }
    return;
}

1;

=head1 AUTHOR

Andy Lester C<< <andy at petdance.com> >> from code by
Andrew Moore C<< <amoore at mooresystems.com> >>.

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
Based on App::Fluff by Andy Lester, "<andy at petdance.com>"

=head1 COPYRIGHT

Copyright (c) 2006-2011 Andy Lester

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
