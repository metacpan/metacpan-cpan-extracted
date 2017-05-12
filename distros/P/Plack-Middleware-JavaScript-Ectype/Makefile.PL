use inc::Module::Install;

name     'Plack-Middleware-JavaScript-Ectype';
all_from 'lib/Plack/Middleware/JavaScript/Ectype.pm';
author   q{Daichi Hiroki <hirokidaichi<AT>gmail.com>};
license  'perl';

build_requires 'Test::More';
build_requires 'Plack::Test';

for(qw/
    HTTP::Date
    JavaScript::Ectype
    parent
    Plack::Middleware
    Plack::Util
    Plack::Util::Accessor
/){
    requires $_;
}
auto_install;

WriteAll;

