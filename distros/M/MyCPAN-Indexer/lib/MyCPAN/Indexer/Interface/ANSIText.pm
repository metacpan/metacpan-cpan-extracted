package MyCPAN::Indexer::Interface::ANSIText;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Interface::Text);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use Log::Log4perl;
use Term::ANSIColor qw(colored);

BEGIN {
	my $rc = eval {
		require Term::ANSIColor;

		Term::ANSIColor->import( colored BLUE GREEN RED RESET );
		1
		};

	die "You need to install the Term::ANSIColor module " .
		" to use MyCPAN::Indexer::Interface::ANSIText\n" unless $rc;
}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Interface::ANSIText - Present the run info as colored text

=head1 SYNOPSIS

Use this in C<backpan_indexer.pl> by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::ANSIText

=head1 DESCRIPTION

This class presents the information as the indexer runs, using plain text.
Successful reports are green and failed reports are red.

=cut

sub skip_tick    { BLUE,  $_[0]->SUPER::skip_tick,    RESET }

sub success_tick { GREEN, $_[0]->SUPER::success_tick, RESET }

sub error_tick   { RED,   $_[0]->SUPER::error_tick,   RESET }

=head1 SEE ALSO

MyCPAN::Indexer::Interface::Text

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
