use strict;
use Test::More;
use Pandoc;

use utf8; # essential!

sub capture_stderr(&;@);

plan skip_all => 'pandoc executable required' unless pandoc;
plan skip_all => 'Capture::Tiny required'
    unless eval 'use Capture::Tiny qw(capture_stderr); 1;';

my $input = <<'DUMMY_TEXT';
## Ëïüs Üt

Qüï äüt völüptätë mïnïmä.
DUMMY_TEXT
my( $output, $stderr );

$stderr = capture_stderr { pandoc->run( +{ in => \$input, out => \$output } ) };
unlike  $stderr, qr{Wide character in print}, 'no wide character warning';

$stderr = capture_stderr { pandoc->run( +{ in => \$input, out => \$output, binmode => ':encoding(UTF-8)' } ) };
unlike  $stderr, qr{Wide character in print}, 'one binmode for all handles';

done_testing;
