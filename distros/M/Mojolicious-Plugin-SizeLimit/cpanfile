if ($] < 5.016) {
    requires 'Mojolicious', '>=8.02, <8.50';
}
else {
    requires 'Mojolicious', '8.02';
}

if ($^O eq 'solaris') {
    # requires 'Solaris::Procfs', '0.27';     # broken and unmaintained
}
if ($^O eq 'linux') {
    requires 'Linux::Smaps' if -e '/proc/self/smaps';
}
elsif ($^O eq 'netbsd') {
    die 'OS unsupported';
}
elsif ($^O =~ /(bsd|aix|darwin)/i) {
    requires 'BSD::Resource';
}
else {
    die 'OS unsupported';
}

requires 'Config';
requires 'File::Spec::Functions';
requires 'File::Temp';
requires 'FindBin';
requires 'IO::Socket::INET';

