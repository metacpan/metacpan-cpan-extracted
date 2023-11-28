use Test::Script 1.10 tests => 20;

script_compiles('bin/compare-code');

# TXT
script_runs(  [ 'bin/compare-code',
                'xt/data/txt/equal',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,100,0,\d{3},\d{3},0,', 'app-visibles-txt-equal' );
script_runs(  [ 'bin/compare-code',
                'xt/data/txt/one_off',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,100,1,\d{3},\d{3},1,', 'app-visibles-txt-1off' );
script_runs(  [ 'bin/compare-code',
                'xt/data/txt/two_off',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,99,2,\d{3},\d{3},0,', 'app-visibles-txt-2off' );
script_runs(  [ 'bin/compare-code',
                'xt/data/txt/ten_off',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,96,10,\d{3},\d{3},10,', 'app-visibles-txt-10off' );

# PHP
script_runs(  [ 'bin/compare-code',
                'xt/data/php/mvc',
                '-i',
                'php',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,98,7,\d{3},\d{3},6,', 'app-visibles-php-7off' );
script_runs(  [ 'bin/compare-code',
                'xt/data/php/mvc',
                '-i',
                'php',
                '-o',
                'csv',
                '-c',
                'signes',
                '-y',
              ] );
script_stdout_like   ( '2,100,0,90,90,0,', 'app-signes-php-7off' );

# JAVA
script_runs(  [ 'bin/compare-code',
                'xt/data/java/factorial',
                '-i',
                'java',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,96,11,\d{3},\d{3},6,', 'app-visibles-java-11off' );

# PERL
script_runs(  [ 'bin/compare-code',
                'xt/data/perl/nine_off',
                '-i',
                'perl',
                '-o',
                'csv',
                '-c',
                'visibles',
                '-y',
              ] );
script_stdout_like   ( '2,95,9,\d{3},\d{3},9,', 'app-visibles-perl-9off' );

# SPLIT ON SENTENCES
script_runs(  [ 'bin/compare-code',
                'xt/data/sentences',
                '-i',
                'txt',
                '-o',
                'csv',
                '-c',
                'visibles',
		'-t',
		'\.',
		'-s',
                '-y',
              ] );
script_stdout_like   ( '2,100,0,33,33,0,', 'app-visibles-split-sentences' );
script_stdout_like   ( '2,100,0,538,538,0,', 'app-visibles-split-sentences2' );
#2	100	0	33	33	0	xt/data/sentences/b.txt	xt/data/sentences/a.txt	comparison done
#2	100	0	538	538	0	xt/data/sentences/max_und_moritz2.txt	xt/data/sentences/max_und_moritz.txt	comparison done
#find xt/data/sentences -type f | perl -Ilib bin/compare-code -v -c visibles -s -t '\.'
