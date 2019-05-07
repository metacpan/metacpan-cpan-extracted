use Test::Script 1.10 tests => 14;

script_compiles('bin/mcp');
script_compiles('bin/mcp-dump');

script_runs( [ 'bin/mcp', 1, 'examples/questions/binary_choice.yml' ],
               'run-with-binary');
script_stdout_like   ( '\S+', 'binary-stdout-something' );
script_stderr_unlike ( '\S+', 'binary-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/mixed_choice.yml' ],
               'run-with-mixed');
script_stdout_like   ( '\S+', 'mixed-stdout-something' );
script_stderr_unlike ( '\S+', 'mixed-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/multiple_choice.yml' ],
               'run-with-multiple');
script_stdout_like   ( '\S+', 'multiple-stdout-something' );
script_stderr_unlike ( '\S+', 'multiple-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/similar_choices.yml' ],
               'run-with-similar');
script_stdout_like   ( '\S+', 'similar-stdout-something' );
script_stderr_unlike ( '\S+', 'similar-stderr-nothing' );
