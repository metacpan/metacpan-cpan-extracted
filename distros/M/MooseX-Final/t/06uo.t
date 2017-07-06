=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Final works with UNIVERSAL::Object.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
{ package Workaround::For::Oddity; use Test::Requires { 'UNIVERSAL::Object' => '0.10' } };
use Test::Fatal;

{
	package Example::Phone;
	use parent qw(UNIVERSAL::Object);
	our %HAS = ( number => sub { die 'required' } );
	sub call { die('unimplemented') }
	
	# Make final
	sub BUILD {
		use MooseX::Final;
		assert_final( my $self = shift );
	}
}

{
	package Example::Phone::Mobile;
	use parent -norequire, 'Example::Phone';
	sub send_sms { die('unimplemented') }
}

is(
	exception { Example::Phone->new(number => 1) },
	undef,
);

#line 53
my $e = exception { Example::Phone::Mobile->new(number => 2) };
like(
	$e,
	qr/Example::Phone is final; Example::Phone::Mobile should not inherit from it at (.+) line 53/,
);

done_testing;

