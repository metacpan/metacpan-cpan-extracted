package MyCPAN::Indexer::Queue::ModifiedSince;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Queue);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use File::Basename;
use File::Find;
use File::Find::Closures  qw( find_by_regex );
use File::Path            qw( mkpath );
use File::Spec::Functions qw( catfile rel2abs );
use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Queue' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Queue - Find distributions to index

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	queue_class  MyCPAN::Indexer::Queue::ModifiedSince

=head1 DESCRIPTION

This class returns a list of Perl distributions for the BackPAN
indexer to process. It returns from the backpan directories the
files modified in the last day (not yet configurable).

=head2 Methods

=over 4

=item get_queue

C<get_queue> sets the key C<queue> in C<$Notes> hash reference. It
finds all of the tarballs or zip archives in under the directories
named in C<backpan_dir> and C<merge_dirs> in the configuration.

It specifically skips files that end in C<.txt.gz> or C<.data.gz>
since PAUSE creates those meta files near the actual module
installations.

If the C<organize_dists> configuration value is true, it also copies
any distributions it finds into a PAUSE-like structure using the
value of the C<pause_id> configuration to create the path.

=cut

sub _get_file_list
	{
	my( $self, @dirs ) = @_;

	$logger->debug( "Taking dists from [@dirs]" );
	my( $wanted, $reporter ) =
		File::Find::Closures::find_by_modified_after( time - 24*60*60 );

	find( $wanted, @dirs );

	return [
		map  { rel2abs($_) }
		grep { ! /.(data|txt).gz$/ and ! /02packages/ }
		$reporter->()
		];

	}

1;

=back

=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
