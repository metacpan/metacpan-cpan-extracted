#!/usr/bin/perl
#
# This file is part of POE-Component-SimpleDBI
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use POE;
use POE::Component::SimpleDBI;

# Create a new session with the alias we want
POE::Component::SimpleDBI->new( 'SimpleDBI' ) or die 'Unable to create the DBI session';

# Create our own session to communicate with SimpleDBI
POE::Session->create(
	inline_states => {
		_start => sub {
			# Tell SimpleDBI to connect
			$_[KERNEL]->post( 'SimpleDBI', 'CONNECT',
				'DSN'		=>	'DBI:mysql:database=foobaz;host=192.168.1.100;port=3306',
				'USERNAME'	=>	'FooBar',
				'PASSWORD'	=>	'SecretPassword',
				'EVENT'		=>	'conn_handler',
			);

			# Execute a query and return number of rows affected
			$_[KERNEL]->post( 'SimpleDBI', 'DO',
				'SQL'		=>	'DELETE FROM FooTable WHERE ID = ?',
				'PLACEHOLDERS'	=>	[ 38 ],
				'EVENT'		=>	'deleted_handler',
			);

			# Retrieve one row of information
			$_[KERNEL]->post( 'SimpleDBI', 'SINGLE',
				'SQL'		=>	'Select * from FooTable LIMIT 1',
				'EVENT'		=>	'success_handler',
				'BAGGAGE'	=>	'Some Stuff I want to keep!',
			);

			# We want many rows of information + get the query ID so we can delete it later
			my $id = $_[KERNEL]->call( 'SimpleDBI', 'MULTIPLE',
				'SQL'		=>	'SELECT foo, baz FROM FooTable2 WHERE id = ?',
				'PLACEHOLDERS'	=>	[ 53 ],
				'EVENT'		=>	'multiple_handler',
				'PREPARE_CACHED'=>	0,
			);

			# Quote something and send it to another session
			$_[KERNEL]->post( 'SimpleDBI', 'QUOTE',
				'SQL'		=>	'foo$*@%%sdkf"""',
				'SESSION'	=>	'OtherSession',
				'EVENT'		=>	'quote_handler',
			);

			# Changed our mind!
			$_[KERNEL]->post( 'SimpleDBI', 'Delete_Query', $id );

			# 3 ways to shutdown

			# This will let the existing queries finish, then shutdown
			$_[KERNEL]->post( 'SimpleDBI', 'shutdown' );

			# This will terminate when the event traverses
			# POE's queue and arrives at SimpleDBI
			#$_[KERNEL]->post( 'SimpleDBI', 'shutdown', 'NOW' );

			# Even QUICKER shutdown :)
			#$_[KERNEL]->call( 'SimpleDBI', 'shutdown', 'NOW' );
		},

		# Define your request handlers here
		'quote_handler'	=>	\&FooHandler,
		# And so on
	},
);

# Run POE!
POE::Kernel->run();
exit;
