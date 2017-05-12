use strict;
use Test::More;
use ShipIt::Step::Readme;
use ShipIt::Util qw(slurp);

################################################################################
# adding Install instructions
my $package_content = q~
=head1 NAME

ShipIt::Step::Readme

=head1 SYNOPSIS
~;

my $new_package = ShipIt::Step::Readme->_add_install_instructions($package_content);
is  $new_package,
    q~
=head1 NAME

ShipIt::Step::Readme

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS
~,
    'Adding Install Instructions after NAME';

################################################################################
# adding Install instructions after VERSION
$package_content = q~
=head1 NAME

ShipIt::Step::Readme

=head1 VERSION

Version 1.0

=head1 SYNOPSIS
~;

$new_package = ShipIt::Step::Readme->_add_install_instructions($package_content);
is  $new_package,
    q~
=head1 NAME

ShipIt::Step::Readme

=head1 VERSION

Version 1.0

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS
~,
    'Adding Install Instructions after VERSION';

################################################################################
# don't overwrite existing Install instructions
# => can't be tested here, it is earlier in the code
#$package_content = q~
#=head1 NAME
#
#ShipIt::Step::Readme
#
#=head1 INSTALLATION
#
#To install this module, run the following commands:
#
#    perl Build.PL
#    ./Build
#    ./Build test
#    ./Build install
#    dance around your computer 3 times
#
#=head1 SYNOPSIS
#~;
#
#$new_package = ShipIt::Step::Readme->_add_install_instructions($package_content);
#is  $new_package,
#    $package_content,
#    'Existing Install Instructions are not overwritten';


done_testing;