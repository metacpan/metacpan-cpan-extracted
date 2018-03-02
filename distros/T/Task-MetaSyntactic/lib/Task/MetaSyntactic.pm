package Task::MetaSyntactic;
$Task::MetaSyntactic::VERSION = '1.043';
use strict;
use warnings;

'whack_eth';

__END__

=head1 NAME

Task::MetaSyntactic - All Acme::MetaSyntactic themes at once

=head1 SYNOPSIS

    cpan Task::MetaSyntactic

    cpanp -i Task::MetaSyntactic

    cpanm Task::MetaSyntactic

=head1 DESCRIPTION

L<Acme::MetaSyntactic> is a module designed to fill all your metasyntactic
needs. There was a weekly update with new themes on CPAN between January
15, 2005 and November 6, 2006.

Since version 0.99, the weekly uploads of the module have stopped,
while I took some rest. I have also been looking for a better way to
distribute the core modules and the themes themselves.

However, some users of L<Acme::MetaSyntactic> desperately needed new
themes to be added, and grew tired of waiting for me. So, in a JFDI way,
they started to upload their own themes on CPAN.

On May 7, 2012, after a hiatus of five and a half years,
L<Acme::MetaSyntactic> was back, in a shiny version 1.000.
The main C<Acme-MetaSyntactic> distribution contains the core modules
and a single theme, while all "historical" themes now live in the
C<Acme-MetaSyntactic-Themes> distribution.

The L<Test::MetaSyntactic> module included in the main distribution
aims at simplifying the test and distribution of new themes by
individual authors.

This L<Task> (formerly a Bundle) installs the core modules and all the
official and not-so-official L<Acme::MetaSyntactic> themes, in a single
command (see the L<SYNOPSIS>).

=head1 CONTENTS

L<Acme::MetaSyntactic> - Themed metasyntactic variables names (BOOK)

L<Acme::MetaSyntactic::Themes> - The original Acme::MetaSyntactic themes (BOOK)

L<Acme::MetaSyntactic::Themes::Abigail> - More themes by Abigail (ABIGAIL)

L<Acme::MetaSyntactic::buzzwords> - Pointy-haired boss lingo (JQUELIN)

L<Acme::MetaSyntactic::chinese_zodiac> - The Chinese zodiac theme (PERLANCAR)

L<Acme::MetaSyntactic::christmas> - The Christmas theme (PERLANCAR)

L<Acme::MetaSyntactic::countries> - Country names (PERLANCAR)

L<Acme::MetaSyntactic::cpanauthors> - We are CPAN authors, and metasyntactic! (BOOK)

L<Acme::MetaSyntactic::daleks> - EXTERMINATE! EXTERMINATE! EXTERMINATE! (SAPER)

L<Acme::MetaSyntactic::dangdut> - A selection of popular Indonesian dangdut singers (PERLANCAR)

L<Acme::MetaSyntactic::display_resolution> - Display resolution names (PERLANCAR)

L<Acme::MetaSyntactic::dune> - For he is the Kwisatz Haderach! (MCARTMELL)

L<Acme::MetaSyntactic::errno> - The Errno theme (BOOK)

L<Acme::MetaSyntactic::frasier> - Characters from the sitcom Frasier (1993) (PERLANCAR)

L<Acme::MetaSyntactic::id_names> - Most common Indonesian first names (PERLANCAR)

L<Acme::MetaSyntactic::legobatman> - LEGO Batman theme (BINGOS)

L<Acme::MetaSyntactic::legocityundercover> - LEGO City Undercover theme (BINGOS)

L<Acme::MetaSyntactic::legoharrypotter> - LEGO Harry Potter theme (BINGOS)

L<Acme::MetaSyntactic::legoindianajones> - LEGO Indiana Jones theme (BINGOS)

L<Acme::MetaSyntactic::legojurassicworld> - LEGO Jurassic World theme (BINGOS)

L<Acme::MetaSyntactic::legolotr> - LEGO Lord of the Rings theme (BINGOS)

L<Acme::MetaSyntactic::legomarvelsavengers> - LEGO Marvel's Avengers theme (BINGOS)

L<Acme::MetaSyntactic::legomarvelsuperheroes> - LEGO Marvel Super Heroes theme (BINGOS)

L<Acme::MetaSyntactic::legomovievideogame> - LEGO Movie Videogame theme (BINGOS)

L<Acme::MetaSyntactic::legopiratesofthecaribbean> - LEGO Pirates of the Caribbean theme (BINGOS)

L<Acme::MetaSyntactic::legostarwarstheforceawakens> - LEGO Star Wars The Force Awakens theme (BINGOS)

L<Acme::MetaSyntactic::legothehobbit> - LEGO The Hobbit game theme (BINGOS)

L<Acme::MetaSyntactic::legoworlds> - LEGO Worlds theme (BINGOS)

L<Acme::MetaSyntactic::mlpfim> - a meta syntactic variable for everypony! (SHLOMIF)

L<Acme::MetaSyntactic::morning_musume> - The Mumusu theme (ELBEHO)

