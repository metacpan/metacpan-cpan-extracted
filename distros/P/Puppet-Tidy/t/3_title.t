use strict;
use Puppet::Tidy;
use Test::More tests => 6;

my (@output, $source);
###
# Identity check
###
my @should_be_output = << 'EOF';
  package { 'openssh': ensure => present }
EOF

$source = << 'EOF';
	package { 'openssh': ensure => present }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Identity test");

###
# Single line resource w/o single quotes
###
@should_be_output = << 'EOF';
  package { 'openssh': ensure => present }
EOF

$source = << 'EOF';
  package { openssh: ensure => present }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Single line resource");

###
# Single line resource with just a variable (unquoted)
###
@should_be_output = << 'EOF';
  package { "$openssh": ensure => present }
EOF

$source = << 'EOF';
  package { $openssh: ensure => present }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Title with just a variable (unquoted)");

###
# Single line resource with just a variable (single quoted)
###
@should_be_output = << 'EOF';
  package { "$openssh": ensure => present }
EOF

$source = << 'EOF';
  package { '$openssh': ensure => present }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Title with just a variable (single quoted)");

###
# Don't break paths
###
@should_be_output = << 'EOF';
  exec {
    'something':
      path => '/bin:/sbin:/usr/sbin:/usr/bin';
  }
EOF

$source = << 'EOF';
  exec {
    'something':
      path => '/bin:/sbin:/usr/sbin:/usr/bin';
  }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Path definitions shouldn't be touched");

###
# Don't break quoted commands
###
@should_be_output = << 'EOF';
  exec {
    'something':
      command => "egrep '(ffs|swap)' /etc/fstab > /tmp/fstab && cat /etc/fstab.tail >> /tmp/fstab && mv /tmp/fstab /etc/fstab";
  }
EOF

$source = << 'EOF';
  exec {
    'something':
      command => "egrep '(ffs|swap)' /etc/fstab > /tmp/fstab && cat /etc/fstab.tail >> /tmp/fstab && mv /tmp/fstab /etc/fstab";
  }
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Command shouldn't be touched");
