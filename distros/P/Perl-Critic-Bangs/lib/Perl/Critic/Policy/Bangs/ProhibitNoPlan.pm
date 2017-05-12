package Perl::Critic::Policy::Bangs::ProhibitNoPlan;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.10';

sub supported_parameters { return ()                             }
sub default_severity     { return $SEVERITY_LOW                  }
sub default_themes       { return qw( bangs tests )              }
sub applies_to           { return 'PPI::Token::QuoteLike::Words' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;


    if ( $elem =~ qr/\bno_plan\b/ ) {
        # Make sure that the previous sibling was Test::More, or return
        my $sib = $elem->sprevious_sibling() || return;
        $sib->isa('PPI::Token::Word') && $sib eq 'Test::More' || return;

        my $desc = q(Test::More with "no_plan" found);
        my $expl = q(Test::More should be given a plan indicating the number of tests run);
        return $self->violation( $desc, $expl, $elem );
    }

    return;
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitNoPlan - Know what you're going to test.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Test::More should be given a plan indicting the number of tests to be
run. This policy searches for instances of Test::More called with
"no_plan".

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

Andrew Moore <amoore@mooresystems.com>

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
Based on App::Fluff by Andy Lester, "<andy at petdance.com>"

=head1 COPYRIGHT

Copyright (c) 2006-2011 Andy Lester <andy@petdance.com> and Andrew
Moore <amoore@mooresystems.com>

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
