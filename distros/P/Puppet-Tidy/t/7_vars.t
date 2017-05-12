use strict;
use Puppet::Tidy;
use Test::More tests=>3;

my (@output, $source);
my @should_be_output = << 'EOF';
  if ($::bootstrap) {}
EOF

###
# Don't touch qualified variables (yet).
###
$source = << 'EOF';
  if ($::bootstrap) {}
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "don't touch qualified variables");

###
# Don't touch qualified variables (yet).
###
$source = << 'EOF';
  "/home/OpenBSD/$::operatingsystemrelease":
EOF

@should_be_output = << 'EOF';
  "/home/OpenBSD/$::operatingsystemrelease":
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "don't touch qualified variables (yet)");

###
# Don't touch unquoted qualified variables.
###
$source = << 'EOF';
  if ($conf::cacountry != "") {}
EOF

@should_be_output = << 'EOF';
  if ($conf::cacountry != "") {}
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "don't touch unquoted qualified variables");
