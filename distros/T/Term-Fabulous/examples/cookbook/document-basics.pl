#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Document;
use Term::Fabulous::Widget::DocumentView;

# Joins pieces of text into a text and the marks over it, as the
# factories take them. A piece is a plain string, [ KIND => 'text' ] for
# a styled piece, or [ link => 'text', TARGET ] for a link.
sub marked (@pieces) {
	my ( $text, @marks ) = ('');
	foreach my $piece (@pieces) {
		if ( !ref $piece ) {
			$text .= $piece;
			next;
		}
		my ( $kind, $words, $target ) = @$piece;
		my $start = length $text;
		$text .= $words;
		push @marks, [ $start, length $text, $kind, $kind eq 'link' ? ($target) : () ];
	}
	return { text => $text, marks => \@marks };
}

my $document = Term::Fabulous::Document->new;

$document->heading( 1, 'snapback' );
$document->paragraph(
	marked(
		[ bold   => 'snapback' ],    ' copies the files of a directory to a backup disk, but ',
		[ italic => 'only' ],        ' those that changed since the last run. It reads its settings from ',
		[ file   => '~/.snapback' ], '. The old option ', [ strike => '--all' ], ' is gone.',
	)
);

$document->heading( 2, 'Usage' );
$document->code( "snapback ~/Documents /mnt/backup\nsnapback --dry-run ~/Photos /mnt/backup", language => 'shell' );

$document->heading( 2, 'Options' );
$document->term('--dry-run');
$document->paragraph( 'Lists the files it would copy, and copies nothing.', indent => 4 );
$document->term('--keep N');
$document->paragraph( marked( 'Keeps the last ', [ code => 'N' ], ' backups and deletes older ones.' ), indent => 4 );

$document->heading( 2, 'Before the first run' );
$document->list_item( '-',  'Connect the backup disk.' );
$document->list_item( '-',  'Check that it has enough free space:',                                        position => 2 );
$document->list_item( '1.', marked( 'Run ', [ code => 'df -h /mnt/backup' ], '.' ),                        indent   => 2 );
$document->list_item( '2.', 'Compare it with the size of the directory.',                                  indent   => 2, position => 2 );
$document->list_item( '-',  marked( 'Try a dry run first (see ', [ link => 'Options', 'Options' ], ').' ), position => 3 );

$document->heading( 3, 'From the mailing list' );
$document->paragraph( 'Ada wrote:',                                                                             quote => 1 );
$document->paragraph( 'Restore a file now and then. A backup that was never restored is a hope, not a backup.', quote => 2 );
$document->paragraph( marked( 'More at ', [ link => 'snapback.example.org', 'https://snapback.example.org' ], '.' ) );

my $view = Term::Fabulous::Widget::DocumentView->new(
	id       => 'manual',
	document => $document,
	layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1, top => 1 } },
);

my $ui = Term::Fabulous->new( root => $view, width => 80, height => 24 );
$ui->interaction->set_focused_widget($view);
$ui->run;
