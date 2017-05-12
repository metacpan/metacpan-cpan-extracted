use lib 'lib';

use inc::Module::Install;

name 'Mousse';

perl_version '5.008003';

if ($ENV{MOUSSE_AUTHOR}) {
    warn "\n\n*** WARNING *** Makefile.PL set to build new Mousse!\n\n";
    use_mousse_dev('Mousse');
}

{
    local $SIG{__WARN__} = sub {1};
    all_from 'lib/Mousse/Maker.pm';
    all_from 'lib/Mousse.pod';
}
manifest_skip 'clean';
readme_from 'lib/Mousse.pod';
ack_xxx;
version_check;

WriteAll;
