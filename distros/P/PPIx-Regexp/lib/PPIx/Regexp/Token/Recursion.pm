=head1 NAME

PPIx::Regexp::Token::Recursion - Represent a recursion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(foo(?1)?)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Recursion> is a
L<PPIx::Regexp::Token::Reference|PPIx::Regexp::Token::Reference>.

C<PPIx::Regexp::Token::Recursion> has no descendants.

=head1 DESCRIPTION

This class represents a recursion to a named or numbered capture.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Recursion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME @CARP_NOT };

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    my ( $self ) = @_;
    $self->is_named()
	and return sprintf q<Recurse into capture group '%s'>,
	    $self->name();
    if ( $self->is_relative() ) {
	my $number = $self->number();
	$number >= 0
	    and return sprintf
		q<Recurse into %s following capture group (%d in this regexp)>,
		PPIx::Regexp::Util::__to_ordinal_en( $self->number() ),
		$self->absolute();
	return sprintf
	    q<Back reference to %s previous capture group (%d in this regexp)>,
	    PPIx::Regexp::Util::__to_ordinal_en( - $self->number() ),
	    $self->absolute();
    } elsif ( my $number = $self->absolute() ) {
	return sprintf q<Recurse into capture group %d>, $number;
    } else {
	return q<Recurse to beginning of regular expression>;
    }
}

sub perl_version_introduced {
    return '5.009005';
}

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return (
	[ qr{ \A \( \? (?: ( [-+]? [0-9]+ )) \) }smx, { is_named => 0 } ],
	[ qr{ \A \( \? (?: R) \) }smx,
	    { is_named => 0, capture => '0' } ],
	[ qr{ \A \( \?  (?: & | P> ) ( @{[ RE_CAPTURE_NAME ]} ) \) }smxo,
	    { is_named => 1 } ],
    );
}

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
