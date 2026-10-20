#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Encode qw(decode);
use IO::Async::Loop;
use IO::Async::Process;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# The command to run: the program's arguments, or a default.
my @command = @ARGV ? @ARGV : ( 'ls', '-l', '/' );

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);

# The arguments are bytes, like the command's output.
my $title = Term::Fabulous::Widget::Text->new( text => decode( 'UTF-8', "Running: @command" ), text_color => [ 255, 200, 80, 255 ] );

# follow_end keeps the newest line in view (see the recipe "Scroll a
# ScrollBox from code").
my $output = Term::Fabulous::Widget::ScrollBox->new(
	id               => 'output',
	follow_end       => 1,
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child( $title, $output );

sub add_line ( $line, $color = [ 200, 210, 230, 255 ] ) {
	$output->add_child( Term::Fabulous::Widget::Text->new( text => $line, text_color => $color ) );
	return;
}

# Turns the bytes of one output line into a character string; bytes
# that are not valid UTF-8 become U+FFFD.
sub clean ($bytes) {
	$bytes =~ s/\r\z//;
	return decode( 'UTF-8', $bytes );
}

# Hands every complete line of a stream to add_line.
sub line_reader ($color) {
	return sub ( $stream, $buffer_ref, $eof ) {
		add_line( clean($1), $color ) while $$buffer_ref =~ s/\A([^\n]*)\n//;
		if ( $eof && length $$buffer_ref ) {    # a last line without a line break
			add_line( clean($$buffer_ref), $color );
			$$buffer_ref = '';
		}
		return 0;
	};
}

my $loop    = IO::Async::Loop->new;
my $process = IO::Async::Process->new(
	command   => \@command,
	stdin     => { from    => '' },    # the command must not read the terminal
	stdout    => { on_read => line_reader( [ 200, 210, 230, 255 ] ) },
	stderr    => { on_read => line_reader( [ 255, 110, 110, 255 ] ) },
	on_finish => sub ( $process, $exit_code ) {
		add_line( sprintf( 'Finished with exit status %d. Press Ctrl+C to quit.', $exit_code >> 8 ), [ 255, 200, 80, 255 ] );
		return;
	},
	on_exception => sub ( $process, $exception, $errno, $exit_code ) {

		# A failed exec leaves $exception empty and the reason in $errno.
		my $reason = length( $exception // '' ) ? $exception : "$errno";
		add_line( "Could not run the command: $reason", [ 255, 110, 110, 255 ] );
		return;
	},
);
$loop->add($process);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

$ui->run;
