use Test::More;

use lib 't/ODS';

use Table::User;

use ODS::Table::Generate::Data;

qx{/usr/bin/clear};

my $total = 29;

ODS::Table::Generate::Data->new(
	table_class => 'Table::User',
	table_class_type => 'Directory',
	table_class_connect => {
		directory => 't/filedb/directory/truth/test2',
		cache_directory => 't/filedb/directory/cache/test2',
		serialize_class => 'YAML'
	},
	total => $total
)->generate;

my $test = Table::User->connect('Directory', {
	directory => 't/filedb/directory/truth/test2',
	cache_directory => 't/filedb/directory/cache/test2',
	serialize_class => 'YAML'
});

my $data = $test->all();

is(scalar @{$data}, $total);

is($data->table->rows->[0]->id, 1);

my $reverse = $test->all(
	sort => "id",
	sort_direction => "desc"
);

is(scalar @{$reverse}, $total);

is($reverse->table->rows->[0]->id, $total);

$reverse = $reverse->sort(sub {
	$_[0]->id <=> $_[1]->id
});

is($reverse->table->rows->[0]->id, 1);

opendir(my $dh, 't/filedb/directory/cache/test2') || die "Can't opendir $directory: $!";
my @cfiles = sort { $a <=> $b } grep { $_ !~ m/^\.+$/ } readdir($dh);
closedir $dh;

for (@cfiles) {
	diag explain $_;
	unlink 't/filedb/directory/cache/test2/' . $_;
}

opendir(my $dh, 't/filedb/directory/truth/test2') || die "Can't opendir $directory: $!";
my @files = sort { $a <=> $b } grep { $_ !~ m/^\.+$/ } readdir($dh);
closedir $dh;

for (@files) {
	diag explain $_;
	unlink 't/filedb/directory/truth/test2/' . $_;
}

done_testing();
