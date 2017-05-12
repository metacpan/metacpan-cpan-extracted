requires 'AnyEvent';
requires 'Module::Runtime';
requires 'parent';
requires 'perl', '5.008001';

# dependencies for each platforms
if ($^O eq 'darwin') {
    requires 'Cocoa::EventLoop';
    requires 'Cocoa::Skype';
} elsif ($^O eq 'linux') {
    requires 'AnyEvent::DBus';
    requires 'Net::DBus::Skype::API';
}

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::More', '0.98';
};
