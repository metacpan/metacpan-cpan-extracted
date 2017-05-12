=pod

=encoding utf-8

=head1 PURPOSE

Test Sub::Trigger::Lock in a typical usage scenario.

=head1 DEPENDENCIES

Moose 2.0600.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { Moose => '2.0600' };
use Test::Fatal;

{
	package Person;
	use Moose;
	
	has name => (is => 'ro', writer => 'set_name');
}

{
	package Band;
	use Moose;
	use Sub::Trigger::Lock -all;
	
	has members => (is => RO);
	
	sub add_members {
		my ($self, @members) = @_;
		my $guard = unlock $self->members;
		push @{$self->members}, @members;
	}
}

my $spice_girls = Band->new(
	members => [
		Person->new(name => 'Victoria Adams'),
		Person->new(name => 'Melanie Brown'),
		Person->new(name => 'Emma Bunton'),
	],
);

is(
	exception { $spice_girls->members->[0]->set_name('Victoria Beckham') },
	undef,
	'no exception for deep change',
);

like(
	exception { $spice_girls->members->[0] = Person->new(name => 'Johnny Cash') },
	qr/^Modification of a read-only value attempted/,
	'exception for shallow change',
);

is(
	exception {
		$spice_girls->add_members(
			Person->new(name => 'Melanie Chisholm'),
			Person->new(name => 'Geri Halliwell'),
		);
	},
	undef,
	'no exception with temporary hash unlock',
);

like(
	exception { $spice_girls->members->[3] = Person->new(name => 'Nick Cave') },
	qr/^Modification of a read-only value attempted/,
	'... which really was temporary',
);

done_testing;

