package ConfigAbbrevApp::Cmd::ThuruksPride;

use strict;
use warnings;

BEGIN
{
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;";
    $@ and die $@;
    $moodel->import;
}
use MooX::Cmd with_config_from_file => 1;

has race           => is => ro => required  => 1;
has security_level => is => ro => required  => 1;
has planets        => is => ro => required  => 1;
has stations       => is => ro => required  => 1;
has asteroids      => is => ro => required  => 1;
has north_gate     => is => ro => predicate => 1;
has south_gate     => is => ro => predicate => 1;
has east_gate      => is => ro => predicate => 1;
has west_gate      => is => ro => predicate => 1;

sub execute { @_ }

1;
