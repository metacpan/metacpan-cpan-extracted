# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use Term::Bash::Completion::Generator ;
use Text::Diff ;

{
local $Plan = {'generate_bash_completion_function' => 5} ;

my $expected_perl_script = <<'EOF' ;
#! /usr/bin/perl

=pod

B<source> the following line in your I<~/.bashrc>:

B<complete> -o default -C perl_completion_script my_command

Replace I<perl_completion_script> with the name you saved the script under. The script has to
be executable and somewhere in the path.

The script will receive these arguments from bash:

@ARGV
|- 0 = command
|- 1 = word_to_complete
`- 2 = word_before_the_word_to_complete

You return possible completion you want separated by I<\n>. Return nothing if you
want the default bash completion to be run which is possible because of the <-o defaul>
passed to the B<complete> command.

Note! You may have to re-run the B<complete> command after you modify your perl script.

=cut

use strict;
use Tree::Trie;

my @completions =
	qw(
	--aeode
	--calliope
	--clio
	--erato
	--euterpe
	--melete
	--melpomene
	--mneme
	--polymnia
	--terpsichore
	--thalia
	--urania
	) ;

my($trie) = new Tree::Trie;
$trie->add(@completions) ;

if(defined $ARGV[1])
	{
	if(substr($ARGV[1], 0, 1) eq '-')
		{
		print join("\n", $trie->lookup($ARGV[1])) ;
		}
	}
else
	{
	print join("\n", $trie->lookup('')) ;
	}
EOF

my ($bash_command, $perl_script) = 
	Term::Bash::Completion::Generator::generate_perl_completion_script('my_command') ;

is($bash_command, 'complete -o default -C perl_completion_script my_command', 'generated command matches') ;
is($perl_script, $expected_perl_script, 'generated script matches')  ;
	#~ or diag (diff(\$perl_script, \$expected_perl_script)) ; 




my $expected_perl_script2 = <<'EOF' ;
#! /usr/bin/perl

=pod

B<source> the following line in your I<~/.bashrc>:

B<complete> -o default -C perl_completion_script my_command2

Replace I<perl_completion_script> with the name you saved the script under. The script has to
be executable and somewhere in the path.

The script will receive these arguments from bash:

@ARGV
|- 0 = command
|- 1 = word_to_complete
`- 2 = word_before_the_word_to_complete

You return possible completion you want separated by I<\n>. Return nothing if you
want the default bash completion to be run which is possible because of the <-o defaul>
passed to the B<complete> command.

Note! You may have to re-run the B<complete> command after you modify your perl script.

=cut

use strict;
use Tree::Trie;

my @completions =
	qw(
	-j
	--jobs
	-d
	--display_documentation
	-o
	) ;

my($trie) = new Tree::Trie;
$trie->add(@completions) ;

if(defined $ARGV[1])
	{
	if(substr($ARGV[1], 0, 1) eq '-')
		{
		print join("\n", $trie->lookup($ARGV[1])) ;
		}
	}
else
	{
	print join("\n", $trie->lookup('')) ;
	}
EOF

my ($bash_command2, $perl_script2) = 
	Term::Bash::Completion::Generator::generate_perl_completion_script
		(
		'my_command2',
		['j|jobs=i', 'd|display_documentation:s', 'o'],
		) ;

is($bash_command2, 'complete -o default -C perl_completion_script my_command2', 'generated command matches') ;

is($perl_script2, $expected_perl_script2, 'generated script matches') ;
	#~ or diag (diff(\$perl_script2, \$expected_perl_script2)) ; 

throws_ok
	{
	Term::Bash::Completion::Generator::generate_perl_completion_script() ;
	}
	qr/Argument "\$command" not defined/, 'command needed' ;
}


{
local $Plan = {'generate_bash_completion_function' => 4} ;

my $completion_function = 
	Term::Bash::Completion::Generator::generate_bash_completion_function
		(
		'my_command',
		[qw( a bb ccc)],
		) ;

is($completion_function, <<'EOF', 'generated function matches') ;
_my_command_bash_completion()
{
	local cur

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	if [[ "$cur" == -* ]]; then
		COMPREPLY=( $( compgen -W '\
			-a --a \
			-bb --bb \
			-ccc --ccc \
			' -- $cur ) )
	fi

	return 0
}

complete -F _my_command_bash_completion -o default my_command
EOF

my $completion_function2 = 
	Term::Bash::Completion::Generator::generate_bash_completion_function
		(
		'my_command',
		['j|jobs=i', 'd|display_documentation:s', 'o'],
		) ;

is($completion_function2, <<'EOF', 'getopt argv options') ;
_my_command_bash_completion()
{
	local cur

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	if [[ "$cur" == -* ]]; then
		COMPREPLY=( $( compgen -W '\
			-j --j \
			-jobs --jobs \
			-d --d \
			-display_documentation --display_documentation \
			-o --o \
			' -- $cur ) )
	fi

	return 0
}

complete -F _my_command_bash_completion -o default my_command
EOF

my $completion_function3 = 
	Term::Bash::Completion::Generator::generate_bash_completion_function
		(
		'my_command',
		['j|jobs=i', 'd|display_documentation:s', 'o'],
		'COMPLETION_PREFIX',
		0, # single_and_double_dash
		'COMPLETE_OPTIONS'
		) ;

is($completion_function3, <<'EOF', 'generation options') ;
_my_command_bash_completion()
{
	local cur

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	if [[ "$cur" == COMPLETION_PREFIX ]]; then
		COMPREPLY=( $( compgen -W '\
			-j \
			--jobs \
			-d \
			--display_documentation \
			-o \
			' -- $cur ) )
	fi

	return 0
}

complete -F _my_command_bash_completion COMPLETE_OPTIONS my_command
EOF

throws_ok
	{
	Term::Bash::Completion::Generator::generate_bash_completion_function() ;
	}
	qr/Argument "\$command" not defined/, 'command needed' ;
	
=pod

the completion is accepted by source
the completion works

=cut
}
