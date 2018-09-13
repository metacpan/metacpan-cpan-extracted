use strict;
use warnings;
use Test::More 0.98;
use Test::Snapshot;
use SQL::Translator;

use_ok 'SQL::Translator::Parser::OpenAPI';

(my $file = $0) =~ s#schema\.t$#corpus.json#;
$file =~ s#json$#yml# if !-f $file;
die "$file: $!" if !-f $file;

my $translator = SQL::Translator->new;
$translator->parser("OpenAPI");
$translator->producer("MySQL");

my $data = do { open my $fh, $file or die "$file: $!"; local $/; <$fh> };

my $got = $translator->translate(file => $file);
if ($got) {
  my @lines = split /\n/, $got;
  splice @lines, 0, 4; # zap opening blurb to dodge false negs
  $got = join "\n", @lines;
} else {
  diag $translator->error;
}
is_deeply_snapshot $got, 'schema';

done_testing;
