package MooXCmdTest::Cmd::Tested;

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

has confidential_setting => (
    is      => "ro",
    builder => "_build_confidential_attribute",
    lazy    => 1,
);
sub _build_confidential_attribute { time }

sub execute { @_ }

1;

