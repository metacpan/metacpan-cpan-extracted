#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::FileDialog;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::TextArea;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Encode qw(decode);
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Temp;
use Time::Local qw(timegm);

# A folder of sample notes in a temporary directory, deleted when the
# program ends. The days are fixed and the folder is deep enough that
# the dialog shows only the end of its path, so the picture is the same
# on every run.
my $temporary = File::Temp->newdir;
my $samples   = "$temporary/home/grace/Documents/garden-club/season-2026/notes";
make_path($samples);
foreach my $sample ( [ 'groceries.txt', "Milk\nBread\nApples\n", 28 ], [ 'ideas.md', "# Ideas\n\nA clock that runs backwards.\n", 30 ], [ 'garden.txt', "Water the tomatoes.\n" x 5, 31 ] ) {
	my ( $name, $text, $day ) = @$sample;
	write_text( "$samples/$name", $text ) or die "Cannot write $samples/$name: $!\n";
	my $time = timegm( 0, 30, 10, $day, 4, 2026 );    # 10:30 on a day in May 2026
	utime $time, $time, "$samples/$name";
}

my $notes  = Term::Fabulous::Widget::TextArea->new( wrap => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $path   = undef;    # the file of the note; undef until it has one
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Ctrl+O opens, Ctrl+S saves, Alt+s saves as, Ctrl+Q quits.',
	parts   => sub { [ defined $path ? name_of($path) : 'untitled', 'dim' ] },
);
my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $notes, $status );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# A path is bytes, as the file system and the dialog's answer have it;
# the status bar shows the file's name decoded.
sub name_of ($file) {
	return decode( 'UTF-8', basename($file), Encode::FB_PERLQQ | Encode::LEAVE_SRC );
}

# Both return false when the file cannot be read or written; $! says why.
sub read_text ($file) {
	open my $in, '<:encoding(UTF-8)', $file or return;
	my $text = do { local $/; <$in> };
	close $in;
	return $text;
}

sub write_text ( $file, $text ) {
	open my $out, '>:encoding(UTF-8)', $file or return;
	print {$out} $text;
	return close $out;
}

sub open_note ($file) {
	my $text = read_text($file);
	if ( !defined $text ) {
		$status->message( 'Cannot read ' . name_of($file) . ": $!", 'danger' );
		return;
	}
	$notes->value($text);
	$path = $file;
	$status->message( 'Opened ' . name_of($file) . '.', 'success' );
	return;
}

sub save_note ($file) {
	if ( !write_text( $file, $notes->value ) ) {
		$status->message( 'Cannot write ' . name_of($file) . ": $!", 'danger' );
		return;
	}
	$path = $file;
	$status->message( 'Saved ' . name_of($file) . '.', 'success' );
	return;
}

# The dialogs start in the folder of the note, or in the samples.
sub folder () {
	return defined $path ? dirname($path) : $samples;
}

sub ask_to_open () {
	Term::Fabulous::Widget::FileDialog->new(
		mode      => 'open',
		directory => folder(),
		filters   => [ [ 'Notes' => '*.txt *.md' ], [ 'All files' => '*' ] ],
		list_rows => 5,
		width     => 60,
	)->on(
		Answer => sub ($event) {
			open_note( $event->value('path') ) if $event->button eq 'open';
			return;
		}
	)->open($ui);
	return;
}

sub ask_to_save () {
	Term::Fabulous::Widget::FileDialog->new(
		mode              => 'save',
		directory         => folder(),
		name              => defined $path ? basename($path) : 'untitled.txt',
		current_file      => $path,
		default_extension => 'txt',
		list_rows         => 5,
		width             => 60,
	)->on(
		Answer => sub ($event) {
			save_note( $event->value('path') ) if $event->button eq 'save';
			return;
		}
	)->open($ui);
	return;
}

my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'open',    label => 'Open...',    keys => ['Ctrl+O'], run => \&ask_to_open },
		{ id => 'save',    label => 'Save',       keys => ['Ctrl+S'], run => sub { defined $path ? save_note($path) : ask_to_save() } },
		{ id => 'save_as', label => 'Save as...', keys => ['Alt+s'],  run => \&ask_to_save },
		{ id => 'quit',    label => 'Quit',       keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
	],
);
$commands->listen($root);

$ui->interaction->set_focused_widget($notes);
$ui->run;
