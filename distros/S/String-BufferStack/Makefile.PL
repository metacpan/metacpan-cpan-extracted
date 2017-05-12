use inc::Module::Install;

name ('String-BufferStack');
author ('Alex Vandiver <alexmv@bestpractical.com>');
abstract_from ('lib/String/BufferStack.pm');
version_from ('lib/String/BufferStack.pm');
license_from ('lib/String/BufferStack.pm');

requires( perl => '5.8.0');

sign;
WriteAll;
