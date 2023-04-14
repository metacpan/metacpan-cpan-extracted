package iniweb;

use feature ':5.16';
use ojo;

sub import {
	$ENV{PERL_MINIWEB_ROOT}       //= '.';
	$ENV{PERL_MINIWEB_DIR_INDEX}  //= 'index.html:index.htm';

	local @ARGV = 'daemon';
	my %opts = (
		root       => $ENV{PERL_MINIWEB_ROOT},
		dir_index  => [ split ':', $ENV{PERL_MINIWEB_DIR_INDEX} ],
	);
	a->plugin( DirectoryServer => %opts )->start;

	exit( 0 );
}

1;

=head1 NAME

iniweb - Very quickly spawn a web server

=head1 SYNOPSIS

 perl -Miniweb

=head1 DESCRIPTION

The command in the synopsis will spawn a web server, serving static files
from the current working directory.

=head2 Environment Variables

=over

=item C<PERL_MINIWEB_ROOT>

Root directory to serve. Defaults to the current directory.

=item C<PERL_MINIWEB_DIR_INDEX>

Colon-seperated list of filenames to treat as a directory index. Defaults to
C<< "index.html:index.htm" >>.

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 SEE ALSO

L<Mojolicious::Plugin::DirectoryServer>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
