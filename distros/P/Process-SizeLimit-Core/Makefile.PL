#!/usr/bin/env perl
use Config;
use inc::Module::Package 'Au:dry 1';

perl_version '5.005';
license 'apache2';
author 'Audrey Tang <cpan@audreyt.org>';

my $osname = $Config{osname};
if ( $osname eq 'linux' ) {
    requires 'Linux::Pid';
    if ( -e '/proc/self/smaps' ) {
        requires 'Linux::Smaps';
    }
}
elsif ( $osname =~ /(bsd|aix|darwin)/i ) {
    requires 'BSD::Resource';
}
elsif ( $osname eq 'MSWin32' ) {
    requires 'Win32::API';
}
