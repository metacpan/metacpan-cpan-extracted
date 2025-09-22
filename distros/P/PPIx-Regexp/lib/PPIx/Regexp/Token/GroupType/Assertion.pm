=head1 NAME

PPIx::Regexp::Token::GroupType::Assertion - Represent a look ahead or look behind assertion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo(?=bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Assertion> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents the parenthesized look ahead and look behind
assertions.

=head1 METHODS

This class provides the following public methods beyond those provided
by its superclass.

=cut

package PPIx::Regexp::Token::GroupType::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{
    COOKIE_LOOKAROUND_ASSERTION
    @CARP_NOT
};

our $VERSION = '0.090';

use constant EXPL_NLA	=> 'Negative look-ahead assertion';
use constant EXPL_NLB	=> 'Negative look-behind assertion';
use constant EXPL_PLA	=> 'Positive look-ahead assertion';
use constant EXPL_PLB	=> 'Positive look-behind assertion';

use constant DEF	=> {

    '?!'	=> {
	expl	=> EXPL_NLA,
	look_ahead	=> 1,
    },
    '*nla:'	=> {
	expl	=> EXPL_NLA,
	intro	=> '5.027009',
	look_ahead	=> 1,
    },
    '*negative_lookahead:'	=> {
	expl	=> EXPL_NLA,
	intro	=> '5.027009',
	look_ahead	=> 1,
    },
    '?<!'	=> {
	expl	=> EXPL_NLB,
	intro	=> '5.005',
    },
    '*nlb:'	=> {
	expl	=> EXPL_NLB,
	intro	=> '5.027009',
    },
    '*negative_lookbehind:'	=> {
	expl	=> EXPL_NLB,
	intro	=> '5.027009',
    },
    '?='	=> {
	expl	=> EXPL_PLA,
	look_ahead	=> 1,
	positive	=> 1,
    },
    '*pla:'	=> {
	expl	=> EXPL_PLA,
	intro	=> '5.027009',
	look_ahead	=> 1,
	positive	=> 1,
    },
    '*positive_lookahead:'	=> {
	expl	=> EXPL_PLA,
	intro	=> '5.027009',
	look_ahead	=> 1,
	positive	=> 1,
    },
    '?<='	=> {
	expl	=> EXPL_PLB,
	intro	=> '5.005',
	positive	=> 1,
    },
    '*plb:'	=> {
	expl	=> EXPL_PLB,
	intro	=> '5.027009',
	positive	=> 1,
    },
    '*positive_lookbehind:'	=> {
	expl	=> EXPL_PLB,
	intro	=> '5.027009',
	positive	=> 1,
    },
};

__PACKAGE__->__setup_class();

sub __match_setup {
    my ( undef, $tokenizer ) = @_;	# $class not used
    $tokenizer->__cookie_exists( COOKIE_LOOKAROUND_ASSERTION )
	and return;
    my $nest_depth = 1;
    $tokenizer->cookie( COOKIE_LOOKAROUND_ASSERTION, sub {
	    my ( undef, $token ) = @_;	# $tokenizer not used
	    $token
		and $token->isa( 'PPIx::Regexp::Token::Structure' )
		and $nest_depth += ( {
		    '('	=> 1,
		    ')'	=> -1,
		}->{ $token->content() } || 0 );
	    return $nest_depth;
	},
    );
    return;
}

=head2 is_look_ahead

This method returns a true value if the assertion is a look-ahead
assertion, or a false value if it is a look-behind assertion.

=cut

sub is_look_ahead {
    my ( $self ) = @_;
    return $self->DEF->{ $self->unescaped_content() }->{look_ahead};
}

=head2 is_positive

This method returns a true value if the assertion is a positive
assertion, or a false value if it is a negative assertion.

=cut

sub is_positive {
    my ( $self ) = @_;
    return $self->DEF->{ $self->unescaped_content() }->{positive};
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PPIx-Regexp>,
L<https://github.com/trwyant/perl-PPIx-Regexp/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2023, 2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
