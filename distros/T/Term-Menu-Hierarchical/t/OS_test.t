use Test::More tests => 1;

# Until I test them, I can't promise anything...
ok($^O !~ /^(?:MSWin|VMS|dos|MacOS|os2|epoc|cygwin)/i) or BAIL_OUT("OS unsupported");
