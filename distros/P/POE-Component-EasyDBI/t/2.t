# -*- perl -*-
# Before `Build install' is performed this script should be runnable with
# `Build test'. After `Build install' it should work as `perl 1.t'
# vim: syntax=perl ts=4
#########################

use Test::More tests => 18;
#use Carp;
#$SIG{__WARN__} = \&Carp::cluck;

use Test::Requires 'DBD::SQLite';

BEGIN {
	use_ok('POE'); # 1
	use_ok('POE::Component::EasyDBI'); # 2
	use_ok('POE::Component::EasyDBI::SubProcess'); # 3
};

POE::Session->create(
	# options => { trace => 1},
	inline_states => {
		_start => sub {
			$_[KERNEL]->alias_set('test');
			eval "use Time::Stopwatch";
			POE::Component::EasyDBI->spawn(
				alias => 'db',
				dsn => 'dbi:SQLite:dbname=',
				no_cache => 1, # don't use cached queries with DBD::AnyData
				username => '',
				password => '',
				connected => [ $_[SESSION]->ID, 'connected' ],
				connect_error => [ $_[SESSION]->ID, 'error' ],
				# alt_fork => 1,
				stopwatch => ($@) ? 0 : 1,
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
			$_[KERNEL]->post(db => do => {
				begin_work => 1,
				sql => 'CREATE TABLE test (id INT, foo TEXT, bar TEXT)',
				commit => 1,
				# event => $_[SESSION]->postback('table_created'),
				event => 'table_created',
			});
		},
		table_created => sub {
			$_[ARG0] = $_[ARG1]->[0];
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("create_in_memory_table");
				return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
			}
			# TODO check if table exists?
			pass("create_in_memory_table"); # 6
			$_[KERNEL]->post(db => combo => {
				queries => [
					{
						insert => {
							table => 'test',
							insert => [
								{ id => 1, foo => 123456, bar => 'a quick brown fox' },
								{ id => 2, foo => 7891011, bar => time() },
							],
						},
					},
					{
						insert => {
							table => 'test',
							hash => { id => 2, foo => 7891011, bar => time() },
						},
					},
				],
				event => 'hash',
			});
		},
		hash => sub {
			$_[ARG1]->{error} = "incorrect result:insert = $_[ARG1]->{result}"
				unless (!ref($_[ARG1]->{result})
				&& $_[ARG1]->{result} == 1
				&& !defined($_[ARG1]->{error}));
			if (defined($_[ARG1]->{error})) {
				diag("$_[ARG1]->{error}");
				fail("insert");
				return $_[KERNEL]->call($_[SESSION] => shutdown => 'NOW');
			}
			diag("Query took $_[ARG1]->{stopwatch} seconds to complete") if (exists($_[ARG1]->{stopwatch}));
			pass("insert"); # 7
			$_[KERNEL]->post(db => hash => {
				sql => 'SELECT * FROM test WHERE id=?',
				placeholders => [ 1 ],
				event => 'array',
			});
		},
		array => sub {
			$_[ARG0]->{error} = "incorrect result:hash"
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
			$_[ARG0]->{error} = "incorrect result:array"
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
			$_[ARG0]->{error} = "incorrect result:single"
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
				begin_work => 1,
				sql => 'UPDATE test SET bar=? WHERE id=?',
				placeholders => [ '\'%blah"', 2 ],
				# using a session id here is messing up?
				event => 'update',
			});
		},
		update => sub {
			# should of updated 2 rows
			$_[ARG0]->{error} = "incorrect result:do = $_[0]->{result}"
				unless (defined($_[ARG0]->{result})
				&& $_[ARG0]->{result} == 2
				&& !defined($_[ARG0]->{error}));

			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("do");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("do"); # 11
			$_[KERNEL]->post(db => commit => {
				event => 'commit',
			});
		},
		commit => sub {
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("commit");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass("commit"); # 12
#			$_[KERNEL]->post(db => quote => {
#				method => 'quote',
#				sql => '\'%blah"',
#				args => [ '\'%blah"' ],
#				event => 'keyvalhash',
#			});
#		},
#		keyvalhash => sub {
#			$_[ARG0]->{error} = "incorrect result:quote == $_[ARG0]->{result}"
#				unless (defined($_[ARG0]->{result})
#				&& $_[ARG0]->{result} eq '\'\\\'%blah"\''
#				&& !defined($_[ARG0]->{error}));
#
#			if (defined($_[ARG0]->{error})) {
#				diag("$_[ARG0]->{error}");
#				fail("quote");
#				return $_[KERNEL]->call(test => shutdown => 'NOW');
#			}
#			pass("quote"); # 12
			$_[KERNEL]->post(db => keyvalhash => {
				sql => 'SELECT id,bar FROM test',
				event => 'hashhash',
			});
		},
		hashhash => sub {
			$_[ARG0]->{error} = "incorrect result:keyvalhash"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'HASH'
				&& $_[ARG0]->{result}->{2} eq '\'%blah"'
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
			$_[ARG0]->{error} = "incorrect result:hashhash"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'HASH'
				&& $_[ARG0]->{result}->{2}->{bar} eq '\'%blah"'
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
			$_[ARG0]->{error} = "incorrect result:arrayhash"
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
				{ id => 2, foo => 7891011, bar => '\'%blah"'},
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
			warn "\nYou should see an error next, this is intended\n";
			$_[KERNEL]->post(db => do => {
				sql => 'PDATE TEST SET bar=2',
				event => 'cause_error',
			});
		},
		cause_error => sub {
			diag($_[ARG0]->{error}) if ($_[ARG0]->{error});
			if (!defined($_[ARG0]->{error})) {
				fail("cause_error");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass('cause_error'); # 16
			$_[KERNEL]->post(db => arrayarray => {
				sql => 'SELECT * FROM test ORDER BY id',
				event => 'done',
			});
		},
		done => sub {
			$_[ARG0]->{error} = "incorrect result:arrayarray"
				unless (defined($_[ARG0]->{result})
				&& ref($_[ARG0]->{result}) eq 'ARRAY'
				&& !defined($_[ARG0]->{error}));
			if (defined($_[ARG0]->{error})) {
				diag("$_[ARG0]->{error}");
				fail("arrayarray");
				return $_[KERNEL]->call(test => shutdown => 'NOW');
			}
			pass('arrayarray'); # 17
			$_[KERNEL]->post(db => do => {
				sql => 'UPDATE test SET id=0',
				event => sub {
					#warn $_[0]->{rows};
					pass('eventcode'); # 18
					diag("Query affected ".$_[0]->{rows}." rows");
					$poe_kernel->post(test => 'shutdown');
				},
			});
		},
		shutdown => sub {
			$_[KERNEL]->alarm_remove_all();
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->call(db => 'shutdown' => $_[ARG0]);
			return;
		},
	},
);

POE::Kernel->run();

#########################
