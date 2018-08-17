use v5.12;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package PerlX::Define;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.101';

use B ();
use Keyword::Simple ();
use namespace::clean ();

sub import
{
	shift;
	
	my ($caller, $file, $line) = caller;
	
	if (@_)
	{
		my ($name, $value) = @_;
		
		local $@;
		ref($value)
			? eval qq[
				package $caller;\n#line $line ${\ B::perlstring($file) }
				sub $name () { \$value };
				1;
			]
			: eval qq[
				package $caller;\n#line $line ${\ B::perlstring($file) }
				sub $name () { ${\ B::perlstring($value) } };
				1;
			];
		
		$@ ? die($@) : return;
	}
	
	Keyword::Simple::define('define' => sub
	{
		my $line = shift;
		my ($whitespace1, $name, $whitespace2, $equals) =
			( $$line =~ m{\A([\n\s]*)(\w+)([\n\s]*)(=\>?)}s )
			or Carp::croak("Syntax error near 'define'");
		my $len = length($whitespace1. $name. $whitespace2. $equals);
		substr($$line, 0, $len) = "; use PerlX::Define $name => ";
	});
	
	'namespace::clean'->import(
		-cleanee => $caller,
		'define',
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PerlX::Define - cute syntax for defining constants

=head1 SYNOPSIS

   use v5.12;
   use strict;
   use warnings;
   
   package MyMaths {
      use PerlX::Define;
      define PI = 3.2;
   }

=head1 DESCRIPTION

PerlX::Define is a yet another module for defining constants.

Differences from L<constant.pm|constant>:

=over

=item *

Cute syntax.

Like constant.pm, constants get defined at compile time, not run time.

=item *

Requires Perl 5.12 or above.

If you're lucky enough to be able to free yourself from the shackles of
supporting decade-old versions of Perl, PerlX::Define is your friend.

=item *

Only supports scalar constants.

List constants are rarely useful.

Your constant can of course be a reference to an array or hash, but this
module doesn't attempt to make the referred-to structure read only.

=item *

Doesn't try to handle some of the things constant.pm does like declaring
constants using fully-qualified names, or defining constants pointing at
magic scalars.

=back

Prior to version 0.100, PerlX::Define was bundled with L<Moops>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Define>.

=head1 SEE ALSO

L<constant>.

L<Moops>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
