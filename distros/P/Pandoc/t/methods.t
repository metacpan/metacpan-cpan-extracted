use strict;
use Test::More;
use Test::Exception;
use File::Which;
use File::Spec::Functions 'catdir';
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

    eval { Pandoc->new('/dev/null/notexist') };
    isa_ok $@, 'Pandoc::Error';
    like $@,   qr{pandoc executable not found at t/methods\.t},
      'stringify Pandoc::Error';
}

# bin
{
    is pandoc->bin, which( $ENV{PANDOC_PATH} || 'pandoc' ),
      'default executable';

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

    throws_ok { pandoc->version('abc') } qr{at t/methods\.t}m,
      'invalid version';
}

# arguments
{
    my @args   = qw(--number-sections -t html);
    my $pandoc = Pandoc->new(@args);
    is_deeply [ $pandoc->arguments ], \@args, 'arguments';

    $pandoc = Pandoc->new( 'pandoc', @args );
    is $pandoc->bin, which('pandoc'), 'executable and arguments';
    is_deeply [ $pandoc->arguments ], \@args, 'arguments';

    my ( $in, $out ) = ('# x');
    is $pandoc->run( [], in => \$in, out => \$out ), 0, 'run';
    like $out,
      qr{<h1 (data-number="1" )?id="x"><span class="header-section-number">1</span> x</h1>},
      'use default arguments';

    is $pandoc->run( '-t' => 'latex', { in => \$in, out => \$out } ), 0, 'run';
    like $out, qr{\\section\{x\}\\label\{x\}}, 'override default arguments';

    throws_ok { $pandoc->arguments(1) }
    qr/^first default argument must be an -option/;

    pandoc->arguments('--number-sections');
    is_deeply [ pandoc->arguments ], ['--number-sections'], 'set arguments';

    pandoc->arguments( [] );
    is_deeply [ pandoc->arguments ], [], 'set arguments with array ref';
}

# data_dir
{
    if ( -d $ENV{HOME} . '/.pandoc' and pandoc->version('1.11') ) {
        my $dir = pandoc->data_dir;
        ok $dir, 'pandoc->data_dir';
        is catdir( $dir, 'filters' ), pandoc->data_dir('filters'),
          'pandoc->data_dir(...)';
    }
}

# libs
{
    is reftype( pandoc->libs ), 'HASH', 'pandoc->libs';

    #if ($ENV{RELEASE_TESTING}) { # don't assume any libraries
    #	isa_ok pandoc->libs->{'highlighting-kate'}, 'Pandoc::Version';
    #}
}

# input_formats / output_formats
{
    my $want = qr/^(markdown|latex|html|json)$/;
    is scalar( grep { $_ =~ $want } pandoc->input_formats ), 4, 'input_formats';
    is scalar( grep { $_ =~ $want } pandoc->output_formats ), 4,
      'output_formats';
}

# highlight_languages
{
    # we cannot assume that highlighting is enabled but it should not die
    if ( pandoc->libs->{'highlighting-kate'} ) {
        ok scalar( pandoc->highlight_languages ) > 10, 'highlight_languages';
    }
}

# file
{
    throws_ok { pandoc->file('?'); } 'Pandoc::Error';
}

done_testing;
