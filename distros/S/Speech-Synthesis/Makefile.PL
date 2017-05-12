use inc::Module::Install;

name('Speech-Synthesis');
version_from('lib/Speech/Synthesis.pm');
abstract_from('lib/Speech/Synthesis.pm');
author('Jouke Visser <jouke@pvoice.org>');
license('perl');
check_nmake();
requires(perl => 5.006);
include_deps('Test::More', 5.004);
build_requires('Test::More');
if ($^O eq 'darwin')
{
    requires('Mac::Speech');
}
elsif ($^O eq 'MSWin32')
{
    my $ok = 0;
    eval "use Win32::SAPI5";
    $ok = 1 unless $@;
    eval "use Win32::SAPI4";
    $ok = 1 unless $@;
    eval "use Win32::MSAgent";
    $ok = 1 unless $@;
    requires('Win32::SAPI5') unless $ok;
    requires('Win32::Locale');
    requires('Win32::OLE');
}
else
{
    requires('Festival::Client::Async');
}
&Meta->write();
&Makefile->write();
