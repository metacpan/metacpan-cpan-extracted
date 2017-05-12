use warnings;
use strict;

package Parse::GutenbergRoget;
use base qw(Exporter);

use Carp ();
use Text::CSV_XS;

our @EXPORT = qw(parse_roget);  ## no critic Export

=head1 NAME

Parse::GutenbergRoget - parse Project Gutenberg's Roget's Thesaurus

=head1 VERSION

version 0.022

  $Id$

=cut

our $VERSION = '0.022';

=head1 SYNOPSIS

 use Parse::GutenbergRoget

 my %section = parse_roget("./roget15a.txt");

 print $section{1}[0][0]{text}; # existence

=head1 DESCRIPTION

A Roget's Thesaurus is more than the simple synonym/antonym finder included in
many dictionary sets.  It organizes words into semantically realted categories,
so that words with related meanings can be found in proximity to one another,
with the level of proximity indicating the level of similarity.

Project Gutenberg has produced an etext of the 1911 edition of Roget's
Thesaurus, and later began to revise it, in 1991.  While it's not the best
Roget-style thesaurus available, it's the best public domain electronic
thesaurus datasource I've found.

This module parses the file's contents into a Perl data structure, which can
then be stored in systems for searching and browsing it.  This module does
I<not> implement those systems.

The code is not complete.  This means that everything that can be parsed is not
yet being parsed.  It's important to realize that not everything is going to be
parseable.  There are too many typos and broken rules which, due to the lousy
nature of the rules, create ambiguity.  For a description of these rules see
L</"RULES"> below.

=head1 FUNCTIONS

=head2 C<< parse_roget($filename) >>

This function, exported by default, will attempt to open, read, and parse the
named file as a Project Gutenberg Roget's Thesaurus.  It has only been tested
with C<roget15a.txt>, which is not included in the distribution, because it's
too big.

It returns a hash with the following structure:

 %section = (
   ...
   '100a' => {
     major => 100, # major and minor form section identity
     minor => 'a',
     name  => 'Fraction',
     comments    => [ 'Less than one' ],
     subsections => [
       {
         type   => 'N', # these entries are nouns
         groups => [
           { entries => [
             { text => 'fraction' },
             { text => 'fractional part' }
           ] },
           { entries => [ { text => 'part &c. 51' } ] }
         ]
       },
       {
         type   => 'Adj',
         groups => [ { entries => [ ... ] } ]
       }
     ]
   }
   ...
 );

This structure isn't pretty or perfect, and is subject to change.  All of its
elements are shown here, except for one exception, which is the next likely
subject for change: flags.  Entries may have flags, in addition to text, which 
note things like "French" or "archaic".  Entries (or possibly groups) will also
gain cross reference attribues, replacing the ugly "&c. XX" text.  I'd also
like to deal with references to other subsections, which come in the form "&c.
Adj."  There isn't any reason for these to be needed, I think.

=cut

sub parse_roget {
  my ($filename) = @_;
  my %section = parse_sections($filename);
	bloom_sections(\%section);
	return %section;
}

=head2 C<< parse_sections($filename) >>

This function is used internally by C<parse_roget> to read the named file,
returning the above structure, parsed only to the section level.

=cut

