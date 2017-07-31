use Config::General;
use Config::INI::Reader;

package Pask::Config;

sub parse_env_file {
    Config::INI::Reader->read_file(shift);
}

1;
