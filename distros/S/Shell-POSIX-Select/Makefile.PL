#!perl -w

use warnings;
use strict;

# Version number just of this Makefile.PL:
our $VERSION = 1.03;

use inc::Module::Install;

all_from('lib/Shell/POSIX/Select.pm');

requires('Carp');
requires('File::Spec::Functions');
requires('Filter::Simple' => 0.84);
requires('Text::Balanced' => 1.97);

WriteAll;

__END__
