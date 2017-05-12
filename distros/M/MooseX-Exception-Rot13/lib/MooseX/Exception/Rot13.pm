use 5.008003;
use strict;
use warnings;

package MooseX::Exception::Rot13;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose 2.1102 ();
use Moose::Exception ();

Moose::Util::find_meta('Moose::Exception')->add_around_method_modifier(
	message => sub {
		my $next = shift;
		my $self = shift;
		my $mesg = $self->$next(@_);
		$mesg =~ tr/N-ZA-Mn-za-m/A-Za-z/;
		return $mesg;
	},
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Exception::Rot13 - Rot13-encode Moose-generated exception messages

=head1 SYNOPSIS

   setenv PERL5OPT '-MMooseX::Exception::Rot13'
   prove -lv t/*.t

=head1 DESCRIPTION

This module globally applies rot13 encoding to all exceptions generated
by Moose 2.1102 and above. This makes it easy to find places in your
application code and test suite where you're relying on the exact text
of particular error messages. (When what you should be doing now is
checking C<< $exception->isa >>.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Exception-Rot13>.

=head1 SEE ALSO

L<Moose::Exception>,
L<http://en.wikipedia.org/wiki/ROT13>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

