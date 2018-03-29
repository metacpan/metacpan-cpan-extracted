use strict;
use Test::More;
use Test::Exception;
use File::Which;
use Pandoc;
use Scalar::Util 'reftype';

plan skip_all => 'pandoc executable required' unless pandoc;

# import
{
    throws_ok { Pandoc->import('999.9.9') }
        qr/^pandoc 999\.9\.9 required, only found \d+(\.\d)+/,
        'import';
}

# require
{
    my $pandoc;
    lives_ok { $pandoc = Pandoc->require('0.1.0.1') } 'Pandoc->require';
    is_deeply $pandoc, pandoc, 'require returns singleton';
    lives_ok { pandoc->require('0.1.0.1') } 'pandoc->require';
    throws_ok { pandoc->require('x') } qr{ at t/methods.t}m, 'require throws)';
    throws_ok { pandoc->require('12345.67') }
        qr/^pandoc 12345\.67 required, only found \d+(\.\d)+/,
        'require throws';
}

# new
{
    my $pandoc = Pandoc->new; 
    is_deeply $pandoc, pandoc(), 'Pandoc->new';
    ok $pandoc != pandoc, 'Pandoc->new creates new instance';

    throws_ok { Pandoc->new('/dev/null/notexist') }
        qr{pandoc executable not found};
}

# bin
{
    is pandoc->bin, which($ENV{PANDOC_PATH} || 'pandoc'), 'default executable';
    
    # not an full test but part of it
    lives_ok { pandoc->bin( pandoc->bin ) } 'set executable';

    throws_ok { pandoc->bin('/dev/null/notexist') }
        qr{pandoc executable not found};
}

# version
{
    my $version = pandoc->version;
    like( $version, qr/^\d+(.\d+)+$/, 'pandoc->version' );
    isa_ok $version, 'Pandoc::Version', 'pandoc->version is a version object';

    ok pandoc->version >= $version, 'compare same versions';
    is pandoc->version($version), $version, 'expect same version';

    ok pandoc->version > '0.1.2', 'compare lower versions';
    is pandoc->version('0.1.2'), $version, 'expect lower version';

    $version =~ s/(\d+)$/$1+1/e;
    ok pandoc->version < $version, 'compare higher versions';
    ok !pandoc->version($version), 'expect higher version';

    throws_ok { pandoc->version('abc') } qr{at t/methods\.t}m, 'invalid version';
}

# arguments
{
    my $pandoc = Pandoc->new(qw(--smart -t html));
    is_deeply [$pandoc->arguments], [qw(--smart -t html)], 'arguments';

    $pandoc = Pandoc->new(qw(pandoc --smart -t html));
    is $pandoc->bin, which('pandoc'), 'executable and arguments';
    is_deeply [$pandoc->arguments], [qw(--smart -t html)], 'arguments';

    my ($in, $out) = ('*...*');
    is $pandoc->run([], in => \$in, out => \$out), 0, 'run';
    is $out, "<p><em>…</em></p>\n", 'use default arguments';

    is $pandoc->run( '-t' => 'latex', { in => \$in, out => \$out }), 0, 'run';
    is $out, "\\emph{\\ldots{}}\n", 'override default arguments';

    throws_ok { $pandoc->arguments(1) }
        qr/^first default argument must be an -option/;

    pandoc->arguments('--smart');
    is_deeply [ pandoc->arguments ], ['--smart'], 'set arguments';
    
    pandoc->arguments([]);
    is_deeply [ pandoc->arguments ], [], 'set arguments with array ref';
}

# data_dir
{
    if (-d $ENV{HOME}.'/.pandoc' and pandoc->version('1.11')) {
        ok( pandoc->data_dir, 'pandoc->data_dir' );
    }
}

# libs
{
    is reftype(pandoc->libs), 'HASH', 'pandoc->libs';
	if ($ENV{RELEASE_TESTING}) { # don't assume any libraries
		isa_ok pandoc->libs->{'pandoc-types'}, 'Pandoc::Version';
	}
}

# input_formats / output_formats
{
    my $want = qr/^(markdown|latex|html|json)$/; 
	is scalar (grep { $_ =~ $want} pandoc->input_formats), 4, 'input_formats';
	is scalar (grep { $_ =~ $want} pandoc->output_formats), 4, 'output_formats';
}

# highlight_languages
{
    # we cannot assume that highlighting is enabled but it should not die 
    if (pandoc->libs->{'highlighting-kate'}) {
        ok scalar( pandoc->highlight_languages ) > 10, 'highlight_languages';
    }
}

done_testing;
