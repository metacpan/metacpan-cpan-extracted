package Tail::Tool::PreProcess;

# Created on: 2010-10-22 14:45:34
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.4.7');

has post => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    init_arg => undef,
);
has many => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 1,
    init_arg => undef,
);


1;

__END__

=head1 NAME

Tail::Tool::PreProcess - Parent module for Plugins that perform pre-processing tasks on tailed lines. eg filtering

=head1 VERSION

This documentation refers to Tail::Tool::PreProcess version 0.4.7.


=head1 SYNOPSIS

   # This module is for other to extend it doesn't do anything it self.
   extends 'Tail::Tool::PreProcess';

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gamil.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gamil.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia, 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
