
use lib 'lib', '../lib' ;
use Term::Shell::MultiCmd;
my $cli = Term::Shell::MultiCmd->new();

$cli -> populate ('feature' => "Optional title for prefix 'feature'",
                  'feature run' =>
                  { help => "This is help message for 'feature run'.
It has few lines documentation, but
the top one would be used as title",
                    comp => \&feature_run_completion,
                    exec => \&feature_run,
                    opts => 'force repeat=i',
                  },
                  # 'feature set' => 'title ', <-- you don't HAVE to declare a prefix
                  'feature set verbose' =>
                  { help => 'Set logs level
Options:
 -file <filename> : print log to <filename> instead of STDOUT
 -level <number>  : set log level to <number>
',
                    # opts => "level=o file=s", # This would have set those options with
                    # 'built in' completion

                    opts => ['level=o', [1, 2, 3], # For example:
                             # shell> feature set v -level <tab>
                             # would show 1, 2, 3 as possible completions

                             'file=s', sub { # a completion subroutine
                                 my($o, $word, $line, $start) = @_;
                                 # do whatever you want, but return
                                 # list of completion words
                                 ('file1', 'file2', 'file3' )
                             } ],
                    exec => sub {
                        my ($o, %p) = @_ ;
                        printf "'feature set verbose' was called. level=%i file='%s'\n",
                          $p{level} || 0, $p{file} || '' ;
                    },
                  },
                 ) ;
print "\n Try the command 'feature run -f -r 3 with a list of parameters'\n" ;
$cli -> loop ;
print "Bye, see you later\n" ;

sub feature_run_completion {
    my ($o, $word, $line, $start, $op) = @_ ;
    # $o is the Term::Shell::MultiCmd object.
    # $word is the curent word
    # $line is the whole line
    # $start is the current location
    # $op is the last option (if present). Like in 'mycmd -opt '
    return grep /^\Q$word/, qw/list of words that might be a legal completion to this command/
}

sub feature_run {
    my ($o, %p) = @_ ;
    print "Running this command, the value of \%p is:\n" ;
    use Data::Dumper ;
    print Dumper \%p ;
    print "\n(Have you tried the tab completion?) \n" ;
}


