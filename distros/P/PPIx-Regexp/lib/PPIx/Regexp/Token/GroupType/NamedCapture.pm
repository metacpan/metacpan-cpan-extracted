=head1 NAME

PPIx::Regexp::Token::GroupType::NamedCapture - Represent a named capture

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?<baz>foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::NamedCapture> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::NamedCapture> has no descendants.

=head1 DESCRIPTION

This class represents a named capture specification. Its content will be
something like one of the following:

 ?<NAME>
 ?'NAME'
 ?P<NAME>

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::GroupType::NamedCapture;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use Carp qw{ confess };

use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME @CARP_NOT };

our $VERSION = '0.063';

use constant TOKENIZER_ARGUMENT_REQUIRED => 1;

sub __new {
    my ( $class, $content, %arg ) = @_;

    defined $arg{perl_version_introduced}
	or $arg{perl_version_introduced} = '5.009005';

    my $self = $class->SUPER::__new( $content, %arg );

    foreach my $name ( $arg{tokenizer}->capture() ) {
	defined $name or next;
	$self->{name} = $name;
	return $self;
    }

    confess 'Programming error - can not figure out capture name';
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    my ( $self ) = @_;
    return sprintf q<Capture match into '%s'>, $self->name();
}

=head2 name

This method returns the name of the capture.

=cut

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

sub __make_group_type_matcher {
    return {
	''	=> [ 
	    qr/ \A [?] P? < ( @{[ RE_CAPTURE_NAME ]} ) > /smxo,
	    qr/ \A [?] ' ( @{[ RE_CAPTURE_NAME ]} ) ' /smxo,
	],
	'?'	=> [
	    qr/ \A \\ [?] P? < ( @{[ RE_CAPTURE_NAME ]} ) > /smxo,
	    qr/ \A \\ [?] ' ( @{[ RE_CAPTURE_NAME ]} ) ' /smxo,
	],
	q{'}	=> [
	    qr/ \A [?] P? < ( @{[ RE_CAPTURE_NAME ]} ) > /smxo,
	    qr/ \A [?] \\ ' ( @{[ RE_CAPTURE_NAME ]} ) \\ ' /smxo,
	],
    };
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
