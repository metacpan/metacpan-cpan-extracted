package Test::Apache2::Override;
use strict;
use warnings;

sub import {
    {
        package Apache2::ServerUtil;

        sub server_root {
            '';
        }

        sub restart_count {
            0;
        }
    }
}

1;

