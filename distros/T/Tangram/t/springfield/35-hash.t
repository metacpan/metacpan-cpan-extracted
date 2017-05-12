#  -*- perl -*-


use strict;
use lib 't/springfield';
use Springfield;
use Test::More tests => 4;

use vars qw( $intrusive );

my $opinions = $intrusive ? 'ih_opinions' : 'h_opinions';
(my $other = $opinions) =~ s{^(i)?}{($1 ? "" : "i")}e;

#$Tangram::TRACE = \*STDOUT;

sub graph {
    my $homer =
    NaturalPerson->new( firstName => 'Homer',
			name => 'Simpson',
			$opinions =>
			{ work => Opinion->new(statement => 'bad'),
			  food => Opinion->new(statement => 'good'),
			  beer => Opinion->new(statement => 'better') },
			# this is for is_deeply...
			$other => undef,
		      );
}

{
	my $storage = Springfield::connect_empty();

	my $homer = graph();

	$storage->insert($homer);

	$storage->disconnect();
}

is(leaked, 0, "leaktest");

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	# Test::More can be awfully pedantic at times :)
	my $homer_eg = graph();
	my $opinions_h = $homer_eg->{$opinions};

	my $ih_parent;
	if ($intrusive) {
	    $ih_parent = $homer_eg;
	}
	while (my($k,$v)= each %$opinions_h) {
	    $v->{ih_parent} = $ih_parent;
	}

	is_deeply([ sort keys %{ $homer->{$opinions}} ],
		  [ sort keys %{$opinions_h} ],
		  "Hash returned intact");
	is_deeply([ sort map { $_->{statement} } values %{ $homer->{$opinions}} ],
		  [ sort map { $_->{statement} } values %{ $opinions_h } ],
		  "Hash returned intact");

	# smash circular references...
	while (my($k,$v)= each %$opinions_h) {
	    $v->{ih_parent} = undef;
	}

	$storage->disconnect();
}

is(leaked, 0, "leaktest");