L<Acme::MetaSyntactic::nethack> - The largest time waster in the world of *nix (ELLIOTJS)

L<Acme::MetaSyntactic::seinfeld> - Characters from the sitcom Seinfeld (1989) (PERLANCAR)

L<Acme::MetaSyntactic::soviet> - NATO codenames for Soviet-designed equipment (JFORGET)

L<Acme::MetaSyntactic::vim> - The vim theme (ELLIOTJS)

L<Acme::MetaSyntactic::xkcdcommon1949> - xkcd common wordlist for Acme::MetaSyntactic (MARKF)

=head1 OTHER METASYNTACTIC MODULES

The following modules (ordered by first release date) are not part of
this L<Task>, but they also make use of L<Acme::MetaSyntactic>:

=over 4

=item L<Bot::MetaSyntactic> (SAPER)

First released on 2005-03-05.

Because the only logical thing to do with L<Acme::MetaSyntactic> was
obviously an IRC bot. This bot was part of the C<#perlfr> bot menagerie
for eight years, until it was replaced by the new kid on the block.

=item L<Acme::MetaSyntactic::RefactorCode> (JFENAL)

First released on 2005-03-15. Now deleted and only available on BackPAN.

Based on L<Acme::Floral>, this module refactors source code by replacing
variable names with L<Acme::MetaSyntactic> items.

=item L<Acme::BooK::Is::My::Bitch> (COG)

First released on 2006-09-02.

This module was written in a hotel room in Birmingham, after the YAPC
Europe 2006 auction. See also L<http://book.ismybit.ch/>.

Now ironically maintained by BooK.

=item L<Bot::BasicBot::Pluggable::Module::MetaSyntactic> (BOOK)

First released on 2013-04-13.

Because there's more than one way to do it, and it's easier to write new
code than patch old code, this bot does what L<Bot::MetaSyntactic> did,
with better support for themes with sub-categories, and the ability to
grep for items.

The bot hangs out on C<#perlfr> and C<#p5p> on L<irc://irc.perl.org/>.

=item L<Acme::PPIx::MetaSyntactic> (TOBYINK)

First released on 2013-05-15.

As we've seen, there's more than one way to be metasyntactic.

This module renames functions and variables in a L<PPI::Document> using
L<Acme::MetaSyntactic> themes.

This is the application that L<Acme::MetaSyntactic> was created for.
It only took eight years.

=item L<Data::Faker::MetaSyntactic> (BOOK)

First released on 2014-04-16.

L<Data::Faker> is all about metasyntactic data, so this module registers
a data provider for each installed L<Acme::MetaSyntactic> theme.

=item L<Acme::CPANAuthors::MetaSyntactic> (BOOK)

First released on 2014-05-24.

The L<Acme::CPANAuthors> series of modules aims at grouping CPAN authors
by various criteria. It seems there are enough authors who have produced
L<Acme::MetaSyntactic> themes to group them in their own category.

=item L<Data::Fake::MetaSyntactic> (BOOK)

First released on 2015-02-28.

L<Data::Fake> generates randomized data using declarative syntax.
This module exports factory functions that collect data from the installed
L<Acme::MetaSyntactic> theme.

=item L<WordList::MetaSyntactic> (PERLANCAR)

First released on 2016-06-06.

This module is a base class for C<WordList::MetaSyntactic::*> modules,
wordlist modules that get their wordlist from corresponding
C<Acme::MetaSyntactic::*> modules.

=item L<WordList::MetaSyntactic::dangdut> (PERLANCAR)

First released on 2016-06-06.

This is the first (and for now only) wordlist module based
on L<WordList::MetaSyntactic>. It takes its word list from
L<Acme::MetaSyntactic::dangdut>.

=item L<Acme::MetaSyntactic::WordList> (PERLANCAR)

First released on 2016-06-08.

Just like L<Acme::MetaSyntactic::cpanauthors> and
L<Acme::CPANAuthors::MetaSyntactic> are two sides of the
same coin, L<Acme::MetaSyntactic::WordList> is the dual of
L<WordList::MetaSyntactic>: a base class for C<Acme::MetaSyntactic::*>
modules that get their meta names from a corresponding C<WordList::*>
module. See L<Acme::MetaSyntactic::countries> for an example.

=item L<App::ShellCompleter::meta> (PERLANCAR)

First released on 2016-11-04.

Shell completer for L<meta>, using L<Shell::Completer>.

=item L<Dist::Zilla::Plugin::Acme::MetaSyntactic> (PERLANCAR)

First released on 2017-02-04.

A L<Dist::Zilla> plugin that automates some of the steps of building an
Acme-MetaSyntactic-* theme distribution.

=item L<App::metastasize> (PERLANCAR)

First released on 2017-02-11.

This is an application based on L<Acme::PPIx::MetaSyntactic>.

=item L<Complete::Acme::MetaSyntactic> (PERLANCAR)

First released on 2017-02-15.

Completion routines for L<Acme::MetaSyntactic>.

=item L<App::metasyn> (PERLANCAR)

First released on 2017-02-17.

An alternative to the L<meta> front-end to L<Acme::MetaSyntactic>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2005-2017 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
