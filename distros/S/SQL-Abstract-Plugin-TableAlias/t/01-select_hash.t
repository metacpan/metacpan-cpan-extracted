
use Test::More;

use SQL::Abstract;

my $sql = SQL::Abstract->new->plugin('+TableAlias');

subtest 'hash_array_select_basic' => sub {
	plan tests => 7;
	
	select_test({
		select => {
			select => [ qw/a b c d/ ],
			from => [
				"tickets",
			],
			group_by => [ 'a' ]
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, tickets.d FROM tickets AS tickets GROUP BY tickets.a|,
	});

	select_test({
		select => {
			select => [ { foo => { -as => 'bar' } }, { baz => { -as => 'zap' } } ],
			from => [
				"tickets",
			],
			group_by => [ 'a' ]
		},
		expected => q|SELECT tickets.foo AS bar, tickets.baz AS zap FROM tickets AS tickets GROUP BY tickets.a|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				"other"
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets, other AS other ORDER BY tickets.a|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [ { baz => { -as => 'zap' } } ] ],
			from => [
				"tickets",
				"other"
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.baz AS zap FROM tickets AS tickets, other AS other ORDER BY tickets.a|,
	});


	select_test({
		select => {
			select => [ [qw/a b c/], qw/d e/ ],
			from => [
				"tickets",
				"other",
				"third"
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d, other.e FROM tickets AS tickets, other AS other, third AS third ORDER BY tickets.a|,
	});


	select_test({
		select => {
			select => [ [qw/a b c/], [qw/d/], [qw/e/] ],
			from => [
				"tickets",
				"other",
				"third"
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d, third.e FROM tickets AS tickets, other AS other, third AS third ORDER BY tickets.a|,
	});

	select_test({
		select => {
			select => [ [qw/a b/], "c"],
			from => [
				"tickets",
				"other",
				-join => [
					kaput => on => { "tickets.id" => "ticket_id" }
				],
			],
			where => {
				a => "inna",
				b => ["other", "thing", "okay"],
				c => { "!=", "completed" }
			},
			order_by => {
				-asc => [qw/a c/]
			},
			group_by => [ 'a' ]
		},
		expected => q|SELECT tickets.a, tickets.b, other.c FROM tickets AS tickets, other AS other JOIN kaput AS kaput ON tickets.id = kaput.ticket_id WHERE ( other.c != ? AND tickets.a = ? AND ( tickets.b = ? OR tickets.b = ? OR tickets.b = ? ) ) GROUP BY tickets.a ORDER BY tickets.a ASC, other.c ASC|,
	});
};

subtest 'hash_array_select_join' => sub {
	plan tests => 4; 

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a ORDER BY tickets.a|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					  on => { -op => [
					      '>', { -ident => [ 'a' ] },
					      { -ident => [ 'a' ] },
					  ] },
					  to => { -ident => [ 'other' ] },
					  type => 'left',
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a ORDER BY tickets.a|,
	});

	select_test({
		select => {
			talias => [qw/t o/],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT t.a, t.b, t.c, o.d FROM tickets AS t LEFT JOIN other AS o ON t.a > o.a ORDER BY t.a|,
	});

	select_test({
		select => {
			talias => [qw/t o/],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					  on => { -op => [
					      '>', { -ident => [ 'a' ] },
					      { -ident => [ 'a' ] },
					  ] },
					  to => { -ident => [ 'other' ] },
					  type => 'left',
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT t.a, t.b, t.c, o.d FROM tickets AS t LEFT JOIN other AS o ON t.a > o.a ORDER BY t.a|,
	});

};

subtest 'hash_array_select_where' => sub {
	plan tests => 8; 

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/], qw/e/ ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				},
				-join => {
					on => { 'e' => { '!=' => 'e' } },
					to => 'thing',
					type => 'right'
				}
			],
			where => {
				a => "inna",
				b => ["other", "thing", "okay"],
				d => { "!=", "completed" }
			},
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d, thing.e FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a RIGHT JOIN thing AS thing ON other.e != thing.e WHERE ( other.d != ? AND tickets.a = ? AND ( tickets.b = ? OR tickets.b = ? OR tickets.b = ? ) ) ORDER BY tickets.a|,
	});

	select_test({
   		select => {
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				{
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				{
					user => 'other',
					status => 'ready'
				}	
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, thing.d FROM tickets AS tickets LEFT JOIN thing AS thing ON tickets.id > thing.id WHERE ( ( ( tickets.status LIKE ? OR tickets.status LIKE ? ) AND tickets.user = ? ) OR ( tickets.status = ? AND tickets.user = ? ) )|
	});

	select_test({
   		select => {
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				{
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				{
					user => 'other',
					status => 'ready'
				}	
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, thing.d FROM tickets AS tickets LEFT JOIN thing AS thing ON tickets.id > thing.id WHERE ( ( ( tickets.status LIKE ? OR tickets.status LIKE ? ) AND tickets.user = ? ) OR ( tickets.status = ? AND tickets.user = ? ) )|
	});

	select_test({
   		select => {
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				-and => {
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				-or => {
					user => 'other',
					status => 'ready'
				}
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, thing.d FROM tickets AS tickets LEFT JOIN thing AS thing ON tickets.id > thing.id WHERE ( ( ( tickets.status LIKE ? OR tickets.status LIKE ? ) AND tickets.user = ? ) OR ( tickets.status = ? OR tickets.user = ? ) )|
	});

	select_test({
		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/], qw/e/ ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				},
				-join => {
					on => { 'e' => { '!=' => 'e' } },
					to => 'thing',
					type => 'right'
				}
			],
			where => {
				a => "inna",
				b => ["other", "thing", "okay"],
				d => { "!=", "completed" }
			},
			order_by => 'a'
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d, t3.e FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a RIGHT JOIN thing AS t3 ON t2.e != t3.e WHERE ( t1.a = ? AND ( t1.b = ? OR t1.b = ? OR t1.b = ? ) AND t2.d != ? ) ORDER BY t1.a|,
	});

	select_test({
   		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				{
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				{
					user => 'other',
					status => 'ready'
				}	
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN thing AS t2 ON t1.id > t2.id WHERE ( ( ( t1.status LIKE ? OR t1.status LIKE ? ) AND t1.user = ? ) OR ( t1.status = ? AND t1.user = ? ) )|
	});

	select_test({
   		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				{
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				{
					user => 'other',
					status => 'ready'
				}	
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN thing AS t2 ON t1.id > t2.id WHERE ( ( ( t1.status LIKE ? OR t1.status LIKE ? ) AND t1.user = ? ) OR ( t1.status = ? AND t1.user = ? ) )|
	});

	select_test({
   		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/] ],
			where => [
				-and => {
					user => 'test',
					status => { -like => ['pending%', 'dispatched'] }
				},
				-or => {
					user => 'other',
					status => 'ready'
				}
			],
			from => [
				"tickets",
				-join => {
					on => { 'id' => { '>' => 'id' } },
					to => 'thing',
					type => 'left'
				}
			],
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN thing AS t2 ON t1.id > t2.id WHERE ( ( ( t1.status LIKE ? OR t1.status LIKE ? ) AND t1.user = ? ) OR ( t1.status = ? OR t1.user = ? ) )|
	});
};

subtest 'hash_array_select_order_by' => sub {
	plan tests => 6; 
	
	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a ORDER BY tickets.a|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => [qw/a d/]
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a ORDER BY tickets.a, other.d|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => [qw/a/, { -asc => 'd' }, { -desc => [qw/b c/] } ]
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a ORDER BY tickets.a, other.d ASC, tickets.b DESC, tickets.c DESC|,
	});

	select_test({
		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => [qw/a/, { -asc => 'd' }, { -desc => [qw/b c/] } ]
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a ORDER BY t1.a, t2.d ASC, t1.b DESC, t1.c DESC|,
	});

	select_test({
		select => {
			talias => [qw/t1 t2 t3/],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => 'a'
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a ORDER BY t1.a|,
	});

	select_test({
		select => {
			talias => [qw/t1 t2 t3/],		
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			order_by => [qw/a d/]
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a ORDER BY t1.a, t2.d|,
	});

};

subtest 'hash_array_select_group_by' => sub {
	plan tests => 4; 

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			group_by => [qw/a d/],
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a GROUP BY tickets.a, other.d|,
	});

	select_test({
		select => {
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			group_by => { -op => [ ',', { -ident => [ 'a' ] }, { -ident => [ 'd' ] } ] },
		},
		expected => q|SELECT tickets.a, tickets.b, tickets.c, other.d FROM tickets AS tickets LEFT JOIN other AS other ON tickets.a > other.a GROUP BY tickets.a, other.d|,
	});

	select_test({
		select => {
			talias => [ qw/t1 t2/ ],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			group_by => [qw/a d/],
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a GROUP BY t1.a, t2.d|,
	});

	select_test({
		select => {
			talias => [ qw/t1 t2/ ],
			select => [ qw/a b c/, [qw/d/] ],
			from => [
				"tickets",
				-join => {
					on => { 'a' => { '>' => 'a' } },
					to => 'other',
					type => 'left'
				}
			],
			group_by => { -op => [ ',', { -ident => [ 'a' ] }, { -ident => [ 'd' ] } ] },
		},
		expected => q|SELECT t1.a, t1.b, t1.c, t2.d FROM tickets AS t1 LEFT JOIN other AS t2 ON t1.a > t2.a GROUP BY t1.a, t2.d|,
	});
};

sub select_test {
	my ($args) = @_;
	my ($stmt, @bind) = $sql->select($args->{select});
	is($stmt, $args->{expected}, 'expected: ' . $args->{expected});
}

done_testing;




