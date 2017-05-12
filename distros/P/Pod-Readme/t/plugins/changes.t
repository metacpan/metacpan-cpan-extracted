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
), $class;

{
    filter_lines( '=for readme plugin changes', '' );

    is_deeply [ $prf->depends_on ], [ $prf->changes_file, $prf->input_file ],
      'depends_on';

    lives_ok { $prf->dependencies_updated } 'dependencies_updated';

    note $out;

    like $out, qr/=head1 RECENT CHANGES\n\n/, '=head1';

    # TODO: test content:
    # - Changes file with sections (using alternative file)
    # - Changes file without sections (using alternative file)
    # - verbatim mode
    # - changed title

    reset_out();
}

done_testing;
