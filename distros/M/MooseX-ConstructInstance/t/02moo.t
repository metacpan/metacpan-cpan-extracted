=head1 PURPOSE

Test that MooseX::ConstructInstance works with Moo.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use if ($] < 5.010), 'UNIVERSAL::DOES';

{
	package Local::Other;
	use Moo;
	has param => (is => 'rw');
	sub new_from_blah {
		my $class = shift;
		$class->new(param => 'blah');
	}
}

{
	package Local::Class1;
	use Moo;
	with qw( MooseX::ConstructInstance );
	has xxx => (is => 'ro');
	sub make_other {
		my $self = shift;
		$self->construct_instance('Local::Other', param => $self->xxx);
	}
	sub make_blah {
		my $self = shift;
		no warnings 'once';
		local $MooseX::ConstructInstance::CONSTRUCTOR = 'new_from_blah';
		$self->construct_instance('Local::Other');
	}
}

{
	package Local::Class2;
	use Moo;
	extends qw( Local::Class1 );
	around construct_instance => sub {
		my ($orig, $self, $class, @args) = @_;
		my $inst = $self->$orig($class, @args);
		$inst->param(2) if $inst->DOES('Local::Other');
		return $inst;
	}
}

can_ok('Local::Class1', 'construct_instance');
ok(
	!Local::Class1->can('import'),
	'Local::Class1 did not accidentally consume an "import" method'
);

ok(
	'Local::Class1'->DOES('MooseX::ConstructInstance'),
	"Local::Class1->DOES(MooseX::ConstructInstance)",
);

{
	my $obj = Local::Class1->new(xxx => 3);
	my $oth = $obj->make_other;
	is($oth->param, 3, 'construct_instance method can be used to construct an instance');
}

{
	my $obj = Local::Class2->new(xxx => 3);
	my $oth = $obj->make_other;
	is($oth->param, 2, 'construct_instance method can be hooked via method modifiers');
}

{
	my $obj = Local::Class1->new(xxx => 3);
	my $oth = $obj->make_blah;
	is($oth->param, 'blah', '$CONSTUCTOR package variable can be used to alter constructor method name');
}

done_testing;
