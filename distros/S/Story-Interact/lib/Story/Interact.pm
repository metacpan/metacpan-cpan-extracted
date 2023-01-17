use 5.010001;
use strict;
use warnings;

package Story::Interact;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001004';

use Story::Interact::Character ();
use Story::Interact::Harness::Terminal ();
use Story::Interact::Page ();
use Story::Interact::PageSource ();
use Story::Interact::PageSource::DBI ();
use Story::Interact::PageSource::Dir ();
use Story::Interact::State ();
use Story::Interact::Syntax ();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Story::Interact - tools for writing (and reading) an interactive story

=head1 SYNOPSIS

Reading story from a directory:

  story-interact /path/to/story/

Reading story from a SQLite database:

  story-interact /path/to/story.sqlite

Reading story from an arbitrary database:

  story-interact 'dbi:...'

Compiling a directory into an SQLite database:

  story-interact-dir2sqlite "/path/to/story/" "/path/to/story.sqlite"

=head1 DESCRIPTION

Story::Interact is for choose-your-own-adventure-style stories, but with a
difference. Pages can alter a global "state". This allows your character to
achieve things, and those achievements alter the course of the story later
on. This elevates stories to a full text-based game.

B<< Documentation is currently very limited. Tests are almost non-existent. >>

Stories are written in pages. Each page is a Perl script using the functions
defined in L<Story::Interactive::Syntax>. They may contain arbitrary Perl
code.

B<< Stories may contain arbitrary Perl code. Do not run untrusted stories. >>

An example page:

  at 'kitchen';
  
  text "You are in the kitchen.";
  
  unless ( location->{apple_gone} ) {
    text "There is an *apple* on the counter.";
    next_page apple => 'Pick up apple';
  }
  
  next_page living_room => 'Go to the living room';

The C<text> function is just to add a paragraph of text. (It may use simple
Markdown for B<< **bold** >> and I<< *italics* >>.) Pages can of course contain
multiple paragraphs. From version 1.001003, C<text> allows you to provide
multiple paragraphs in a single string (just add a blank line between them),
and will trim whitespace from the beginning and end of each paragraphs.

  text q{
    You are in the living room.
    
    You can see open doors to a bedroom and a kitchen.
  };

The C<next_page> function defines a path the story can take after this page.
It takes a page identifier followed by a description. It can be used multiple
times to present the user with a choice. If a page has no next page, then
it is an end to the story. (The C<next_page> function can actually be called
as C<< next_page( $id, $description, %metadata ) >> though this metadata is
not currently used for anything! In future versions it might be used to
allow shortcut keys for certain choices, etc.)

The C<at> function should be used at the top of a page to indicate what place
this page occurs at. It is an arbitrary string, so could be a room name,
grid co-ordinates, etc. Multiple pages may be written for the same location.

The C<< abstract( $string ) >> function defines a title or concise summary for
the page. It is not intended to be displayed to the reader, but may be useful
for the writer as a quick reminder of the purpose of the page.

The C<< todo( $bool ) >> function indicates whether a page still needs writing.
Again, it  is not intended to be displayed to the reader, but may be useful
for the writer.

The C<location> function returns a hashref associated with this location.
This can be used to store state for this location. You can use
C<< location( $string ) >> to access another location's hashref; the
string match must be exact.

The C<world> function returns a hashref for storing story-wide state.

The C<player> function returns a L<Story::Interactive::Character> object
representing the player. This object contains multiple hashrefs to store
character state, including what things the player knows, items the player
carries, and tasks the player has achieved.

The C<< npc( $id ) >> command returns a L<Story::Interactive::Character>
object for a non-player character, if such a character has been defined.

The C<< define_npc( $id, %data ) >> function defines a new NPC. If an NPC
already exists with that identifier, it does nothing. If the player character
will need to interact with another character on multiple occasions, it is
useful to define an NPC for them to track the character's state.

The C<visited> function returns the number of times this page has been visited
as part of the narrative before.

The C<true> and C<false> functions are just to make your code more readable.

The C<< random( $arrayref ) >> function returns a random value from the
arrayref, which can be useful for adding some randomness to stories.

The C<< match( $a, $b ) >> function is re-exported from L<match::simple>.

The first page always has id "main".

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-story-interact/issues>.

=head1 SEE ALSO

L<Pod::CYOA>, L<https://en.wikipedia.org/wiki/Choose_Your_Own_Adventure>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
