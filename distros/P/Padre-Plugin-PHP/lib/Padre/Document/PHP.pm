package Padre::Document::PHP;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.05';
our @ISA     = 'Padre::Document';

sub comment_lines_str { return '#' }

sub event_on_char {
	my ( $self, $editor, $event ) = @_;

	my $main   = Padre->ide->wx->main;
	my $config = Padre->ide->config;

	$editor->Freeze;

	$self->autocomplete_matching_char(
		$editor, $event,
		34  => 34,  # " "
		39  => 39,  # ' '
		40  => 41,  # ( )
		60  => 62,  # < >
		91  => 93,  # [ ]
		123 => 125, # { }
	);

	$editor->Thaw;

	$main->on_autocompletion($event) if $config->autocomplete_always;

	return;
}

sub autocomplete {
	my $self  = shift;
	my $event = shift;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# line from beginning to current position
	my $prefix = $editor->GetTextRange( $first, $pos );
	my $suffix = $editor->GetTextRange( $pos,   $pos + 15 );
	$suffix = $1 if $suffix =~ /^(\w*)/; # Cut away any non-word chars

	# The second parameter may be a reference to the current event or the next
	# char which will be added to the editor:
	my $nextchar;
	if ( defined($event) and ( ref($event) eq 'Wx::KeyEvent' ) ) {
		my $key = $event->GetUnicodeKey;
		$nextchar = chr($key);
	} elsif ( defined($event) and ( !ref($event) ) ) {
		$nextchar = $event;
	}

	# check for hashs
	elsif ( $prefix =~ /(\$\w+(?:\-\>)?)\[([\'\"]?)([\$\&]?\w*)$/ ) {
		my $hashname   = $1;
		my $textmarker = $2;
		my $keyprefix  = $3;

		my $last = $editor->GetLength();
		my $text = $editor->GetTextRange( 0, $last );

		my %words;
		while ( $text =~ /\Q$hashname\E\[(([\'\"]?)\Q$keyprefix\E.+?\2)\]/g ) {
			$words{$1} = 1;
		}

		return (
			length( $textmarker . $keyprefix ),
			sort {
				my $a1 = $a;
				my $b1 = $b;
				$a1 =~ s/^([\'\"])(.+)\1/$2/;
				$b1 =~ s/^([\'\"])(.+)\1/$2/;
				$a1 cmp $b1;
				} ( keys(%words) )
		);

	}

	$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	my $last      = $editor->GetLength();
	my $text      = $editor->GetTextRange( 0, $last );
	my $pre_text  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post_text = $editor->GetTextRange( $first, $last );

	my $regex;
	eval { $regex = qr{\b(\Q$prefix\E\w+(?:::\w+)*)\b} };
	if ($@) {
		return ("Cannot build regex for '$prefix'");
	}
	my @keywords=qw/abstract  	 and   	 array   	 as   	 break
case 	catch 	cfunction 	class 	clone
const 	continue 	declare 	default 	do
else 	elseif 	enddeclare 	endfor 	endforeach
endif 	endswitch 	endwhile 	extends 	final
for 	foreach 	function 	global 	goto
if 	implements 	interface 	instanceof
namespace 	new 	old_function 	or 	private
protected 	public 	static 	switch 	throw
try 	use 	var 	while 	xor/;

	my %seen;
	my @words;
	push @words, grep { $_ =~ $regex and !$seen{$_}++} @keywords;
	push @words, grep { !$seen{$_}++ } reverse( $pre_text =~ /$regex/g );
	push @words, grep { !$seen{$_}++ } ( $post_text =~ /$regex/g );

	if ( @words > 20 ) {
		@words = @words[ 0 .. 19 ];
	}

	# Suggesting the current word as the only solution doesn't help
	# anything, but your need to close the suggestions window before
	# you may press ENTER/RETURN.
	if ( ( $#words == 0 ) and ( $prefix eq $words[0] ) ) {
		return;
	}

	# While typing within a word, the rest of the word shouldn't be
	# inserted.
	if ( defined($suffix) ) {
		for ( 0 .. $#words ) {
			$words[$_] =~ s/\Q$suffix\E$//;
		}
	}

	# This is the final result if there is no char which hasn't been
	# saved to the editor buffer until now
	return ( length($prefix), @words ) if !defined($nextchar);

	# Finally cut out all words which do not match the next char
	# which will be inserted into the editor (by the current event)
	my @final_words;
	for (@words) {

		# Accept everything which has prefix + next char + at least one other char
		next if !/^\Q$prefix$nextchar\E./;
		push @final_words, $_;
	}

	return ( length($prefix), @final_words );
}

sub autoclean {
	my $self = shift;

	my $editor = $self->editor;
	my $text   = $editor->GetText;

	$text =~ s/[\s\t]+([\r\n]*?)$/$1/mg;
	$text .= "\n" if $text !~ /\n$/;

	$editor->SetText($text);

	return 1;

}

sub get_command {

	my $self  = shift;
	my $debug = shift;

	my $config = Padre->ide->config;

	# Use a temporary file if run_save is set to 'unsaved'
	my $filename =
		  $config->run_save eq 'unsaved' && !$self->is_saved
		? $self->store_in_tempfile
		: $self->filename;

	my $php = $config->php_cmd;

	# Warn if the PHP interpreter is not executable:
	if ( defined($php) and ( $php ne '' ) and ( !-x $php ) ) {
		my $ret = Wx::MessageBox(
			Wx::gettext(
				sprintf( '%s seems to be no executable PHP interpreter, use the system default PHP instead?', $php )
			),
			Wx::gettext('Run'),
			Wx::wxYES_NO | Wx::wxCENTRE,
			Padre->ide->wx->main,
		);
		$php = 'php'
			if $ret == Wx::wxYES;

	} else {
		$php = 'php';
	}

	# Set default arguments
	my %run_args = (
		interpreter => $config->php_interpreter_args_default,

		#		script      => $config->run_script_args_default,
	);

	# Overwrite default arguments with the ones preferred for given document
	foreach my $arg ( keys %run_args ) {
		my $type = "run_${arg}_args_" . File::Basename::fileparse($filename);
		$run_args{$arg} = Padre::DB::History->previous($type) if Padre::DB::History->previous($type);
	}

	# TODO: Pack args here, because adding the space later confuses the called interpreter
	my $Script_Args = '';
	$Script_Args = ' ' . $run_args{script} if defined( $run_args{script} ) and ( $run_args{script} ne '' );

	my $dir = File::Basename::dirname($filename);
	chdir $dir;

	return $debug
		? qq{"$php" -d error_reporting=E_ALL $run_args{interpreter} "$filename"$Script_Args}
		: qq{"$php" $run_args{interpreter} "$filename"$Script_Args};
}

sub menu {
	my $self = shift;

	return ['menu.PHP'];
}


sub newline_keep_column {
	my $self = shift;

	my $editor = $self->editor or return;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);
	my $col    = $pos - $editor->PositionFromLine( $editor->LineFromPosition($pos) );
	my $text   = $editor->GetTextRange( $first, ( $pos - $first ) );

	$editor->AddText( $self->newline );

	$pos   = $editor->GetCurrentPos;
	$first = $editor->PositionFromLine( $editor->LineFromPosition($pos) );

	#	my $col2 = $pos - $first;
	#	$editor->AddText( ' ' x ( $col - $col2 ) );

	# TODO: Remove the part made by auto-ident before addtext:
	$text =~ s/[^\s\t\r\n]/ /g;
	$editor->AddText($text);

	$editor->SetCurrentPos( $first + $col );

	return 1;
}


1;
