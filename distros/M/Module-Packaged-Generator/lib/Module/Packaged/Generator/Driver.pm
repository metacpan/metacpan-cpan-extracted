#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Module::Packaged::Generator::Driver;
BEGIN {
  $Module::Packaged::Generator::Driver::VERSION = '1.111930';
}
# ABSTRACT: base class for all drivers

use Moose;

with 'Module::Packaged::Generator::Role::Logging';


# -- public methods


sub list { my $self = shift; $self->log_fatal( "unimplemented" ); }


1;


=pod

=head1 NAME

Module::Packaged::Generator::Driver - base class for all drivers

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This module is the base class for all distribution drivers. It provides
some helper methods, and stubs that needs to be overriden in
sub-classes.

=head1 METHODS

=head2 list

    my @modules = $driver->list;

Return the list of available Perl modules found by this distribution
driver. The method in this class just logs a fatal error, and needs to
be overridden in child classes.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

