package Pod::Perldoc::ToToc;
use strict;
use parent qw(Pod::Perldoc::BaseTo);
use vars qw($VERSION);

use Pod::TOC;

use warnings;
no warnings;

$VERSION = '1.126';

sub is_pageable        { 1 }
sub write_with_binmode { 0 }
sub output_extension   { 'toc' }

sub parse_from_file {
	my( $self, $file, $output_fh ) = @_; # Pod::Perldoc object

	my $parser = Pod::TOC->new();

	$parser->output_fh( $output_fh );

	$parser->parse_file( $file );
	}

=encoding utf8

=head1 NAME

Pod::Perldoc::ToToc - Translate Pod to a Table of Contents

=head1 SYNOPSIS

Use this module with C<perldoc>'s C<-M> switch.

	% perldoc -MPod::Perldoc::ToToc Module::Name

=head1 DESCRIPTION

This module uses the C<Pod::Perldoc> module to extract a table of
contents from a pod file.

=head1 METHODS

=over 4

=item parse_from_file( FILENAME, OUTPUT_FH )

Parse the file named in C<FILENAME> using C<Pod::TOC> and send the
results to the output filehandle C<OUTPUT_FH>.

=back

=head1 SEE ALSO

L<Pod::Perldoc>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/pod-perldoc-totoc

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2006-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
