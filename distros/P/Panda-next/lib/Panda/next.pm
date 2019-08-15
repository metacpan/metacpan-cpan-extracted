package Panda::next;
use 5.012;
use mro();

our $VERSION = '0.1.3';
require Panda::XSLoader;

{
    no warnings 'redefine';
    Panda::XSLoader::load();
}

1;
