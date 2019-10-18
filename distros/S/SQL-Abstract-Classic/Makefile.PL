use strict;
use warnings;

use 5.006;

# Work around one of the most damaging "improvements" made
# during the modern-perl-era
BEGIN { push @INC, '.' unless grep { $_ eq '.' } @INC }

use inc::Module::Install 1.06;

perl_version '5.006';
name 'SQL-Abstract-Classic';
author 'Peter Rabbitson <ribasushi@leporine.io>';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Abstract-Classic';

all_from 'lib/SQL/Abstract/Classic.pm';

dynamic_config 0;


# FIXME: temporary, until we figure out new homes for ::Test and ::Tree
requires 'SQL::Abstract'  => '1.79';


requires 'List::Util'     => '0';
requires 'Scalar::Util'   => '0';
requires 'Exporter'       => '5.57';
requires 'MRO::Compat'    => '0.12';
requires 'Text::Balanced' => '2.00';


test_requires "Test::More"      => '0.88';
test_requires "Test::Exception" => '0.31';
test_requires "Test::Warn"      => '0';
test_requires "Test::Deep"      => '0.101';
test_requires "Storable"        => '0';   # for cloning in tests


tests_recursive 't';

auto_install();

WriteAll();
