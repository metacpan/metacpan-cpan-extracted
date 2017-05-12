use strict;
use Puppet::Tidy;
use Test::More tests => 2;

# don't assume //.+ is a comment inside strings
my @output;
my $source = << 'EOF';
    source => 'puppet:///foo/bar';
EOF

my @should_be_output = << 'EOF';
    source => 'puppet:///foo/bar';
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "not messing within strings");

$source = << 'EOF';
    source => 'puppet:///foo/bar'; // replace me, please
EOF

@should_be_output = << 'EOF';
    source => 'puppet:///foo/bar'; # replace me, please
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "messing outside strings");
