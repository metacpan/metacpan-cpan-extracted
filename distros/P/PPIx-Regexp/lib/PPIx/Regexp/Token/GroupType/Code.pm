=head1 NAME

PPIx::Regexp::Token::GroupType::Code - Represent one of the embedded code indicators

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?{print "hello world!\n")}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Code> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Code> has no descendants.

=head1 DESCRIPTION

This method represents one of the embedded code indicators, either '?'
or '??', in the zero-width assertion

 (?{ print "Hello, world!\n" })

or the old-style deferred expression syntax

 my $foo;
 $foo = qr{ foo (??{ $foo }) }smx;

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub __match_setup {
    my ( undef, $tokenizer ) = @_;	# Invocant unused
    $tokenizer->expect( qw{ PPIx::Regexp::Token::Code } );
    return;
}

__PACKAGE__->__setup_class( {
	'??'	=> {
	    expl	=> 'Evaluate code, use as regexp at this point',
	    intro	=> '5.006',
	},
	'?p'	=> {
	    expl	=> 'Evaluate code, use as regexp at this point (removed in 5.9.5)',
	    intro	=> '5.005',	# Presumed. I can find no documentation.
	    remov	=> '5.009005',
	},
	'?'		=> {
	    expl	=> 'Evaluate code. Always matches.',
	    intro	=> '5.005',
	},
    },
    {
	suffix	=> '{',
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
