use strict;
use warnings;
use Time::HiRes qw(time);

{
	package Person;
	
	use Moose;
	use Types::Standard qw(Int Str);
	use MooseX::MungeHas $ENV{PERL_FASTER} ? qw(is_ro no_isa) : qw(is_ro);
	
	my $Natural = Int->create_child_type(
		name       => "NaturalNumber",
		constraint => sub { $_ >= 0 },
	);
	
	has name => (isa => Str, required => 1);
	has age  => (isa => $Natural);
	
	__PACKAGE__->meta->make_immutable;
}

my $start = time;
while (<DATA>)
{
	/^(.+)\|(.+)$/ and Person->new(name => $1, age => $2);
}
my $finish = time;

printf("Completed run in: %0.6f s.\n", $finish - $start);

=pod

=encoding utf-8

=head1 PURPOSE

Here's a simple use case for MooseX::MungeHas. View this files's source
code for the full script.

We use an environment variable to toggle type constraint checks:

 use MooseX::MungeHas $ENV{PERL_FASTER} ? qw(is_ro no_isa) : qw(is_ro);

When the code is run normally (e.g. on a development machine), the C<no_isa>
munger is not in effect. When run on a machine with the C<PERL_FASTER>
environment variable set to true (e.g. on the production machine), the
C<no_isa> munger strings into action, and type constraints cease to be
checked. (Because any type errors would have cropped up on the development
machines, right??)

=head1 OUTPUT

Your machine is probably faster than mine, but a typical output with
C<PERL_FASTER> false is:

 Completed run in: 0.002362 s.

And with C<PERL_FASTER> true:

 Completed run in: 0.001246 s.

=head1 DEPENDENCIES

Example requires L<Moose> and L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Alice|10
Bob|11
Carol|12
Dave|10
Eve|11
Freddie|10
Greg|11
Hattie|9
Isabel|8
Jack|10
Kevin|11
Lisa|12
Maggie|9
Nils|10
Oliver|11
Peter|10
Quentin|9
Rachel|11
Simon|12
Tessa|8
Usma|9
Veronica|11
Wendy|10
Xavier|10
Yolande|11
Zachary|9
