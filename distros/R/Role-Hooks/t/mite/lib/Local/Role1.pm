package Local::Role1;
use Local::Mite -role;

use Role::Hooks ();

Role::Hooks->before_apply(__PACKAGE__, sub {
	push @{ $Local::xxx{+__PACKAGE__}||=[] }, [before_apply => @_];
});

Role::Hooks->after_apply(__PACKAGE__, sub {
	push @{ $Local::xxx{+__PACKAGE__}||=[] }, [after_apply => @_];
});

1;
