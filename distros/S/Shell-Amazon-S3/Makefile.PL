use inc::Module::Install;
name 'Shell-Amazon-S3';
all_from 'lib/Shell/Amazon/S3.pm';

requires $_
    for (
    qw/
    File::HomeDir
    File::Slurp
    Module::Find
    Net::Amazon::S3
    Path::Class
    Perl6::Say
    Scalar::Util
    Term::ANSIColor
    Term::ReadLine
    YAML
    namespace::clean
    Class::MOP
    Moose
    Moose::Role
    MooseX::ClassAttribute
    Module::Pluggable::Object
    MooseX::Object::Pluggable
    /
    );

build_requires 'Test::More';
use_test_base;
auto_include;
install_script 'script/psh3ll.pl';
WriteAll;
