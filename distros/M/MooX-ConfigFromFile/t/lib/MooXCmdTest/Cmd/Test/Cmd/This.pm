package MooXCmdTest::Cmd::Test::Cmd::This;

use strict;
use warnings;

BEGIN
{
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;";
    $@ and die $@;
    $moodel->import;
}
use MooX::ConfigFromFile
  config_prefix               => "MooXCmdTest",
  config_prefix_map_separator => ".";
use MooX::Cmd with_config_from_file => 1;

has dedicated_setting => (
    is       => "ro",
    required => 1
);

sub execute { @_ }

1;
