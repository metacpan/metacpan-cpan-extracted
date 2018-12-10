#! perl

use Test2::V0;
use Test::Script;

use Path::Tiny;
use Env qw[ @PERL5LIB ];

subtest "synopsis" => sub {
    my $dir    = path( qw[ examples synopsis ] );
    my $script = $dir->child( 'script.pl' );
    script_runs( "$script", { interpreter_options => ["-I$dir"] }, $script );
};

subtest "description" => sub {
    my $dir = path( qw[ examples description ] );
    script_runs(
	'true',
	{
	    interpreter_options =>
	      [ "-I$dir", '-MC1', '-E', 'say C1->new->_tags->{t1}{c1}' ]
	},
	"C1"
    );
    script_stdout_is( "foo\n" );

    script_runs(
	'true',
	{
	    interpreter_options =>
	      [ "-I$dir", '-MC2', '-E', 'say C2->new->_tags->{t2}{c2}' ]
	},
	"C2"
    );
    script_stdout_is( "bar\n" );
};

subtest "accessing" => sub {
    my $dir = path( qw[ examples accessing ] );

    subtest "C->new" => sub {
	script_runs(
	    'true',
	    {
		interpreter_options =>
		  [ "-I$dir", '-MC', '-E', 'say C->new->_tags->{t1}{a}' ]
	    },
	    "C"
	);
	script_stdout_is( "2\n" );

	script_runs(
	    'true',
	    {
		interpreter_options =>
		  [ "-I$dir", '-MC', '-E', 'say C->new->_tags->{t2}{b}' ]
	    },
	    "C"
	);
	script_stdout_is( "foo\n" );
    };

    subtest "C" => sub {
	script_runs(
	    'true',
	    {
		interpreter_options =>
		  [ "-I$dir", '-MC', '-E', 'say C->_tags->{t1}{a}' ]
	    },
	    "C"
	);
	script_stdout_is( "2\n" );

	script_runs(
	    'true',
	    {
		interpreter_options =>
		  [ "-I$dir", '-MC', '-E', 'say C->_tags->{t2}{b}' ]
	    },
	    "C"
	);
	script_stdout_is( "foo\n" );
    };

};

done_testing;
