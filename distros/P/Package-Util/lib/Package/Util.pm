package Package::Util;

BEGIN {
	require 5;
}

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# These are here just as to invite comment

sub package_inc {
	die 'package_inc not implemented';
}

sub package_file {
	die 'package_file not implemented';
}

sub modules_loaded {
	die 'module_loaded not implemented';
}

sub class_loaded {
	die 'class_loaded not implemented';
}

1;

__END__

=pod

=head1 NAME

Package::Util - A Perl/XS implementation of package-related utilities

=head1 DESCRIPTION

This module name is reserved for a dual Perl/XS module to access Perl
internal functionality for package-related functions such as
class-to-file path transformation, and various specific functionality
relating to packages, modules, classes and C<%INC>.

The implementation is proposed for completion and inclusion in the core
for the release of 5.10.

This module was originally planned for implementation as L<Module::Util>,
but unfortunately that name was subsequently taken (hence the blatant
land grab for this name).

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Jos Boumans E<lt>kane@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
