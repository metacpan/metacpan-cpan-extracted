package Regexp::Common::profanity_us;
BEGIN {
  $Regexp::Common::profanity_us::VERSION = '4.112150';
}

use strict;
use warnings;

use Data::Dumper;
use Data::Section::Simple qw(get_data_section);

use Regexp::Common qw /pattern clean no_defaults/;






sub longest_first { length($b) <=> length($a) }

my ($profanity, @profanity);


my $data = Data::Section::Simple::get_data_section('profanity');
#die "data: $data";

    my @line = split "\n", $data;

for (@line) {


#  warn $_;

  next if /^#/;
  next if /^\s*$/;



    s/^\s+//;
    s/\s+$//;

    push @profanity, $_;

}

#die Dumper("profanity", \@profanity);

pattern name   => [qw (profanity us normal label -dist=7)],
        create => sub
  {
    my ($self, $flags) = @_;
    my $word_width = $flags->{-dist};
    my $any_char = ".{0,$word_width}";
    @profanity = map { s/-/$any_char/g; $_ } @profanity;
    $profanity = join '|', @profanity;
    $profanity = '(?k:' .  $profanity  . ')';
    #warn "<PROFANE>$profanity</PROFANE>";
    $profanity;
  },
  ;



1;



=pod

=head1 NAME

Regexp::Common::profanity_us -- provide regexes for U.S. profanity

=head1 SYNOPSIS

  use Regexp::Common qw /profanity_us/;

  my $RE = $RE{profanity}{us}{normal}{label}{-keep}{-dist=>3};

  while (<>) {
      warn "PROFANE" if /$RE/;
  }

Or easier

 use Regexp::Profanity::US;

 $profane = profane     ($string);
 @profane = profane_list($string);

=head1 OVERVIEW

Instead of a dry technical overview, I am going to explain the structure
of this module based on its history. I consult at a company that generates
customer leads primarily by having websites that attract people (e.g. 
lowering loan values, selling cars, buying real estate, etc.). For some reason
we get more than our fair share of profane leads. For this reason I was told
to write a profanity checker.

For the data that I was dealing with, the profanity was most often in the
email address or in the first or last name, so I naively started filtering
profanity with a set of regexps for that sort of data. Note that both names
and email addresses are unlike what you are reading now: they are not
whitespace-separated text, but are instead labels.

Therefore full support for profanity checking should work in 2 entirely
different contexts: labels (email, names) and text (what you are reading).
Because open-source is driven by demand and I have no need for detecting
profanity in text, only C<label> is implemented at the moment. And you 
know the next sentence: "patches welcome" :)

=head2 Spelling Variations Dictated by Sound or Sight

=head3 Creative use of symbols to spell words (el33t sp3@k)

Now, within labels, you can see normal ascii or creative use of symbols:

Here are some normal profane labels:
  suckmycock@isp.com
  shitonastick

And here they are in ascii art:
  s\/cKmyc0k@aol.com
  sh|+0naST1ck

A CPAN module which does a great job of "drawing words" is
L<Acme::Tie::Eleet|Acme::Tie::Eleet>. 
I thought I knew all of the ways that someone could
"inflate" a letter so that dirty words could bypass a profanity checker, but
just look at all these:

 %letter = 
    ( a => [ "4", "@" ],
      c => "(",
      e => "3",
      g => "6",
      h => [ "|-|", "]-[" ],
      k => [ "|<", "]{" ],
      i => "!",
      l => [ "1", "|" ],
      m => [ "|V|", "|\\/|" ],
      n => "|\\|",
      o => "0",
      s => [ "5", "Z" ],
      t => [ "7", "+"],
      u => "\\_/",
      v => "\\/",
      w => [ "vv", "\\/\\/" ],
      'y' => "j",
      z => "2",
      );

=head3 Soundex respelling

Which of course brings me to the final way to take normal text and vary it
for the same meaning: soundex.

The way a word sounds can lead to different spellings. For example, we have
 shitonastick

Which we can soundex out as:
 shitonuhstick

Or, given:
 nigger

We can rewrite it as:
 nigga
 nigguh
 niggah

