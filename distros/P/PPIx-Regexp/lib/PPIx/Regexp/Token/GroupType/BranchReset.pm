=head1 NAME

PPIx::Regexp::Token::GroupType::BranchReset - Represent a branch reset specifier

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?|(foo)|(bar))}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::BranchReset> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::BranchReset> has no descendants.

=head1 DESCRIPTION

This token represents the specifier for a branch reset - namely the
C<?|> that comes after the left parenthesis.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType::BranchReset;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

=begin comment

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{
    my %explanation = (
	'?|'	=> 'Re-use capture group numbers',
    );

    sub __explanation {
	return \%explanation;
    }
}

sub perl_version_introduced {
    return '5.009005';
}

sub __defining_string {
    return '?|';
}

=end comment

=cut

__PACKAGE__->__setup_class(
    {
	'?|'	=> {
	    expl	=> 'Re-use capture group numbers',
	    intro	=> '5.009005',
	},
    },
);

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
