# -*- perl -*-
# Before `Build install' is performed this script should be runnable with
# `Build test'. After `Build install' it should work as `perl 1.t'
# vim: syntax=perl ts=4
#########################

use Test::More skip_all => 'DBD::AnyData is broken';
#use Carp;
#$SIG{__WARN__} = \&Carp::cluck;

use Test::Requires 'DBD::AnyData';

BEGIN {
	use_ok('POE'); # 1
	use_ok('POE::Component::EasyDBI'); # 2
	use_ok('POE::Component::EasyDBI::SubProcess'); # 3
};

POE::Session->create(
	inline_states => {
		_start => sub {
			$_[KERNEL]->alias_set('test');
			POE::Component::EasyDBI->spawn(
				alias => 'db',
				dsn => 'dbi:AnyData(RaiseError=>1):',
				no_cache => 1, # don't use cached queries with DBD::AnyData
				username => '',
				password => '',
				connected => [ $_[SESSION]->ID, 'connected' ],
				connect_error => [ $_[SESSION]->ID, 'error' ],
				# alt_fork => 1,
			);
			pass("component_started"); # 4
			# shouldnt take more than 30 seconds to finish
			$_[KERNEL]->delay_set(fail => 30);
		},
		fail => sub {
			diag("test took too long to finish");
			fail("too_damn_long");
			return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
		},
		error => sub {
			diag("connect failed $_[ARG0]->{error}");
			fail("connect");
			return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
		},
		connected => sub {
			pass("connected"); # 5
			$_[KERNEL]->post(db => func => {
				args => [ 'test', 'CSV', ["id,foo,bar"], 'ad_import' ],
				event => $_[SESSION]->postback('table_created'),
			});
			$_[KERNEL]->post(db => do => {
				sql => 'CREATE TABLE test2 (id INT, foo TEXT, bar TEXT)',
				event => '_no_event',
			});
		},
		table_created => sub {
			$_[ARG0] = $_[ARG1]->[0];
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("create_in_memory_table");
				return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
			}
			pass("create_in_memory_table"); # 6
			$_[KERNEL]->post(db => insert => {
				table => 'test',
				insert => [
					{ id => 1, foo => 123456, bar => 'a quick brown fox' },
					{ id => 2, foo => 7891011, bar => time() },
				],
				event => '_no_event',
			});

			# old hash way, but still supported
			$_[KERNEL]->post(db => insert => {
				table => 'test2',
				hash => { id => 2, foo => 7891011, bar => time() },
				event => 'hash',
			});
		},
		hash => sub {
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("insert");
				return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
			}
			pass("insert"); # 7
			$_[KERNEL]->post(db => hash => {
				sql => 'SELECT * FROM test WHERE id=?',
				placeholders => [ 1 ],
				event => 'array',
			});
		},
		array => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (ref($_[ARG0]->{result}) eq 'HASH'
				&& $_[ARG0]->{result}->{foo} == 123456
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("hash");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("hash"); # 8
			$_[KERNEL]->post(db => array => {
				sql => 'SELECT foo FROM test',
				event => 'single',
			});
		},
		single => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (ref($_[ARG0]->{result}) eq 'ARRAY'
				&& !defined($_[ARG0]->{error}));

				if (defined($_[ARG0]->{error})) {
					diag("$_[ARG0]->{error}");
					fail("array");
					return $_[KERNEL]->call(test => shutdown => 'NOW');
				}
				pass("array"); # 9
				$_[KERNEL]->post(db => single => {
					sql => 'SELECT id FROM test WHERE id=1',
					event => 'db_do',
				});
		},
		db_do => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& $_[ARG0]->{result} == 1
				&& !defined($_[ARG0]->{error}));

			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("single");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("single"); # 10
			$_[KERNEL]->post(db => do => {
				sql => 'UPDATE test SET bar=? WHERE id=?',
				placeholders => [ '\'blah"', 2 ],
				# using a session id here is messing up
				event => 'update',
			});
		},
		update => sub {
			# should of updated 1 row
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& $_[ARG0]->{result} == 1
				&& !defined($_[ARG0]->{error}));

			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("do");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("do"); # 11
			$_[KERNEL]->post(db => quote => {
				# method => 'quote',
				sql => '\'blah"',
				# args => [ '\'blah"' ],
				event => 'keyvalhash',
			});
		},
		keyvalhash => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& $_[ARG0]->{result} eq '\'\\\'blah"\''
				&& !defined($_[ARG0]->{error}));

			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("quote");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("quote"); # 12
			$_[KERNEL]->post(db => keyvalhash => {
				sql => 'SELECT id,bar FROM test',
				event => 'hashhash',
			});
		},
		hashhash => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'HASH'
				&& $_[ARG0]->{result}->{2} eq '\'blah"'
				&& $_[ARG0]->{result}->{1} eq 'a quick brown fox'
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("keyvalhash");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("keyvalhash"); # 13
			$_[KERNEL]->post(db => hashhash => {
				sql => 'SELECT * FROM test',
				primary_key => 'id',
				event => 'arrayhash',
			});
		},
		arrayhash => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'HASH'
				&& $_[ARG0]->{result}->{2}->{bar} eq '\'blah"'
				&& $_[ARG0]->{result}->{1}->{bar} eq 'a quick brown fox'
				&& $_[ARG0]->{result}->{1}->{foo} eq '123456'
				&& $_[ARG0]->{result}->{2}->{foo} eq '7891011'
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("hashhash");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("hashhash"); # 14
			$_[KERNEL]->post(db => arrayhash => {
				sql => 'SELECT * FROM test ORDER BY id',
				event => 'arrayarray',
			});
		},
		arrayarray => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'ARRAY'
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("arrayhash");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			my @r = [
				{ id => 1, foo => 123456, bar => 'a quick brown fox' },
				{ id => 2, foo => 7891011, bar => '\'blah"'},
			];
			my $d = $_[ARG0]->{result};
			for my $i ( 0 .. $#{$r} ) {
				foreach my $k (keys %{$r->[$i]}) {
					unless ($r->[$i]->{$k} eq $d->[$i]->{$k}) {
						$_[ARG0]->{error} = "incorrect data in $i ($k)";
					}
				}
			}
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("arrayhash");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("arrayhash"); # 15
			$_[KERNEL]->post(db => arrayarray => {
				sql => 'SELECT * FROM test ORDER BY id',
				event => 'done',
			});
		},
		done => sub {
			$_[ARG0]->{error} = "incorrect result"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'ARRAY'
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("arrayarray");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass('arrayarray'); # 16
			$_[KERNEL]->post(test => 'shutdown');
		},
		shutdown => sub {
			$_[KERNEL]->alarm_remove_all();
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->call(db => 'shutdown' => $_[ARG0]);
		},
	},
);

POE::Kernel->run();

#########################
