use strict;
use Puppet::Tidy;
use Test::More tests => 4;

my (@output, $source);
###
# Mode set using a variable
###
my @should_be_output = << 'EOF';
  file { 'space': mode => $mode }
EOF

$source = << 'EOF';
  file { 'space': mode => $mode }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "mode as variable");

###
# Mode set with a four digit, double quoted string
###
@should_be_output = << 'EOF';
  file { 'space': mode => '0644' }
EOF

$source = << 'EOF';
  file { 'space': mode => "0644" }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "mode as four digit double quoted string");

###
# Mode set with a 3 digit, unquoted string
###
@should_be_output = << 'EOF';
  file { 'space': mode => '0644' }
EOF

$source = << 'EOF';
  file { 'space': mode => 644 }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "mode as three digit, unquoted string");

###
# Mode set with a 3 digit, single quoted string
###
@should_be_output = << 'EOF';
  file { 'space': mode => '0644' }
EOF

$source = << 'EOF';
  file { 'space': mode => '644' }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "mode as three digit single quoted string");
