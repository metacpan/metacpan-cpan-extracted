package Perl::Critic::Policy::Bangs::ProhibitFlagComments;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.14';

#----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'keywords',
            description    => 'Words to prohibit in comments.',
            behavior       => 'string list',
            default_string => 'XXX FIXME TODO',
        },
    );
}

sub default_severity     { return $SEVERITY_LOW                             }
sub default_themes       { return qw( bangs maintenance )                   }
sub applies_to           { return qw( PPI::Token::Comment PPI::Token::Pod ) }


#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    foreach my $keyword ( keys %{ $self->{'_keywords'} } ) {
        if ( $elem->content() =~ /\b\Q$keyword\E\b/ ) {
            my $desc = qq(Flag comment '$keyword' found);
            my $expl = qq(Comments containing "$keyword" typically indicate bugs or problems that the developer knows exist);
            return $self->violation( $desc, $expl, $elem );
        }
    }
    return;
}

1;

__END__
=for stopwords FIXME

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitFlagComments - Don't use XXX, TODO, or FIXME.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Programmers often leave comments intended to "flag" themselves to
problems later. This policy looks for comments containing 'XXX',
'TODO', or 'FIXME'.

=head1 CONFIGURATION

By default, this policy only looks for 'XXX', 'TODO', or 'FIXME' in
comments. You can override this by specifying a value for C<keywords>
in your F<.perlcriticrc> file like this:

  [Bangs::ProhibitFlagComments]
  keywords = XXX TODO FIXME BUG REVIEW

=head1 AUTHOR

Andrew Moore <amoore@mooresystems.com>

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
Based on App::Fluff by Andy Lester, "<andy at petdance.com>"

=head1 COPYRIGHT

Copyright (c) 2006-2024 Andy Lester <andy@petdance.com> and Andrew
Moore <amoore@mooresystems.com>.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
