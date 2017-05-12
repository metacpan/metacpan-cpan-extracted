#!/usr/bin/perl -w

# For bug: https://rt.cpan.org/NoAuth/Bug.html?id=2637

use lib "t";
use TestNeeds qw(Test::More Set::Object);

require "t/Capture.pm";
use strict;
use Test::More tests => 4;

use Tangram qw(:compat_quiet);
use Tangram::Relational;
use Tangram::Schema;
use Tangram::Scalar;
use Tangram::Ref;
use Tangram::IntrArray;

my @tests =
    ( "iarray (Control)" =>
      [
       NaturalPerson =>
       {
	fields => {
		 string   => [ qw( firstName name ) ],
		 int      => [ qw( age ) ],
		 ref      => { partner => { null => 1 } },
		 iarray    => { children => 'NaturalPerson' },
		},
       },
      ],
      "iarray (w/Package seperator)" =>
      [
       'Natural::Person' =>
       {
	fields => {
		   string   => [ qw( firstName name ) ],
		   int      => [ qw( age ) ],
		   ref      => { partner => { null => 1 } },
		   iarray    => { children => 'Natural::Person' },
		  },
       },
      ],
      "iarray (w/Package seperator, long form)" => 
      [
       'UnNatural::Person' =>
       {
	fields => {
		   string   => [ qw( firstName name ) ],
		   int      => [ qw( age ) ],
		   ref      => { partner => { null => 1 } },
		   iarray    => { children => {
					       class => 'UnNatural::Person',
					      }
				},
		  },
       },
      ],
      "iarray (w/Package seperator, long form + coll/slot)" =>
      [
       'Natural::Bloke' =>
       {
	fields => {
		   string   => [ qw( firstName name ) ],
		   int      => [ qw( age ) ],
		   ref      => { partner => { null => 1 } },
		   iarray    => { children => {
					       class => 'Natural::Bloke',
					       coll => "foo",
					       slot => "bar",
					      }
				},
		  },
       },
      ],
    );

while (my ($test_name, $test_classes) = splice @tests, 0, 2) {

    my $schema = Tangram::Schema->new
	(
	 classes => $test_classes,
	 normalize => sub {
	     my ($name, $type) = @_;
	     $name =~ s/\:\:/_/g;
	     return $name;
	 },
	);

    my $output = new Capture();
    $output->capture_print();
    Tangram::Relational->deploy($schema);
    my $result = $output->release_stdout();
    $result =~ s{INSERT INTO Tangram.*}{};
    unlike ($result, qr/::/, "Normalise applied - $test_name");
}


