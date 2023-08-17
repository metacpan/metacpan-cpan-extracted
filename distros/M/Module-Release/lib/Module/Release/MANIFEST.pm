use v5.16;

package Module::Release::MANIFEST;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw( check_MANIFEST );

our $VERSION = '2.131';

=encoding utf8

=head1 NAME

Module::Release::MANIFEST - Check Perl's MANIFEST to ensure you've updated it

=head1 SYNOPSIS

The release script automatically loads this module and checks your
MANIFEST file. It runs C<{make|Build} manifest> and dies if the
output contains any lines that start with C<added> or C<removed>.

If it dies, you have to start the release process again after
verifying F<MANIFEST> (and F<MANIFEST.SKIP>).

=head1 DESCRIPTION

=over 4

=item check_MANIFEST

Runs C<{make|Build} manifest>. If it sees output
starting with C<added> or C<removed>, it dies.

It looks in C<local_name> to get the name of the distribution file.

There's a slight problem with this command. It might re-order the
list of files in F<MANIFEST>. Although this doesn't bother this
command, it might make the file dirty for source control.

=cut

sub check_MANIFEST
	{
	my $self = shift;

	$self->_print( "Checking MANIFEST... " );

	my $perl = $self->{perl};

	my @ignore = $self->_get_prereq_ignore_list;

	my $output = $self->run( "$self->{make} manifest 2>&1" );

	$self->_die( "\nERROR: MANIFEST is dirty! Update MANIFEST or MANIFEST.SKIP!\n$output\n\nAborting release\n" )
		    if $output =~ /^(?:added|removed)/mi;

	$self->_print( "done\n" );
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

Copyright © 2007-2023, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
