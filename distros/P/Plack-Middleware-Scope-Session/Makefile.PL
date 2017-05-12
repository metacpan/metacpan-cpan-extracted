use inc::Module::Install;

name     'Plack-Middleware-Scope-Session';
all_from 'lib/Plack/Middleware/Scope/Session.pm';
author   q{Daichi Hiroki <hirokidaichi<AT>gmail.com>};
license  'perl';

for(qw/
    Test::More
    Test::Exception
    Plack::Test
/){
    build_requires $_;
}

for(qw/
    parent
    Plack::Middleware
    Scope::Session
    HTTP::Request::Common
/){
    requires $_;
}

auto_install;

WriteAll;

