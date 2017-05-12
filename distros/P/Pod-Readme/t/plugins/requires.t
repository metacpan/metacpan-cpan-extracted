use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Cwd;
use File::Compare qw/ compare_text /;
use File::Temp qw/ tempfile /;
use Path::Tiny qw/ path /;

use lib 't/lib';
use Pod::Readme::Test;

# use Pod::Readme::Test::Kit;

my $class = 'Pod::Readme';
use_ok $class;

isa_ok $prf = $class->new(
    input_file => $0,
    output_fh  => $io,
    base_dir   => cwd,
), $class;

SKIP: {

    # Workaround a possible bug in Travis-CI's build system, where
    # running Makefile.PL no longer generates the META.yml file
    # because the inc dir is present, but it is not in author mode.

    skip "cannot find default META.yml", 3
        unless   -e path($prf->base_dir, 'META.yml') ;

    lives_ok {
        filter_lines( '=for readme plugin requires', '' );
    } 'run requires plugin';

    like $out, qr/=head1 REQUIREMENTS\n\n/, '=head1';
    like $out, qr/\nThis distribution requires the following modules:\n\n/,
        'description';

    is_deeply [ $prf->depends_on ], [ $prf->requires_from_file, $prf->input_file ],
      'depends_on';

    lives_ok { $prf->dependencies_updated } 'dependencies_updated';

    reset_out();

    $prf->requires_run(0);
}

{
    filter_lines(
        '=for readme plugin requires from-file="t/data/META-1.yml" title="PREREQS"',
        ''
    );

    note $out;

    like $out, qr/=head1 PREREQS\n\n/, '=head1';

    like $out, qr/\nThis distribution requires Perl v5\.10\.1\.\n\n/,
        'minimum perl';

    # TODO: test content
    # - test no-omit-core option

    reset_out();

    $prf->requires_run(0);
}

{
    dies_ok {
        filter_lines( '=for readme plugin requires file=nonexistent', '' );
    } 'die on bad filename';

    reset_out();

    $prf->requires_run(0);
}

done_testing;
