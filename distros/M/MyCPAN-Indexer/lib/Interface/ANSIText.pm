package MyCPAN::Indexer::Interface::ANSIText;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Interface::Text)
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Log::Log4perl;
use Term::ANSIColor qw(colored);

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

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
