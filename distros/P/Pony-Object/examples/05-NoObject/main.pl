package main;
use Pony::Object qw/:noobject :try/;

my $a = {deep => [{deep => ['structure']}]};
say dump $a;

my $data = try {
  local $/;
  open my $fh, './some/file' or die;
  my $slurp = <$fh>;
  close $fh;
  return $slurp;
} catch {
  return '';
};

say "\$data: $data";