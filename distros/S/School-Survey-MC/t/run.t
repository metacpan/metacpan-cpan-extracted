use Test::Script 1.10 tests => 22;

script_compiles('bin/mcp');

script_runs( [ 'bin/mcp', 1, 'examples/questions/binary_choice.yml' ],
               'run-with-binary');
script_stdout_like   ( '</html>', 'binary-stdout-something' );
script_stderr_unlike ( '\w+', 'binary-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/mixed_choice.yml' ],
               'run-with-mixed');
script_stdout_like   ( '</html>', 'mixed-stdout-something' );
script_stderr_unlike ( '\w+', 'mixed-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/multiple_choice.yml' ],
               'run-with-multiple');
script_stdout_like   ( '</html>', 'multiple-stdout-something' );
script_stderr_unlike ( '\w+', 'multiple-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/questions/similar_choices.yml' ],
               'run-with-similar');
script_stdout_like   ( '</html>', 'similar-stdout-something' );
script_stderr_unlike ( '\w+', 'similar-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/config/language.yml' ],
               'run-with-similar');
script_stdout_like   ( '</html>', 'config-stdout-something' );
script_stderr_unlike ( '\w+', 'config-stderr-nothing' );

script_runs( [ 'bin/mcp', 1, 'examples/config/config_last.yml' ],
               'run-with-similar');
script_stdout_like   ( '</html>', 'config-stdout-something' );
script_stderr_unlike ( '\w+', 'config-stderr-nothing' );

script_runs( [ 'bin/mcp', 2, 'examples/questions/multiple_choice.yml', 'examples/questions/binary_choice.yml' ],
               'run-with-multifile');
script_stdout_like   ( '</html>', 'multifile-stdout-something' );
script_stderr_unlike ( '\w+', 'multifile-stderr-nothing' );
