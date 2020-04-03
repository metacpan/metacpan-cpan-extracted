package Foo::Roles;
use MooX::Purple;
use MooX::Purple::G -prefix => 'Foo', -lib => 't/test', -module => 1;
role +Role::One {
	public one {
		$_[0]->print(1);
	}
}
role +Role::Two {
	public two {
		$_[0]->print(2);
	}
}
role +Role::Three {
	public three {
		$_[0]->print(3);
	}
}
role +Role::Four {
	public four {
		$_[0]->print(4);
	}
}
1;
