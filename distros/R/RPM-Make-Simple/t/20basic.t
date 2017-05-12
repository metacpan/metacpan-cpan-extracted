use Test::More 'no_plan';
use RPM::Make::Simple;

# define some important build data
my $rpm = RPM::Make::Simple->new(
				name			=> 'Example', #mandatory
				arch			=> 'i386', # mandatory
				version			=> '0.01',
				release			=> '1',
				build_root		=> './build',
				temp_build_loc	=> 'temp_build_loc');

isa_ok($rpm,'RPM::Make::Simple');

# 'From_File' => 'To_File_or_Dir'
$rpm->Files(	'./example/scripts/example.pl'	=> '/var/example/example.pl',
				'./example/docs/example.txt'	=> '/var/example/example.txt',
				'./example/config/example.conf'	=> '/var/example/example.conf',
				'./example/config/example.ini'	=> '/var/example/example.ini',
			);

my @test = (	'./build/var/example/example.conf',
				'./build/var/example/example.ini',
				'./build/var/example/example.pl',
				'./build/var/example/example.txt'	);
my @files = sort glob('./build/var/example/*');
is_deeply(\@test,\@files);


# tell RPM::Make this is a document (optional)
$rpm->Doc('/var/example/example.txt');

# this is a config file (optional)
$rpm->Conf('/var/example/example.conf');

# config file we don't want to replace if it's there (optional)
$rpm->ConfNoReplace('/var/example/example.ini');

# Some pre-requisites
$rpm->Requires('perl(RPM::Make)' => 0.9);
 
# Some more metadata, summary, post installation etc.
$rpm->MetaData(	'summary'		=> 'package for blah blah',
				'description'	=> 'longer than the summary',
				'post'			=> $post_install_script,
				'AutoReqProv'	=> 'no',
				'vendor'		=> 'Bob Co.',
				'group'			=> 'Bob RPMS');
 
# build the RPM! woo!
eval { $rpm->Build(); };
my $log = $@;

ok(-d './build' ? 1 : 0);

# clean up the temporary files
$rpm->Clean();

ok(-d './build' ? 0 : 1);
ok(-f 'Example-0.01-1.i386.rpm' ? 1 : 0);

my $info = `rpm -q -i -p Example-0.01-1.i386.rpm`;
like($info,qr/Name        : Example/);
like($info,qr/Version     : 0.01/);
like($info,qr/Release     : 1/);
like($info,qr/Group       : Bob RPMS/);
like($info,qr/Size        : 20/);
like($info,qr/Summary     : package for blah blah/);
like($info,qr/Description :\nlonger than the summary/);
like($info,qr/Vendor: Bob Co./);
like($info,qr/Source RPM: Example-0.01-1.src.rpm/);

my $info = `rpm -q -l -p Example-0.01-1.i386.rpm`;
like($info,qr!/var/example/example.conf
/var/example/example.ini
/var/example/example.pl
/var/example/example.txt!);

END {
	unlink 'Example-0.01-1.i386.rpm';
}
