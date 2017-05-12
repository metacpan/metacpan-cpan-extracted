package Padre::Document::BibTeX;
BEGIN {
  $Padre::Document::BibTeX::VERSION = '0.13';
}

# ABSTRACT: BibTeX support document for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our @ISA = 'Padre::Document';

sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return '';
}

sub comment_lines_str { return '%' }

# TODO complete this
my @bibtex_types = qw/
	article book incollection inproceedings misc proceedings thesis
	/;

# TODO check for completeness
my @bibtex_fields = qw/
	abstract address author booktitle crossref editor ee isbn issn journal keywords
	location month pages publisher title volume year
	/;

sub autocomplete {
	my $self  = shift;
	my $event = shift;

	my $config    = Padre->ide->config;
	my $min_chars = $config->lang_perl5_autocomplete_min_chars; # TODO rename this config option?

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# This function is called very often, return asap
	return if ( $pos - $first ) < ( $min_chars - 1 );

	# line from beginning to current position
	my $prefix = $editor->GetTextRange( $first, $pos );

	# Remove any ident from the beginning of the prefix
	$prefix =~ s/^[\r\t]+//;
	return if length($prefix) == 0;

	# One char may be added by the current event
	return if length($prefix) < ( $min_chars - 1 );

	# The second parameter may be a reference to the current event or the next
	# char which will be added to the editor:
	my $nextchar = ''; # Use empty instead of undef
	if ( defined($event) and ( ref($event) eq 'Wx::KeyEvent' ) ) {
		my $key = $event->GetUnicodeKey;
		$nextchar = chr($key);
	} elsif ( defined($event) and ( !ref($event) ) ) {
		$nextchar = $event;
	}
	return if ord($nextchar) == 27; # Close on escape
	$nextchar = '' if ord($nextchar) < 32;

	# TODO fields, crossref, author, year

	# check for BibTeX entry types
	if ( $prefix =~ /@(\w*)$/ ) {
		my $entry_prefix = $1;
		return $self->find_completions( $entry_prefix, $nextchar, map { $_ . '{,' } @bibtex_types );
	}

	# check for BibTeX fields
	if ( $prefix =~ /(\w*)$/ ) {
		my $field_prefix = $1;
		return $self->find_completions( $field_prefix, $nextchar, @bibtex_fields );
	}

	return;
}

sub find_completions {
	my $self       = shift;
	my $prefix     = shift;
	my $nextchar   = shift;
	my @candidates = @_;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	my $last      = $editor->GetLength();
	my $pre_text  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post_text = $editor->GetTextRange( $first, $last );

	my $regex;
	eval { $regex = qr{\b(\Q$prefix\E\w*)\b} };
	if ($@) {
		warn "Cannot build regex for '$prefix'\n";
		return;
	}

	my %seen;
	my @words;
	push @words, grep { $_ =~ $regex and !$seen{$_}++ } @candidates;
	push @words, grep { !$seen{$_}++ } reverse( $pre_text =~ /$regex/g );
	push @words, grep { !$seen{$_}++ } ( $post_text =~ /$regex/g );

	# TODO is 20 a good limit?
	# TODO configurable?
	if ( scalar @words > 20 ) {
		@words = @words[ 0 .. 19 ];
	}

	# Suggesting the current word as the only solution doesn't help
	# anything, but your need to close the suggestions window before
	# you may press ENTER/RETURN.
	if ( ( $#words == 0 ) and ( $prefix eq $words[0] ) ) {
		return;
	}

	my $suffix = $editor->GetTextRange( $pos, $pos + 15 );
	$suffix = $1 if $suffix =~ /^(\w*)/; # Cut away any non-word chars

	# While typing within a word, the rest of the word shouldn't be
	# inserted.
	if ( defined($suffix) ) {
		for ( 0 .. $#words ) {
			$words[$_] =~ s/\Q$suffix\E$//;
		}
	}                                    # TODO check this

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


1;

__END__
=pod

=head1 NAME

Padre::Document::BibTeX - BibTeX support document for Padre

=head1 VERSION

version 0.13

=head1 AUTHORS

=over 4

=item *

Zeno Gantner <zenog@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Zeno Gantner, Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

