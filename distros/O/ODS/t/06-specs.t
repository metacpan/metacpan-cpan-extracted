use Test::More;

use lib 't/ODS';

use Table::Spec;

qx{/usr/bin/clear};

my $test = Table::Spec->connect('Directory', {
	directory => 't/filedb/directory/truth/test2',
	cache_directory => 't/filedb/directory/cache/test2',
	serialize_class => 'YAML'
});

my $spec = $test->create({
	__custom_file_name => 'height.yml',
	__serialize => 1,
	disallowed => [
		{
			a => 1,
			b => 2
		},
		{
			a => 3,
			b => 4,
			c => 5
		}
	]
})->rows->[0];

my $spec2 = $test->create({
	__custom_file_name => 'width.yml',
	__serialize => 1,
	allowed => [
		qw/1 2 3/
	]
})->rows->[-1];

$spec = $test->create({
	__custom_file_name => 'height.yml',
	__serialize => 1,
	kaput => 'abc',
	allowed => [
		1, 2, 3
	],
	disallowed => [
		{
			a => 1,
			b => 2
		},
		{
			a => 3,
			b => 4,
			c => 5
		}
	],
	other => {
		a => {
			b => 2
		},
		c => 3
	},
	hashref => {
		1 => 'okay',
		2 => 'not okay',
	}
})->rows->[-1];

ok( $spec->kaput("Update The Name") );

ok( $spec->update() );

my $test2 = Table::Spec->connect('Directory', {
	directory => 't/filedb/directory/truth/test2',
	cache_directory => 't/filedb/directory/cache/test2',
	serialize_class => 'JSON'
});

$spec2 = $test2->create({
	__custom_file_name => 'width.yml',
	__serialize => 1,
	kaput => 'abc',
	allowed => [
		1, 2, 3
	],
	other => {
		a => {
			b => 2
		},
		c => 3
	},
	hashref => {
		1 => 'okay',
		2 => 'not okay',
	}
})->rows->[-1];

ok( $spec2->kaput("Update The Name") );

ok( $spec2->update() );

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
