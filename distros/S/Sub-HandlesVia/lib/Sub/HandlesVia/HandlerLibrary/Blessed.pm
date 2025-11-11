use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Blessed;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050005';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( is_Str );

# Non-exhaustive list!
sub handler_names {
	return;
}

sub has_handler {
	my ($me, $handler_name) = @_;
	is_Str $handler_name;
}

my $simple_method_name = qr/\A[^\W0-9]\w*\z/;
sub get_handler {
	my ($me, $handler_name) = @_;
	
	if ( $handler_name =~ $simple_method_name ) {
		return handler(
			name      => 'Blessed:' . $handler_name,
			template  => sprintf(
				'use Scalar::Util (); ⸨q{$ATTRNAME is not a blessed object}⸩ unless Scalar::Util::blessed( $GET ); $GET->%s(@ARG)',
				$handler_name,
			),
			is_mutator => 0,
		);
	}
	else {
		return handler(
			name      => 'Blessed:' . $handler_name,
			template  => sprintf(
				'use Scalar::Util (); ⸨q{$ATTRNAME is not a blessed object}⸩ unless Scalar::Util::blessed( $GET ); $GET->${\ %s }(@ARG)',
				B::perlstring($handler_name),
			),
			is_mutator => 0,
		);
	}
}

1;

__END__

=head1 NAME

Sub::HandlesVia::HandlerLibrary::Blessed - library of object-related methods

=head1 SYNOPSIS

  package My::Class {
    use Moo;
    use Sub::HandlesVia;
    use Types::Standard 'Object';
    use HTTP::Tiny;
    has http_ua => (
      is => 'rwp',
      isa => Object,
      handles_via => 'Blessed',
      handles => {
        'http_get'  => 'get',
        'http_post' => 'post',
      },
      default => sub { HTTP::Tiny->new },
    );
  }

=head1 DESCRIPTION

This is a library of methods for L<Sub::HandlesVia>.

=head1 DELEGATABLE METHODS

Unlike the other libraries supplied by Sub::HandlesVia, this library allows
you to delegate to I<any> method name.

It assumes that the attribute value is a blessed object, and calls the
correspondingly named method on it.

L<Moo>, L<Moose>, L<Mouse>, and L<Mite> all have this kind of delegation
built-in anyway, but this module allows you to perform the delegation using
Sub::HandlesVia. This may be useful for L<Object::Pad> and L<Class::Tiny>,
which don't have a built-in delegation feature.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

