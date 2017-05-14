package Padre::Plugin::CSS::Document;
BEGIN {
  $Padre::Plugin::CSS::Document::VERSION = '0.14';
}

# ABSTRACT: CSS Document support for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();
use File::Spec      ();
use YAML::Tiny qw(LoadFile);

our @ISA = 'Padre::Document';

sub comment_lines_str { return '//' }

sub get_help_provider {
	require Padre::Plugin::CSS::Help;
	return Padre::Plugin::CSS::Help->new;
}

sub find_help_topic {
	my ($self) = @_;

	# TODO: recognize tags with dash in the name: background-color
	# TODO: recognize values that include a number: 4px
	# TODO: recognize pseudo-class selectors:   :visited

	# TODO code copied from Padre::Wx::Dialog::HelpSearch::find_help_topic
	# eliminate duplication!
	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;

	# The selected/under the cursor word is a help topic
	my $topic = $editor->GetSelectedText;
	if ( not $topic ) {
		$topic = $editor->GetTextRange(
			$editor->WordStartPosition( $pos, 1 ),
			$editor->WordEndPosition( $pos, 1 )
		);
	}

	#warn "Topic '$topic'";
	return if not $topic;
	$topic =~ s/://;

	return lc $topic;
}


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

	$prefix =~ s{^.*?((?:\w+-)*\w+)$}{$1};
	my $last      = $editor->GetLength();
	my $text      = $editor->GetTextRange( 0, $last );
	my $pre_text  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post_text = $editor->GetTextRange( $first, $last );

	my $regex;
	eval { $regex = qr{\b(\Q$prefix\E\w+(?:-\w+)*)\b} };
	if ($@) {
		return ("Cannot build regex for '$prefix'");
	}
	require Padre::Plugin::CSS::Help;
	my $keywords = Padre::Plugin::CSS::Help->help_list;

	my %seen;
	my @words;
	push @words, grep { $_ =~ $regex and !$seen{$_}++ } @$keywords;
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

1;

__END__
=pod

=head1 NAME

Padre::Plugin::CSS::Document - CSS Document support for Padre

=head1 VERSION

version 0.14

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