sub parse_sections {
	my ($filename) = @_;

	open my $roget, '<', $filename
		or Carp::croak "couldn't open $filename: $!";

	my $previous_section;
	my %section;

	my $peeked_line;
	my ($in_newheader, $in_longcomment);

	while (my $line = ($peeked_line || <$roget>)) {
		undef $peeked_line;

		chomp $line;
		next unless $line;
		next if ($line =~ /^#/); # comment

		if ($line =~ /^\s*<--/) { $in_longcomment = 1; }
		if ($line =~ /-->$/) { $in_longcomment = 0; next; }
		next if $in_longcomment;

		if ($line =~ /^%/) {
			$in_newheader = not $in_newheader;
			next;
		}
		next if $in_newheader;

		$line =~ s/^\s+//;

		until ($peeked_line) {
			$peeked_line = <$roget>;
			last unless defined $peeked_line;
			chomp $peeked_line;
			if ($peeked_line and $peeked_line !~ /^\s{4}/
				and $peeked_line !~ /^(?:#|%|<--)/)
			{
				$line .= q{ } unless (substr($line, -1, 1) eq q{-});
				$line .= $peeked_line;
				undef $peeked_line;
				if ($line =~ /[^,]+,[^.]+\.\s{4}/) {
					($line, $peeked_line) = split /\s{4}/, $line, 2;
				}
			}
		}

		my ($sec, $title, $newline) =
			($line =~ /^#?(\d+[a-z]?). (.*?)(?:--(.*))?$/);
		$line = ($newline||'') if ($sec);

		if ($sec) {
			(my($comment_beginning), $title, my($comment_end)) =
				($title =~ /(?:\[(.+?)\.?\])?\s*([^.]+)\.?\s*(?:\[(.+?)\.?\])?/);
			$title =~ s/(^\s+|\s{2,}|\s+$)//g;
			$section{$sec} = {
				name        => $title,
				subsections => [ { text => $line||'' } ],
				comments    => [ grep { defined $_ } ($comment_beginning, $comment_end) ]
			};
			@{$section{$sec}}{qw[major minor]} = ($sec =~ /^(\d+)(.*)$/);
			Carp::confess "couldn't parse section: $sec" unless $section{$sec}{major};
			$previous_section = $sec;
		} else {
			$section{$previous_section}{subsections} ||= [];
			push @{$section{$previous_section}{subsections}}, { text => $line };
		}
	}
	return %section;

}

=head2 C<< bloom_sections(\%sections) >>

Given a reference to the section hash, this subroutine expands the sections
into subsections, groups, and entries.

=cut

sub bloom_sections {
	my ($section) = @_;

	my $decomma = Text::CSV_XS->new;
	my $desemi  = Text::CSV_XS->new({sep_char => q{;}});

	my $types = qr/(Adj|Adv|Int|N|Phr|Pron|V)/;

	for (values %$section) {
		my $previous_subsection;
		for my $subsection (@{$_->{subsections}}) {
			$subsection->{text} =~ s/\.$//;
			$subsection->{text} =~ s/ {2,}/ /g;
			$subsection->{text} =~ s/(^\s+|\s+$)//g;

			if (my ($type) = ($subsection->{text} =~ /^$types\./)) {
				$subsection->{text} =~ s/^$type\.//;
				$subsection->{type} = $type;
			} elsif ($previous_subsection) {
				$subsection->{type} = $previous_subsection->{type};
			} else {
				$subsection->{type} = 'UNKNOWN';
			}

			$desemi->parse(delete $subsection->{text});
			$subsection->{groups} = [ map { { text => $_ } } $desemi->fields ];

			for my $group (@{$subsection->{groups}}) {
				$decomma->parse(delete $group->{text});
				$group->{entries} = [ map { { text => $_, flags => [] } } $decomma->fields ];

				for (@{$group->{entries}}) {
					$_->{text}||= 'UNPARSED';
					if ($_->{text} =~ s/\[obs3\]//) {
						push @{$_->{flags}}, 'archaic? (1991)';
					}
					if ($_->{text} =~ s/|!//) {
						push @{$_->{flags}}, 'obsolete (1991)';
					}
					if ($_->{text} =~ s/|//) {
						push @{$_->{flags}}, 'obsolete (1911)';
					}
					$_->{text} =~ s/(^\s+|\s+$)//;
				}
			}
			$previous_subsection = $subsection;
		}
	}
}

=head1 THE FILE

=over 4

=item * The thesaurus file is plain text, in 7-bit ASCII.

=item * Lines with a C<#> as their first character are comments.

=item * Lines beginning with C<< <-- >> begin multi-line comments.

=item * Lines ending with C<< --> >> end multi-line comments.

These multi-line comments were originally used for including the page numbers
from the original text.  Later editors used them (instead of C<#> comments) to
mark their editorial notes.

There exists one situation in C<roget15a.txt> where the C<< <-- >> occurs
outside of position zero in a line.

=item * A line containing only C<%> begins or ends new "supersection" data.

So, if we wanted to begin a new supersection for "States of Mind", we might
have the following:

 %
 STATES OF MIND
 %

Unfortunately, there is almost no consistency in how these supersections are
organized.  Some entries declare new sections "SECTION VII. CHANGE" and
immediately begin new subsupersections, "1. SIMPLE CHANGE".  Others just give
headings: "Present Events" 

Then there is this excerpt:

 %
                          CLASS II
                     WORDS RELATING TO SPACE
 
                SECTION I.  SPACE IN GENERAL
 
 1. ABSTRACT SPACE
 %

I think the only thing to do is ignore all this crap, so that's what is done.

=item * Lines do not exceed 79 characters in width.

=item * New lines begin in column 6.

Some, though, begin in column 5, 6, or 8.  A line starting in column 4 or less
is always a continuation, unless it's in 0.  (I'm not considering comments.)

Also, new lines might begin in any column, when a period that does not follow
the declaration of a subsection type is followed by at least four spaces.

=item * Lines in column 0 are continuation.

Unless the previous line ended with a period.

Continuations are appended to the continued line.  Unless the continued line
ended with a hyphen, a space is used to join the lines.

There is at least one case where a word is split without a hyphen, appearing as
"crocu\ns".  This word is left broken in the parsed text.

=item * New lines beginning with a C<#> (not in column 0) begin new sections.

The C<#> is omitted in one case, section 252a.

=item * The C<#> in a section heading is followed by the section identifier.

The section identifier is a series of numbers followed by an optional letter
and terminated by a period.

=item * The section header is followed by a name and comments.

The comments are marked off by square brackets, and may occur before or after
the name, or both.

The name is all the rest of the text between the comments and before a
terminating C<-->.

=item * Once section headers are removed, every new line is a new subsection.

=item * Subsections may begin with a type declaration.

A type declaration indicates that all entries in the subsection are of one
part of speech: adjective, adverb, noun, interjection, phrase, and so on.

=item * Subsections with no declared type are of the type of the previous subsection.

Despite this rule, some subsections have no type.  I file them as UNKNOWN.

=item * Subsections are divided into groups by semicolons.

Semicolons don't divide subsections, if they occur within double quotes.  The
quotes can be part of the line, and need not quote the entire group.

In other words, this is a valid subsection, consisting of three groups:

 ...
      Int. go for it; "go ahead; make my day" [Dirty Harry]; give it a try,
 take a shot.
 ...

=item * Groups are divided into entries by commas.

Commas don't divide groups, if they occur within double quotes.  The quotes can
be just part of the entry, and need not quote the entire entry.

Some groups include the entry-breaking comma inside the quotes, like this one:

      Phr. it must go no further, it will go no further; don't tell a
 soul;"tell it not in Gath,"nobody the wiser; alitur vitium vivitque
 tegendo[Lat][obs3]; "let it be tenable in your silence still"[Hamlet].

The comma after "Gath" should be on the outside.

=item * Flags may follow the text of an entry.

Flags are either text enclosed in square brackets, as "[Lat]" or the special
identifiers C<|!> or C<|>.  These flags provide metadata about the entry, like
its language of origin or the domain of jargon in which it is relevant.  C<|>
indicates that a word was obsolete in the 1911 edition, and C<|!> indicates
words that were no longer used as indicated by 1991.  (A third obsolete status
is indicated by the flag "[obs3]" meaning "entirely archaic as of 1991.")

Sometimes, flags occur outside of quotes, and sometimes they're inside.  The
example text above shows flags outside of the Hamlet quote, but this section
(which really exists) is a counter-example:

      Phr. noli me tangere[Lat]; nemo me impune lacessit[Lat]; don't tread
 on me; don't you dare; don't even think of it; "Go ahead, make my day!"
 [Dirty Harry].

=item * Cross-references may follow the entry.

I haven't determined whether any entries have both a cross-reference I<and>
flags.

A cross-reference is in the form "c&. 123" where 123 is a section, or "c&. n."
where "n" refers to the noun-type subsections for this section.

Unfortunately, cross-references are not always followed by commas or
semicolons, meaning that they sometimes seem to appear in the middle of an
entry, as follows:

      miss, miss one's aim, miss the mark, miss one's footing, miss stays;
 slip, trip, stumble; make a slip &c., n. blunder &c. 495, make a mess of,
 ...

The cross-reference after "make a slip" should have a comma after the "n." but
does not, so it appears to be the middle of an entry beginning after "stumble;"
and ending before "make a mess of."

=back

=head1 TODO

Well, a good first step would be a TODO section.

I'll write some tests that will only run if you put a C<roget15a.txt> file in
the right place.  I'll also try the tests with previous revisions of the file.

I'm also tempted to produce newer revisions on my own, after I contact the
address listed in the file.  The changes would just be to eliminate anomalies
that prevent parsing.  Distraction by shiny objects may prevent this goal.

The flags and cross reference bits above will be implemented.

The need for Text::CSV_XS may be eliminated.

Entries with internal quoting (especially common in phrases) will no longer
become UNPARSED.

I'll try to eliminate more UNKNOWN subsection types.

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parse-gutenbergroget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
