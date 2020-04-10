package Foo::Roles;
use MooX::Purple;
use MooX::Purple::G -prefix => 'Foo', -lib => 't/test', -module => 1;
role +Role::One {
	public one {
		$self->print(1);
	}
}
role +Role::Two {
	public two {
		$self->print(2);
	}
}
role +Role::Three {
	public three {
		$self->print(3);
	}
}
role +Role::Four {
	public four {
		$self->print(4);
	}
}
1;

=head1 NAME

Foo::Role::One - one

=cut

=head1 METHODS

=cut

=head1 one

	$pkg->one

=cut

=head1 NAME

Foo::Role::Two - two

=cut

=head1 METHODS

=cut

=head1 two

	$pkg->two

=cut

=head1 NAME

Foo::Role::Three - three

=cut

=head1 METHODS

=cut

=head1 three

	$pkg->three

=cut

=head1 NAME

Foo::Role::Four - four

=cut

=head1 METHODS

=cut

=head1 four

	$pkg->four

=cut

