use Test::More tests => 2;
use String::Errf 'errf';

my $payload = {
  total_amount => 1010,
  limit        => 1000,
  category     => "sandwiches",
};

{
  # Here String::Errf could warn about a malformed format string, or it could
  # produce reasonable partial output, but it does neither.
  my $format = join(" ",
    "payment of \$%{total_amount}",
    "for category '%{category}s'",
    "over limit of \$%{limit;.2}f",
  );

  my $output = eval { errf($format, $payload) };
  isnt($output, 'payment of $\' over limit of $1000.00', "wat");
}

{
  # Here String::Errf could warn about a malformed format string, or it could
  # produce reasonable partial output, but it does neither.
  my $format = join(" ",
    "payment of \$%{total_amount;.2}",
    "for category '%{category}s'",
    "over limit of \$%{limit;.2}f",
  );

  my $output = eval { errf($format, $payload) };
  ok(
    ! defined $output || $output =~ qr/category.*sandwiches/,
    "where did the literal text 'category' go?",
  );
}

