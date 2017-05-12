use strict;
use Puppet::Tidy;
use Test::More tests=>4;

my (@output, $source);
my @should_be_output = << 'EOF';
  if ('false') { # XXX: Quoted boolean encountered.
EOF

###
# Insert warning for single quoted 'false'.
###
$source = << 'EOF';
  if ('false') {
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "insert warning for single quoted 'false'");

###
# Insert warning for double quoted 'false'.
###
$source = << 'EOF';
  if ("false") {
EOF

@should_be_output = << 'EOF';
  if ("false") { # XXX: Quoted boolean encountered.
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "insert warning for double quoted 'false'");

###
# Booleans mustn't be single quoted.
###
$source = << 'EOF';
  if ('true') {
    # This is also reached.
  }
EOF

@should_be_output = << 'EOF';
  if (true) {
    # This is also reached.
  }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "booleans mustn't be single quoted");

###
# Booleans mustn't be double quoted.
###
$source = << 'EOF';
  if ("true") {
    # This is also reached.
  }
EOF

@should_be_output = << 'EOF';
  if (true) {
    # This is also reached.
  }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "booleans mustn't be double quoted");
