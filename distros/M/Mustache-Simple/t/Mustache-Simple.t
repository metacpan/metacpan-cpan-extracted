# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mustache-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use 5.10.0;

use YAML::XS qw(LoadFile);
use Data::Dumper;
$Data::Dumper::Deparse = 1;


use experimental qw{smartmatch};

use Test::More; # tests => 1;
BEGIN { use_ok('Mustache::Simple') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @tests;
push @tests, LoadFile($_) foreach (glob 't/specs/*.yml');

# print STDERR Dumper @tests;

my @skip = (
    'Indented Inline',
    'Standalone Without Newline',
    'Standalone Without Previous Line',
    qr{Decimal},
    'Internal Whitespace',
    'Indented Inline Sections',
    'Standalone Line Endings',
    'Standalone Indentation',
    'Standalone Indented Lines',

);


my $count = 1;
foreach my $yaml (@tests)
{
    foreach my $test (@{$yaml->{tests}})
    {
#        next unless ++$count == 120;
#	say STDERR "Test: $test->{name}";
	SKIP: {
	    foreach (@skip)
	    {
		skip $test->{name}, 1 if $test->{name} ~~ $_;
	    }
	    eval {
		my $mustache = new Mustache::Simple(
		    partial => sub {
			my $partial = shift;
			return $test->{partials}{$partial};
		    },
		);
		my $context = $test->{data};
		if (exists $context->{lambda}{perl})
                {
                    my $sub = $context->{lambda}{perl};
                    $context->{lambda} = sub {
                        #    say "IN SUB: \@_ = @_";
                        eval "$sub->(\@_);"
                    };
                }
		my $result = $mustache->render($test->{template}, $context);
		is($result, $test->{expected}, $test->{desc});
	    };
	    fail($test->{name} . ": $@") if $@;
	}
    }
}

done_testing();

