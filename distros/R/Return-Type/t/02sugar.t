=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< :ReturnType >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Return::Type;
use Types::Standard qw( Int Num );

use constant Rounded => Int->plus_coercions(Num, q{int($_)});

sub foo :ReturnType(Rounded, coerce => 1) {
	$_[0];
}

is( scalar foo(4), 4 );
is( scalar foo(3.1), 3 );
ok exception { my $x = foo("x") };

if (0)
#for ('foo')
{
	require B::Deparse;
	note( "Deparsed '$_':" );
	my $ref = __PACKAGE__->can($_);
	note( B::Deparse->new->coderef2text($ref) );
}

done_testing;
