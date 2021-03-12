use v5.16;

package Module::Release::MetaCPAN;

use strict;
use warnings;
use Exporter qw(import);

use Carp;

our @EXPORT = qw( cpan_version );

our $VERSION = '2.128';

=encoding utf8

=head1 NAME

Module::Release::MetaCPAN - Interact with MetaCPAN

=head1 SYNOPSIS

The release script automatically loads this module if it sees a
F<.svn> directory. The module exports C<cpan_version>.

=head1 DESCRIPTION

C<Module::Release::MetaCPAN> is a plugin for C<Module::Release>.

These methods are B<automatically> exported in to the callers namespace
using Exporter. You should only use it from C<Module::Release> or its
subclasses.


=cut

=over 4

=item * cpan_version()

Return the version of the module on CPAN.

=cut

sub _metacpan {
	state $rc = require MetaCPAN::Client;
	state $mcpan = MetaCPAN::Client->new;

	$mcpan;
	}


sub cpan_version {
	my $self = shift;

	# One reason for failure is that this is a new module not yet
	# on CPAN
	my $module = eval { _metacpan()->module( $self->module_name ) };
	return unless $module;

	my $date    = $module->{data}{date};
	my $version = $module->{data}{version};
	}

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2021, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
