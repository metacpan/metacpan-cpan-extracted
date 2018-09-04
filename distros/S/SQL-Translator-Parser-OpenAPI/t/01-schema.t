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
$translator->producer("YAML");

my $data = do { open my $fh, $file or die "$file: $!"; local $/; <$fh> };

my $got = $translator->translate(file => $file);
if ($got) {
  $got =~ s/^  version:[^\n]*\n//m; # remove SQLT version to dodge false negs
} else {
  diag $translator->error;
}
is_deeply_snapshot $got, 'schema';

done_testing;