There are two CPAN modules, L<Text::Soundex|Text::Soundex> and 
L<Text::Metaphone|Text::Metaphone> which do
this sort of thing, but after they resolved "shit" and "shot" to the same
soundex, I forgot about them :). 


So to conclude this OVERVIEW, (or is that oV3r\/ieW :), this module does
profanity checking for:

  labels and not text

and for:

  normal and not eleet spelling

with a bit of hedging to support soundexing (and only definite obscene
words are searched for. Ambiguous / contextual searching is left as an
exercise for the reader).

In L<Regexp::Common> terminology, which is the infrastructure on which 
this module is built, we have only the following regexp for your 
string-matching ecstasy:

    $RE{profanity}{us}{normal}{label}

and patches are welcome for:

    $RE{profanity}{us}{label}{eleet}
    $RE{profanity}{us}{text}{normal}
    $RE{profanity}{us}{text}{eleet}

But do note this if you plan to implement I<text> parsing,

C<[^:alpha:]> and not C<\b> should be used because C<_> does not form a 
word boundary and so 

  \bshit\b

will match

  shit head

and 

  shit-head

but not
  
  shit_head

Another thing about text is that it may be resolved into labels by splitting
on whitespace. Thus, one could have one engine and a different pre-processor.

=head1 USAGE

Please consult the manual of L<Regexp::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regexp::Common>.

This module reads one flag, C<-dist> which is used to set the amount of
characters that can appear between components of an obscene phrase.
For example

  suck!!!my!!!cock

will match the following regular expression

  suck-my-cock

as long as the flag C<-dist> is set to 3 or greater because this module
changes C<-> into C<.{0,$dist}> with C<$dist> defaulting to 7. 
Why such a large default? It is done so that the profanity list can
omit certain words such as my or your. Take this:

  poop on your face

We have the following regular expression

  poop--face

which is transformed to

  poop.{0,7}.{0,7}face

which will match the possible prepositions and adjectives in between
"poop" and "face" and also match the hideous term "poopface".

=head2 Capturing

Under C<-keep> (see L<Regexp::Common>):

=over 4

=item $1

captures the entire word

=back

=head1 SEE ALSO

L<Regexp::Common> for a general description of how to use this interface.

L<Regexp::Common::profanity> for a slightly more European set of words.

L<Regexp::Profanity::US> for a pair of wrapper functions that use these regexps.

=head1 AUTHOR

T. M. Brannon, tbone@cpan.org

I cannot pay enough thanks to 

  Matthew Simon Cavalletto, evo@cpan.org.

who refactored this module completely of his own volition and 
in spite of his hectic schedule. He turned this module from an
unsophisticated hack into something worth others using.

Useful brain picking came from William McKee of Knowmad Consulting on the 
L<Data::FormValidator> mailing list.

=cut


__DATA__
@@ profanity
# relating to the penis:

big-dick
big-prick
super-prick
meaty-ball
deez-nut
big-n-hard
big-and-hard
chester-the-pussy-molester
hard-on
hot-cock

# terms referring to untruths

bull-shit
load-of-crap

# sexual act

cock-suck
suck-my-cock
blow-job
facial-fetish
fuck
suck-(cock|dick)
hand-job
jack-off
jerk-off
(lick|suck)-(cock|dick|nipples|tits)

#  groin

crotch

# buttocks

ass-crack
butt-crack

# terms referring to an aggravating person

dick-head
prick-head
ass-hole
bastard

# nerd/wimp terms

punk-ass
pussy-ass
faggot
dick-less

# expletives (like bloody)

m(o|u)th(er|a|)-fuck
god-dam
shitty-ass

# racial terms

nigg?(a|er|uh)

# sexist terms

bitch
whore

# telling someone to get lost

suck-my-ass
hug-my-nuts
goto-hell
eat-shit
shit-eater
shit-head
turd-head
shit-face
suck-my-cock
fuck-off

# unpleasant bodily acts

eat-poop
smell-farts
half-assed
piss--face
piss--ass
poop--face
piss-drink
drink-piss


# vaginal 

pussies
hot-puss
juicy-puss
smelly-puss
funky-puss
white-puss
black-puss
asian-puss
sex-puss
sex-clit
juic-clit

# christmas

season-peeing
merry-pissmas

# things I have seen in my inbox :)

milk-my-breasts


