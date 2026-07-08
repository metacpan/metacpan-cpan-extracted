#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception; # throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $tmp = File::Temp->new(SUFFIX => '.tsv', UNLINK => 1);
print {$tmp} "# PDB\tscore\n1\t10\n2\t20\n3\t30\n";
close $tmp;

#--------
# filter by commented header name, as written in the file
#--------
my $rows = read_table("$tmp", filter => { '# PDB' => sub { $_ == 2 } });
is(scalar(@$rows), 1, 'filter on "# PDB" keeps one row');
is($rows->[0]{score}, 20, 'correct row survived the filter');
is($rows->[0]{PDB}, 2, 'commented header stored under the clean name "PDB"');

my $rows2 = read_table("$tmp", filter => { PDB => sub { $_ == 2 } });
is(scalar(@$rows2), 1, 'filter on the stripped name "PDB" also works');

throws_ok { read_table("$tmp", filter => { nope => sub { 1 } }) }
	qr/Filter column 'nope' not found/,
	'unknown filter column dies';

no_leaks_ok {
	eval {
		read_table("$tmp", filter => { '# PDB' => sub { $_ == 2 } })
	}
} 'read_table(filter): no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
