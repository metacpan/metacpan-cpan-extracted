package Perl::Critic::Policy::Bangs::ProhibitCommentedOutCode;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.14';

#---------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'commentedcoderegex',
            description    => 'Regular expression to use to look for code in comments.',
            behavior       => 'string',
            default_string => '\$[A-Za-z_].*=', ## no critic (RequireInterpolationOfMetachars)
        },
    );
}

sub default_severity     { return $SEVERITY_LOW           }
sub default_themes       { return qw( bangs maintenance ) }
sub applies_to           { return 'PPI::Token::Comment'   }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( $elem =~ $self->{_commentedcoderegex} ) {
        my $desc = q(Code found in comment);
        my $expl = q(Commented-out code found can be confusing);
        return $self->violation( $desc, $expl, $elem );
    }

    return;
}

1;

__END__
=for stopwords regex

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitCommentedOutCode - Commented-out code is usually noise. It should be removed.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Commented-out code is often a sign of a place where the developer
is unsure of how the code should be.  If historical information
about the code is important, then keep it in your version control
system.

=head1 CONFIGURATION

By default, this policy attempts to look for commented out code by
looking for variable assignments in code as represented by the regular
expression C<qr/\$[A-Za-z_].*=/> found in a comment. You can change
that regex by specifying a value for C<commentedcoderegex>.

  [Bangs::ProhibitCommentedOutCode]
  commentedcoderegex = \$[A-Za-z_].*=/

=head1 AUTHOR

Andrew Moore C<< amoore@mooresystems.com >>

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
Based on App::Fluff by Andy Lester, "<andy at petdance.com>"

=head1 COPYRIGHT

Copyright (C) 2006-2017 Andy Lester and Andrew Moore

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
