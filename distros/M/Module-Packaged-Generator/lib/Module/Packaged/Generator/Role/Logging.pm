#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Module::Packaged::Generator::Role::Logging;
BEGIN {
  $Module::Packaged::Generator::Role::Logging::VERSION = '1.111930';
}
# ABSTRACT: role to provide easy logging

use Moose::Role;
use MooseX::Has::Sugar;

use Module::Packaged::Generator::Logger;

# -- private attributes

has _logger => (
    ro,
    isa     => 'Module::Packaged::Generator::Logger',
    default => sub { Module::Packaged::Generator::Logger->instance },
    handles => [ qw{
        log_step log log_fatal log_debug
        set_debug set_muted progress_bar
    } ],
);


# provided by mpg:logger

no Moose::Role;

1;


=pod

=head1 NAME

Module::Packaged::Generator::Role::Logging - role to provide easy logging

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This L<Moose> role provides the consuming class with an easy access to
L<Module::Packaged::Generator::Logger>.

=head1 METHODS

=head2 log

=head2 log_fatal

=head2 log_debug

=head2 set_debug

=head2 set_muted

=head2 progress_bar

Those methods are imported from L<Module::Packaged::Generator::Logger> -
refer to this module for more information.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

