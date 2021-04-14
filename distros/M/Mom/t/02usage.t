=pod

=encoding utf-8

=head1 PURPOSE

Test that Mom compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Local::Role;
	use Mom q( :role foo :required );
}

{
	package Local::Class;
	use Mom q( :with(Local::Role) bar :required :type(Int) :std );
	
	sub sum {
		my $self = shift;
		Int->( $self->foo + $self->bar );
	}
}

my $obj = 'Local::Class'->new( foo => 3, bar => 4 );

is(
	$obj->sum,
	7,
	'sum'
);

like(
	exception { 'Local::Class'->new( foo => 3, bar => [] ) },
	qr/type constraint/,
	':type(Int)',
);

like(
	exception { 'Local::Class'->new( foo => 3 ) },
	qr/re[q]uired/,
	'foo :required',
);

like(
	exception { 'Local::Class'->new( bar => 4 ) },
	qr/re[q]uired/,
	'bar :required',
);

done_testing;

