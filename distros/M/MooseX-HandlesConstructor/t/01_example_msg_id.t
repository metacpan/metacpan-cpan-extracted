use strict;
use warnings;

use Test::Most tests => 2;

use lib 't/lib';
use Module::Load;

# 2 classes
for my $class (qw(ExampleMoo ExampleMoose)) {
	SKIP: {
		eval { load $class };

		skip "Not testing $class", 1 if $@;

		subtest "Testing class $class", sub {
			my $ex = $class->new;
			$ex->msg_type( 'reply' );
			ok( $ex->header->{msg_type} eq 'reply' );
			ok( $ex->msg_type eq 'reply' );

			my $ex_handle_constructor = $class->new( msg_type => 'reply', header => { answer => 42 }  );
			ok( $ex_handle_constructor->header->{msg_type} eq 'reply' );
			ok( $ex_handle_constructor->msg_type eq 'reply' );
			ok( $ex_handle_constructor->header->{answer} == 42 );
		};
	};
}

done_testing;
