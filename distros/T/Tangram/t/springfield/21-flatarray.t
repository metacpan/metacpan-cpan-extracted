#  -*- perl -*- ergo sum


use strict;
use lib 't/springfield';
use Springfield;

use Test::More tests => 24;

{
	my $storage = Springfield::connect_empty();

	my $homer = NaturalPerson->new( firstName => 'Homer',
									name => 'Simpson',
									interests => [ qw( beer food ) ] );

	$storage->insert($homer);

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	is("@{ $homer->{interests} }", 'beer food',
	   "Flat array store/retrieve");

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	push @{ $homer->{interests} }, 'sex';
	$storage->update($homer);

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	is("@{ $homer->{interests} }", 'beer food sex',
	   "Array change flushed successfully");

	pop @{ $homer->{interests} };
	$storage->update($homer);

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	is("@{ $homer->{interests} }", 'beer food',
	   "Array change flushed again successfully");

	unshift @{ $homer->{interests} }, 'sex';
	$storage->update($homer);

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	is("@{ $homer->{interests} }", 'sex beer food',
	   "Array change flushed yet again successfully");

	delete $homer->{interests};
	$storage->update($homer);

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	is("@{ $homer->{interests} }", '',
	   "Removing array flushes from DB");

	$homer->{interests} = [ qw( beer food ) ];
	$storage->update($homer);

	$storage->insert(
        NaturalPerson->new(
            firstName => 'Marge',
			name => 'Simpson',
			interests => [ qw( kids household cooking cleaning ) ] ) );

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

# exists, includes

{
	my $storage = Springfield::connect();

	my ($remote) = $storage->remote('NaturalPerson');
	my @results = $storage->select($remote, $remote->{interests}->includes('beer'));
	is(@results, 1, "Got back one result only");
	is($results[0]->{firstName}, 'Homer', "Select by array entry");

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

{
    SKIP: {

	my $storage = Springfield::connect();

	    $storage->disconnect, skip "Sub-select tests disabled", 2,
		if $storage->{no_subselects};

	    my ($remote) = $storage->remote('NaturalPerson');
	    my @results = $storage->select($remote, $remote->{interests}->exists('beer'));
	    is(@results, 1, "I'll wash all the dishes,");
	    is($results[0]->{firstName}, 'Homer', "And you go have a beer");
	    $storage->disconnect();
	}
}


is(leaked, 0, "Nothing leaked");

# prefetch

{
	my $storage = Springfield::connect();

	my ($remote) = $storage->remote('NaturalPerson');
	$storage->prefetch($remote, 'interests');
	my ($homer) = $storage->select($remote, $remote->{firstName} eq 'Homer');

	{
		local ($storage->{db});
		is("@{ $homer->{interests} }", 'beer food',
		   "Prefetch test - no prefetch filter");
	}

	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked - here 1");

{
	my $storage = Springfield::connect();

	my ($remote) = $storage->remote('NaturalPerson');
	$storage->prefetch($remote, 'interests', $remote->{firstName} eq 'Homer');

	my ($homer) = $storage->select($remote, $remote->{firstName} eq 'Homer');

	{
		local ($storage->{db});
		is("@{ $homer->{interests} }", 'beer food',
		   "Another prefetch test - prefetch filter"
		  );
	}

	$storage->disconnect();
}

THEEND:

is(leaked, 0, "Nothing leaked - here 2");


{
	my $storage = Springfield::connect();
	$storage->erase( $storage->select('NaturalPerson'));
	$storage->disconnect();
	$storage = Springfield::connect();
	is( $storage->connection()->selectall_arrayref("SELECT COUNT(*) FROM NaturalPerson_interests")->[0][0], 0, "All interests cleaned up correctly" );
	$storage->disconnect();
}

is(leaked, 0, "Nothing leaked");

