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

package Module::Packaged::Generator::Utils;
BEGIN {
  $Module::Packaged::Generator::Utils::VERSION = '1.111930';
}
# ABSTRACT: various subs and constants used in the dist

use Exporter::Lite;
use File::HomeDir::PathClass;

our @EXPORT_OK = qw{ $DATADIR };


# -- public vars

our $DATADIR = File::HomeDir::PathClass->my_dist_data(
    'Module-Packaged-Generator', { create => 1 } );


1;


=pod

=head1 NAME

Module::Packaged::Generator::Utils - various subs and constants used in the dist

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This module exports some subs & variables used in the dist.

The following variables are available:

=over 4

=item * $DATADIR

    my $file = $DATADIR->file( ... );

A L<Path::Class> object containing the data directory for the
distribution. This directory will be created if needed.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

