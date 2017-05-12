use strict;
use Puppet::Tidy;
use Test::More tests=>4;

my (@output, $source);
my @should_be_output = << 'EOF';
  Exec['reboot']
EOF

###
# Double to single quotes.
###
$source = << 'EOF';
  Exec["reboot"]
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "double to single quotes");

###
# Double quotes to single quotes.
###
@should_be_output = << 'EOF';
  Exec[$reboot]
EOF

$source = << 'EOF';
  Exec['$reboot']
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "single quotes to double quotes");

###
# Standard resource type test.
###
@should_be_output = << 'EOF';
  Exec[$reboot]
EOF

$source = << 'EOF';
  Exec["$reboot"]
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Handle standard resource types");

###
# Non-standard resource type test.
###
@should_be_output = << 'EOF';
  Host['localhost']
EOF

$source = << 'EOF';
  Host["localhost"]
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Handle non-standard resource types");
