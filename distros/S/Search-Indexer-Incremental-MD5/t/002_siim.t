
use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);
use Test::Command ;
use Test::Script::Run ;

use Search::Indexer::Incremental::MD5 ;

use File::Find::Rule ;
use FindBin;
use File::Slurp ;

{
local $Plan = {'completion_script' => 93} ;

my $generate_completion = "$^X -Mblib scripts/siim --completion_script";

exit_is_num($generate_completion, 0, 'completion script generation exit code ok');
stdout_like($generate_completion, qr/^_siim_bash_completion()/smx);

my %tree_structure =
	(
	index =>
		{
		stopwords =>['A B C'], # not clear from documentation what format it should have
		},
		
	index_no_access => {},
		
	'file.txt' => ['file_txt a b C'],
	'file.pl' => ['file_pl b c d for while'],
	'stopwords.txt' => ['a b C file_txt'],
	) ;
	
use Directory::Scratch::Structured qw(create_structured_tree) ;
my $siim_directory= create_structured_tree(%tree_structure) ;

my $source_completion = "$^X -Mblib scripts/siim --completion_script > $siim_directory/siim ; source $siim_directory/siim" ;
exit_is_num($source_completion, 0, 'completion script sourced properly');
	
for my $test_description
	(
		{
		NAME => 'no parameters, get help',
		EXIT_STATUS => 1,
		ARGUMENTS => '',
		STDOUT => qr~^$~,
		STDERR => qr/User Contributed Perl Documentation/
		},
		
		{
		NAME => 'adding a file to the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -a $siim_directory/file.txt",
		STDOUT => qr~^$siim_directory/file.txt$~,
		STDERR => qr/^$/
		},
		
		{
		NAME => 'adding the same file to the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -a $siim_directory/file.txt",
		STDOUT => qr~^$~,
		STDERR => qr/^$/
		},
		
		sub
		{
		write_file "$siim_directory/file.txt",  read_file("$siim_directory/file.txt"), '1' ;
		},
		
		{
		NAME => 're-index modified file',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -a $siim_directory/file.txt",
		STDOUT => qr~^$siim_directory/file.txt$~,
		STDERR => qr/^$/
		},
		
		{
		NAME => 'check re-indexed file modification are in the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -s 1",
		STDOUT => qr~^'$siim_directory/file.txt' \[id:2\] with score \d{2}.$~,
		STDERR => qr/^$/,
		#~ DIAG => 	sub {diag read_file("$siim_directory/file.txt") ;}
		},
		
		sub
		{
		write_file 
			"$siim_directory/file.txt",
			grep
				{
				! m/1/ # remove what we have added
				} split(/(\s)/, read_file("$siim_directory/file.txt")) ;
		},
		
		{
		NAME => 're-index modified file, verbose',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -a $siim_directory/file.txt",
		STDOUT => qr~^'$siim_directory/file.txt' \[id:3\] re-indexed in \d.\d{3} s.$~,
		STDERR => qr/^$/,
		#~ DIAG => 	sub {diag read_file("$siim_directory/file.txt") ;}
		},
		
		{
		NAME => 'check re-indexed file modification are in the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -s 1",
		STDOUT => qr~^$~,
		STDERR => qr/^$/
		},
		
		{
		NAME => 'adding second file to the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -a $siim_directory/file.pl",
		STDOUT => qr~^'$siim_directory/file.pl' \[id:4\] new file \d.\d{3} s.$~,
		STDERR => qr/^$/
		},
		
		{
		NAME => 'query matching no files',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -s something_not_in_the_index",
		STDOUT => qr~^$~,
		STDERR => qr/^$/
		},

		{
		NAME => 'query matching the firs file only',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -s a",
		STDOUT => qr~^'$siim_directory/file.txt' \[id:3\] with score \d{3}.$~,
		STDERR => qr/^$/
		},

		{
		NAME => 'query matching two file',
		EXIT_STATUS => 0, 
		ARGUMENTS => "-i $siim_directory/index -v -s b",
		STDOUT => qr~
		^
		'$siim_directory/file.txt'\ \[id:3\]\ with\ score\ \d{2}.\n
		'$siim_directory/file.pl'\ \[id:4\]\ with\ score\ \d{2}.
		~xsm,
		STDERR => qr/^$/,
		},
		
                {
                NAME => 'display database information',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/index -v --database_information",
                STDOUT => qr~
				^
				Location:\ $siim_directory/index\n
				Last\ updated\ on:\ .*\n
				Number\ of\ indexed\ documents:\ 2\n
				Database\ size:\ \d+\ bytes
		                $~xsm,
	        STDERR => qr/^$/,
                },
		
		{
		NAME => 'check database content',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -c",
		STDOUT => qr~^
				$siim_directory/file.pl\n
				$siim_directory/file.txt\n
				$~smx,
		STDERR => qr/^$/
		},
	 
		{
		NAME => 'remove document from database',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -r $siim_directory/file.pl",
		STDOUT => qr~^$siim_directory/file.pl$~smx,
		STDERR => qr/^$/,
		},
		
		{
		NAME => 'remove non existing document from database',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -r $siim_directory/non_existant_file.pl",
		STDOUT => qr~^$~smx,
		STDERR => qr/^$/,
		},
		
		{
		NAME => 'remove non existing document from database',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -r $siim_directory/stopwords.txt",
		STDOUT => qr~^$~smx,
		STDERR => qr/^$/,
		},
		
                {
                NAME => 'number of indexed document decreased',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/index --database_information",
                STDOUT => qr~Number\ of\ indexed\ documents:\ 1\n~,
	        STDERR => qr/^$/,
                },
		 
                {
                NAME => 'delete_database',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/index --delete_database",
                STDOUT => qr~~,
	        STDERR => qr/^$/,
                },
	 
		{
		NAME => 'new index in non existant directory',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/created_index -a $siim_directory/file.txt",
		STDOUT => qr~^$siim_directory/file.txt$~,
		STDERR => qr/^$/
		},
	
                {
                NAME => 'indexed document in new index',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/created_index --database_information",
                STDOUT => qr~Number\ of\ indexed\ documents:\ 1\n~,
	        STDERR => qr/^$/,
                },
		
		{
		NAME => 'adding two files to the index',
		EXIT_STATUS => 0,
		ARGUMENTS => "-i $siim_directory/index -v -a $siim_directory/file.txt $siim_directory/file.pl",
		STDOUT => qr~^
				'$siim_directory/file.pl'\ \[id:1\]\ new\ file\ \d.\d{3}\ s.\n
				'$siim_directory/file.txt'\ \[id:2\]\ new\ file\ \d.\d{3}\ s.
				$~smx,
		STDERR => qr/^$/
		},
	 
                {
                NAME => 'delete_database',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/index --delete_database",
                STDOUT => qr~~,
	        STDERR => qr/^$/,
                },
	 
		{
		NAME => 'limit file size and use stopwords',
		EXIT_STATUS => 0,
		ARGUMENTS => 
			"-i $siim_directory/index -v"
			. " --maximum_document_size=20 --stopwords_file=$siim_directory/stopwords.txt"
			. " -a $siim_directory/file.pl $siim_directory/file.txt",
		STDOUT => qr~^
				'$siim_directory/file.txt'\ \[id:1\]\ new\ file\ \d.\d{3}\ s.
				$~smx,
		STDERR => qr~'$siim_directory/file.pl'\ is\ bigger\ than\ 20\ bytes,\ skipping!~
		},
		
                {
                NAME => 'delete_database',
                EXIT_STATUS => 0,
                ARGUMENTS => "-i $siim_directory/index --delete_database",
                STDOUT => qr~~,
	        STDERR => qr/^$/,
                },
	 
		{
		NAME => 'perl mode',
		EXIT_STATUS => 0,
		ARGUMENTS => 
			"-i $siim_directory/index -v "
			. " --perl_mode --stopwords_file=$siim_directory/stopwords.txt"
			. " -a $siim_directory/file.pl $siim_directory/file.txt",
		STDOUT => qr~^
				'$siim_directory/file.pl'\ \[id:1\]\ new\ file\ \d.\d{3}\ s.\n
				'$siim_directory/file.txt'\ \[id:2\]\ new\ file\ \d.\d{3}\ s.
				$~smx,
		STDERR => qr~^$~
		},
	
		{
		NAME => 'stopwords_file overridden by perl_mode',
		EXIT_STATUS => 0, 
		ARGUMENTS => "-i $siim_directory/index -v -s file_txt",
		STDOUT => qr~
		^
		'$siim_directory/file.txt'\ \[id:2\]\ with\ score\ \d{3}.\n
		~xsm,
		STDERR => qr/^$/,
		},
		
		{
		NAME => 'perl_mode stopwords',
		EXIT_STATUS => 0, 
		ARGUMENTS => "-i $siim_directory/index -v -s while",
		STDOUT => qr~^$~,
		STDERR => qr/^$/,
		},
		
		{
		NAME => 'undefined index',
		EXIT_STATUS => 1, # we want a failure
		ARGUMENTS => "-c",
		STDOUT => qr~^$~,
		STDERR => qr/^Error: --index_directory \(short -i\) is required! Try --help for a complete help/
		},
		
		sub
		{
		chmod 0, "$siim_directory/index_no_access" ;
		},
		
		{
		NAME => 'fail creating index',
		EXIT_STATUS => 2,
		ARGUMENTS => "-i $siim_directory/index_no_access -a $siim_directory/file.txt",
		STDOUT => qr~^$~,
		STDERR => qr/^Error: opening/
		},
		
		{
		NAME => 'fail searching index',
		EXIT_STATUS => 2,
		ARGUMENTS => "-i $siim_directory/index_no_access -s xxx",
		STDOUT => qr~^$~,
		STDERR => qr/^No full text index found!/
		},
		
	)
	{
	run_siim_test($test_description) if ref $test_description eq 'HASH' ;
	$test_description->() if ref $test_description eq 'CODE' ;
	}
}

sub run_siim_test
{
my ($description) = @_ ;

my ($run3_status, $stdout, $stderr) = run_script("$FindBin::Bin/../scripts/siim",   [split /\s+/, $description->{ARGUMENTS}] );

my $exit_status ;

if ($? == -1) 
	{ diag "failed to execute: $!\n";}
elsif 
	($? & 127) { diag "child died with signal %d, %s coredump\n", ($? & 127),  ($? & 128) ? 'with' : 'without';}
else 
	{$exit_status =  $? >> 8;}
    
is($exit_status, $description->{EXIT_STATUS}, "exit status - $description->{NAME}") ;
like($stdout, $description->{STDOUT}, "stdout - $description->{NAME}") ;
like($stderr, $description->{STDERR}, "stderr - $description->{NAME}") ;

$description->{DIAG}->() if defined $description->{DIAG} ;

return ;
}




		
