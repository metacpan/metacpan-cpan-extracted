use strict;
use Puppet::Tidy;
use Test::More tests=>6;

my (@should_be_output, @output, $source);
###
# CPP style comment
###
$source = << 'EOF';
  // 42
EOF

@should_be_output = << 'EOF';
  # 42
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "leading cpp style");

###
# Trailing CPP style comment
###
$source = << 'EOF';
  42, // 43!
EOF

@should_be_output = << 'EOF';
  42, # 43!
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "trailing cpp style");

###
# Empty CPP style comment
###
$source = << 'EOF';
  //
EOF

@should_be_output = << 'EOF';
  #
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "empty cpp style");

###
# C style comment
###
$source = << 'EOF';
  /* P */
EOF

@should_be_output = << 'EOF';
  # P
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "C style");

###
# Trailing C style comment
###
$source = << 'EOF';
  P, /* NP */
EOF

@should_be_output = << 'EOF';
  P, # NP
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "trailing C style");

###
# Empty C style comment
###
$source = << 'EOF';
  /*         */
EOF

@should_be_output = << 'EOF';
  #
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "empty C style");
