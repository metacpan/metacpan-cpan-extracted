use inc::Module::Install 1.06;

# Define metadata
name 'Padre-Plugin-Cookbook';
abstract 'Cookbook contains recipes to assist you in makeing your own Padre::Plugin';
license 'perl';
author 'Kevin Dawson <bowtie@cpan.org>';
perl_version '5.010001';

# All from our plugin
all_from      'lib/Padre/Plugin/Cookbook.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe01/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe02/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe03/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe04/Main.pm';

# Padre version, should match that of the latest version, used in padre_interfaces,
requires 'Padre'                => '0.96';

# required modules from CPAN
requires 'Carp'                 => '1.26';
requires 'Data::Dumper'         => '2.145';
requires 'Data::Printer'        => '0.35';
requires 'Moose'                => '2.0802';
requires 'constant'             => '1.27';
requires 'namespace::autoclean' => '0.13';
requires 'parent'               => '0.225';

test_requires 'Test::More' => '0.98';

recommends 'Test::Pod'           => '1.48';
recommends 'Test::Pod::Coverage' => '1.08';

# Optional if you have used the share directory
install_share;

# additinal
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginDialog';
bugtracker 'http://padre.perlide.org/trac';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Cookbook/';

no_index 'directory' => qw{ fbp inc share t xt };

WriteAll;
