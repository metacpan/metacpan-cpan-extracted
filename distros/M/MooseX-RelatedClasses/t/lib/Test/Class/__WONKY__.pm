#
# This file is part of MooseX-RelatedClasses
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Test::Class::__WONKY__;

use Moose;
use namespace::autoclean;

with 'MooseX::RelatedClasses' => {
    all_in_namespace => 1,
};

!!42;
__END__
