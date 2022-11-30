package RiveScript::WD;

use strict;
use warnings;

# Version of the Perl RiveScript interpreter. This must be on a single line!
# See `perldoc version`
use version; our $VERSION = version->declare('v2.0.4');

# This is not a real module; it's only a current copy of the RiveScript
# Working Draft. See the latest version at
# http://www.rivescript.com/wd/RiveScript.html
1;

=head1 NAME

RiveScript::WD - RiveScript 2.00 Working Draft (2014/11/30)

=head1 DESCRIPTION

This document details the standards for the RiveScript scripting language. The
purpose of this document is that interpreters for RiveScript could be written
in various programming languages that would meet the standards for the
RiveScript language itself.

The most current version of this document is at
http://www.rivescript.com/wd/RiveScript.html

=head1 INTRODUCTION

RiveScript is an interpreted scripting language for giving responses to
chatterbots and other intelligent chatting entities in a simple trigger/reply
format. The scripting language is intended to be simplistic and easy to learn
and manage.

=head1 VOCABULARY

=over 4

=item RiveScript

RiveScript is the name of the scripting language that this document explains.

=item Interpreter

The RiveScript interpreter is a program or library in another programming
language that loads and parses a RiveScript document.

=item RiveScript Document

A RiveScript Document is a text file containing RiveScript code.

=item Bot

A Bot (short for robot) is the artificial entity that is represented by an
instance of a RiveScript Interpreter object. That is, when you create a new
Interpreter object and load a set of RiveScript Documents, that becomes the
"brain" of the bot.

=item Bot Variable

A variable that describes the bot, such as its name, age, or other details
you want to define for the bot.

=item Client Variable

A variable that the bot keeps about a specific client, or user of the bot.
Usually as the client tells the bot information about itself, the bot could
save this information into Client Variables and recite it later.

=back

=head1 FORMAT

A RiveScript document should be parsed line by line, and preferably arranged
in the interpreter's memory in an efficient way.

The first character on each line should be the C<command>, and the rest of the
line is the command's C<arguments>. The C<command> should be a single character
that is not a number or a letter.

In its most simple form, a valid RiveScript trigger/response pair looks like
this:

  + hello bot
  - Hello, human.

=head1 WHITESPACE

A RiveScript interpreter should ignore leading and trailing whitespace characters
on any line. It should also ignore whitespace characters surrounding individual
arguments of a RiveScript command, where applicable. That is to say, the following
two lines should be interpreted as being exactly the same:

  ! global debug = 1
  !    global    debug=    1

=head1 COMMANDS

=head2 ! DEFINITION

The C<!> command is for defining variables within RiveScript. It's used to
define information about the bot, define global arrays that can be used in
multiple triggers, or override interpreter globals such as debug mode.

The format of the C<!> command is as follows:

  ! type name = value

Where C<type> is one of C<version, global, var, array, sub,> or C<person>.
The C<name> is the name of the variable being defined, and C<value> is the
value of said variable.

Whitespace surrounding the C<=> sign should be stripped out.

Setting a value to C<E<lt>undefE<gt>> will undefine the variable (deleting it
or uninitializing it, depending on the implementation).

The variable types supported are detailed as follows:

=head3 version

It's highly recommended practice that new RiveScript documents explicitly
define the version of RiveScript that they are following. RiveScript 2.00
has some compatibility issues with the old 1.x line (see L<"REVERSE COMPATIBILITY">).
Newer RiveScript versions should encourage that RiveScript documents define their
own version numbers.

  ! version = 2.00

=head3 global

This should override a global variable at the interpreter level. The obvious
variable name might be "debug" (to enable/disable debugging within the
RiveScript interpreter).

The interpreter should take extra care not to allow reserved globals to be
overridden by this command in ways that might break the interpreter.

Examples:

  ! global debug = 1

=head3 var

This should define a "bot variable" for the bot. This should only be used in an
initialization sense; that is, as the interpreter loads the document, it should
define the bot variable as it reads in this line. If you'd want to redefine or
alter the value of a bot variable, you should do so using a tag inside of a
RiveScript document (see L<"TAGS">).

Examples:

  ! var name      = RiveScript Bot
  ! var age       = 0
  ! var gender    = androgynous
  ! var location  = Cyberspace
  ! var generator = RiveScript

=head3 array

This will create an array of strings, which can then be used later in triggers
(see L<"+ TRIGGER">). If the array contains single words, separating the words
with a space character is fine. If the array contains items with multiple words
in them, separate the entries with a pipe symbol (C<"|">).

Examples:

  ! array colors = red green blue cyan magenta yellow black white orange brown
  ! array be     = is are was were
  ! array whatis = what is|what are|what was|what were

Arrays have special treatment when spanned over multiple lines. Each extension
of the array data is treated individually. For example, to break an array of
many single-words into multiple lines of RiveScript code:

  ! array colors = red green blue cyan
  ^ magenta yellow black white
  ^ orange brown

The data structure pulled from that code would be identical to the previous
example above for this array.

Since each extension line is processed individually, you can combine the
space-delimited and pipe-delimited formats. In this case, we can add some color
names to our list that have multiple words in them.

  ! array colors = red green blue cyan magenta yellow
  ^ light red|light green|light blue|light cyan|light magenta|light yellow
  ^ dark red|dark green|dark blue|dark cyan|dark magenta|dark yellow
  ^ white orange teal brown pink
  ^ dark white|dark orange|dark teal|dark brown|dark pink

Finally, if your array consists of almost entirely single-word items, and you
want to add in just one multi-word item, but don't want to require an extra line
of RiveScript code to accomplish this, just use the C<\s> tag where you need
spaces to go.

  ! array blues = azure blue aqua cyan baby\sblue sky\sblue

=head3 sub

The C<sub> variables are for defining substitutions that should be run against
the client's message before any attempts are made to match it to a reply.

The interpreter should do the minimum amount of formatting possible on the
client's message until after it has been passed through all the substitution
patterns.

B<NOTE:> Spaces are allowed in both the variable name and the value fields.

Examples:

  ! sub what's  = what is
  ! sub what're = what are
  ! sub what'd  = what did
  ! sub a/s/l   = age sex location
  ! sub brb     = be right back
  ! sub afk     = away from keyboard
  ! sub l o l   = lol

=head3 person

The C<person> variables work a lot like C<sub>s do, but these are run against
the bot's response, specifically within C<E<lt>personE<gt>> tags (See L<"TAGS">).

Person substitutions should swap first- and second-person pronouns. This is so
that ex. if the client asks the bot a direct question using "you" when addressing
the bot, if the bot uses the client's message in the response it should swap
"you" for "I".

Examples:

  ! person you are = I am
  ! person i am    = you are
  ! person you     = I
  ! person i       = you

=head2 E<gt> LABEL

The C<E<gt>> and C<E<lt>> commands are for defining a subset of your code under
a certain label. The label command takes between one and three arguments. The
first argument defines the type of the label, which is one of C<begin, topic,>
or C<object>. The various types are as follows.

=head3 begin

This is a special label used with the C<BEGIN block>. Every message the
client sends to the bot gets passed through the Begin Statement first, and the
response in there determines whether or not to get an actual reply.

Here's a full example of the Begin Statement.

  > begin

    + request
    - {ok}

  < begin

In the C<BEGIN block>, the trigger named "C<request>" is called by the
interpreter, and it should return the tag "C<{ok}>" to tell the interpreter
that it's OK to get a real reply. This way the bot could have a "maintenance
mode," or could filter the results of your trigger based on a variable.

Here's a maintenance mode example:

  > begin

    + request
    * <id> eq <bot master> => {ok} // Always let the bot master get a reply
    * <env maint> eq true  => Sorry, I'm not available for chat right now!
    - {ok}

  < begin

  // Allow the owner to change the maintenance mode
  + activate maintenance mode
  * <id> eq <bot master> => <env maint=true>Maintenance mode activated.
  - You're not my master! You can't tell me what to do!

  + deactivate maintenance mode
  * <id> eq <bot master> => <env maint=false>Maintenance mode deactivated.
  - Only my master can deactivate maintenance mode!

With this example, if the global variable "maint" is set to "true", the bot
will always reply "Sorry, I'm not available for chat right now!" when a user
sends it a message -- unless the user is the bot's owner.

Here is another example that will modify the response formatting based on a
bot variable called "mood," to simulate humanoid moods for the bot:

  > begin

    + request
    * <get mood> == happy => {ok} :-)
    * <get mood> == sad   => {lowercase}{ok}{/lowercase}
    * <get mood> == angry => {uppercase}{ok}{/uppercase}
    - {ok}

  < begin

In this example the bot will use smiley faces when it's happy, reply in all
lowercase when it's sad, or all uppercase when it's angry. If its mood doesn't
fall into any of those categories, it replies normally.

Here is one last example: say you want your bot to interview its users when
they first talk to it, by asking them for their name:

  > begin

    + request
    * <get name> == undefined => {topic=newuser}{ok}
    - {ok}

  < begin

  > topic newuser
    + *
    - Hello! My name is <bot name>! I'm a robot. What's your name?

    + _
    % * what is your name
    - <set name=<formal>>Nice to meet you, <get name>!{topic=random}
  < topic

Begin blocks are B<optional!> They are not required. You only need to manually
define them if you need to do any "pre-processing" or "post-processing" on the
user's message or the bot's response. Having no begin block is the same as
having a super basic begin block, which always returns C<{ok}>.

=head3 topic

A topic is a smaller set of responses to which the client will be bound until
the topic is changed to something else. The default topic is C<random>.

The C<topic> label only requires one additional argument, which is the name of
the topic. The topic's name should be one word and lowercase.

Example:

  + i hate you
  - Well then, I won't talk to you until you take that back.{topic=apology}

  > topic apology

    + *
    - I won't listen to you until you apologize for being mean to me.
    - I have nothing to say until you say you're sorry.

    + (sorry|i apologize)
    - Okay. I guess I'll forgive you then.{topic=random}

  < topic

Topics are able to C<include> and C<inherit> triggers that belong to a
different topic. When a topic C<includes> another topic, it means that the
triggers in another topic are made available in the topic that did the
inclusion (hereby called the "source topic", which includes triggers from
the "included topic").

When a topic inherits another topic, it means that the entire collection
of triggers of the source topic I<and> any included topics, will have a
higher matching priority than the inherited topics.

See L<"Sorting +Triggers"> to see how triggers are sorted internally. The
following example shows how includes and inheritence works:

  // This is in the default "random" topic and catches all non-matching
  // triggers.
  + *
  - I'm afraid I don't know how to reply to that!

  > topic alpha
    + alpha trigger
    - Alpha's response.
  < topic

  > topic beta
    + beta trigger
    - Beta's response.
  <

  > topic gamma
    + gamma trigger
    - Gamma's response.
  < topic

  > topic delta
    + delta trigger
    - Delta's response.

    + *
    - You can't access any other triggers! Haha!
  < topic

These are all normal topics. Alpha, beta, and gamma all have a single
trigger corresponding to their topic names. If the user were put into
one of these topics, this is the only trigger available. Anything else
would give them a "NO REPLY" error message. They are unable to match the
C<*> trigger at the top, because that trigger belongs to the "C<random>"
topic, and they're not in that topic.

Now let's see how we can pair these topics up with includes and
inheritence.

  > topic ab includes alpha
    + hello bot
    - Hello human!
  < topic

  // Matching order:
  alpha trigger
  hello bot

If the user were put into topic "C<ab>", they could match the trigger
C<hello bot> as well as the trigger C<alpha trigger>, as if they were
both in the same topic.

Note that in the matching order, "alpha trigger" is at the top: this
is because it is the longest trigger. If the user types "alpha trigger",
the interpreter knows that "alpha trigger" does not belong to the topic
"ab", but since "ab" includes triggers from "alpha", the interpreter
searches there and finds the trigger. Then it gives the user the
correct reply of "Alpha's response."

  > topic abc includes alpha beta
    + how are you
    - Good, how are you?
  < topic

  // Matching order:
  how are you
  alpha trigger
  beta trigger

In this case, "how are you" is on the top of the matching list because
it has three words, then "alpha trigger" and "beta trigger" -- "alpha
trigger" is first because it is longer than "beta trigger", even though
they both have 2 words.

Now consider this example:

  > topic abc includes alpha beta
    + how are you
    - Good, how are you?

    + *
    - You matched my star trigger!
  < topic

  // Matching order:
  how are you
  alpha trigger
  beta trigger
  *

Notice what happened here: we had a trigger of simply C<*> in the "abc"
topic - C<*> is the fallback trigger which matches anything that wasn't
matched by a better trigger. But this trigger is at the end of our matching
list! This is because the triggers available in the "alpha" and "beta" topics
are included in the "abc" topic, meaning they all share the same "space"
when the triggers are sorted. Since C<*> has the lowest sort priority,
it ends up at the very end of the collective list.

What if we want C<*>, or any other short trigger, to match in our current
topic before anything in an included topic? We need to C<inherit> another
topic. Consider this:

  > topic abc inherits alpha beta
    + how are you
    - Good, how are you?

    + *
    - You matched my star trigger!
  < topic

  // Matching order:
  how are you
  *
  alpha trigger
  beta trigger

Now the C<*> trigger is the second on the matching list. Because "abc"
I<inherits> alpha and beta, it means that the collection of triggers
inside "abc" are sorted independently, and I<then> the triggers of alpha
and beta are sorted. So this way every trigger in "abc" inherits, or
I<overrides>, all triggers in the inherited topics.

Of course, using a C<*> trigger in a topic that inherits other topics is
useless, because you could just leave the topic as it is. However it might
be helpful in the case that a trigger in your topic is very short or has
very few words, and you want to make sure that this trigger will have a
good chance of matching before anything that appears in a different topic.

You can combine inherited and included topics together, too.

  > topic abc includes alpha beta delta inherits gamma
    + how are you
    - Good, how are you?
  < topic

  // Matching order:
  how are you
  alpha trigger
  delta trigger
  beta trigger
  *
  gamma trigger

In this example, the combined triggers from abc, alpha, beta, and delta
are all merged together in one pool and sorted amongst themselves, and
then triggers from gamma are placed after them in the sort list.

This effectively means you can combine the triggers from multiple
topics together, and have ALL of those triggers override triggers
from an inherited topic.

You can use as many "includes" and "inherits" keywords as you want, but
the order you specify them has no effect. So the following two formats
are identical:

  > topic alpha includes beta inherits gamma
  > topic alpha inherits gamma includes beta

In both cases, alpha and beta's triggers are pooled and have higher
priority than gamma's. If gamma wants to include beta and have alpha's
triggers be higher priority than gamma's and beta's, gamma will need
to include beta first.

  > topic gamma includes beta
  > topic alpha inherits gamma

In this case the triggers in "alpha" are higher priority than the
combined triggers in gamma and beta.

=head3 object

Objects are bits of program code that the interpreter should try to process.
The programming language that the interpreter was written in will determine
whether or not it will attempt to process the object.

See L<"OBJECT MACROS"> for more information on objects.

The C<object> label should have two arguments: a lowercase single-word name for
the object, and the programming language that the object should be interpreted
by, which should also be lowercase.

Example:

  > object encode perl
    my ($obj,$method,@args) = @_;
    my $msg = join(" ",@args);

    use Digest::MD5 qw(md5_hex);
    use MIME::Base64 qw(encode_base64);

    if ($method eq 'md5') {
      return md5_hex($msg);
    }
    else {
      return encode_base64($msg);
    }
  < object

=head2 + TRIGGER

The C<+> command is the basis for all things that actually do stuff within a
RiveScript document. The trigger command is what matches the user's message to
a response.

The trigger's text should be entirely lowercase and not contain any symbols
(except those used for matching complicated messages). That is, a trigger that
wants to match "C<what's your name>" shouldn't be used; you should use a
L<"sub">stitution to convert C<what's> into C<what is> ahead of time.

Example:

  + are you a bot
  - How did you know I'm a robot?

=head3 Atomic Trigger

An atomic trigger is a trigger that matches nothing but plain text. It doesn't
contain any wildcards (C<*>) or optionals, but it may contain alternations.
Atomic triggers should take higher priority for matching a client's message
than should triggers containing wildcards and optionals.

Examples:

  + hello bot
  + what is your name
  + what is your (home|office) phone number
  + who is george w bush

=head3 Trigger Wildcards

Using an asterisk (C<*>) in the trigger will make it act as a wildcard. Anything
the user says in place of the wildcard may still match the trigger. For example:

  + my name is *
  - Pleased to meet you, <star>.

An asterisk (C<*>) will match any character (numbers and letters). If you want
to only match numbers, use C<#>, and to match only letters use C<_>. Example:

  // This will ONLY take a number as the wildcard.
  + i am # years old
  - I will remember that you are <star> years old.

  // This will ONLY take letters but not numbers.
  + my name is _
  - Nice to meet you, <star>.

The values matched by the wildcards can be retrieved in the responses by using
the tags C<E<lt>star1E<gt>>, C<E<lt>star2E<gt>>, C<E<lt>star3E<gt>>, etc. in the
order that the wildcard appeared. C<E<lt>starE<gt>> is an alias for C<E<lt>star1E<gt>>.

=head3 Trigger Alternations

An alternation in a trigger is a sub-set of strings, in which any one of the
strings will still match the trigger. For example, the following trigger should
match both "are you okay" and "are you alright":

  + are you (okay|alright)

Alternations can contain spaces in them, too.

  + (are you|you) (okay|alright)

That would match all of the following questions from the client:

  are you okay
  are you alright
  you okay
  you alright

Alternations match the same as wildcards do; they can be retrieved via the
C<E<lt>starE<gt>> tags.

=head3 Trigger Optionals

Triggers can contain optional words as well. Optionals are written similarly to
alternations, but they use square braces. The following example would match both
"what is your phone number" as well as "what is your B<home> phone number"

  + what is your [home] phone number

Optionals do B<NOT> match like wildcards do. They do NOT go into the
C<E<lt>starE<gt>> tags. The reason for this is that optionals are optional, and
won't always match anything if the client didn't actually say the optional word(s).

=head3 Arrays in Triggers

Arrays defined via the L<"! DEFINITION"> L<"array"> commands can be used within
a trigger. This is the only place where arrays are used, and they're added as a
convenience feature.

For example, you can make an array of color names, and then use that array in
multiple triggers, without having to copy a whole bunch of alternation code between
triggers.

  ! array colors = red green blue cyan magenta yellow black white orange brown

  + i am wearing a (@colors) shirt
  - I don't know if I have a shirt that's colored <star>.

  + my favorite color is (@colors)
  - I like <star> too.

  + i have a @colors colored *
  - Have you thought about getting a <star> in a different color?

When an array is called within parenthesis, it should be matched into a
C<E<lt>starE<gt>> tag. When the parenthesis are absent, however, it should not
be matched into a C<E<lt>starE<gt>> tag.

=head3 Priority Triggers

A new feature proposed for RiveScript 2.00 is to add a priority tag to triggers.
When the interpreter sorts all the loaded triggers into a search sequence, any
triggers that have a priority defined will be sorted with higher priority
triggers first.

The idea is to have "important" triggers that should always be matched before a
different trigger, which may have been a better match, can be tried. The best
example would be for commands. For example:

  + google *
  - Searching Google... <call>google <star></call>

  + * or not
  - Or yes. <@>

In that example, if the bot had a Google search function and the user wanted to
search for whether or not Perl is a superior programming language to PHP, the
user might ask "C<google is perl better than php or not>". However, without
priorities in effect, that question would actually match the "C<* or not>"
trigger, because that trigger has more words than "C<google *>" does.

Adding a priority to the "C<google *>" trigger would ensure that conflicts like
this don't happen, by always sorting the Google search trigger with higher
priority than the other.

  + {weight=100}google *
  - Searching Google... <call>google <star></call>

B<NOTE:> It would NOT be recommended to put a priority tag on every one of your
triggers. To the interpreter this might mean extra processing work to sort
prioritized triggers by each number group. Only add priorities to triggers that
need them.

=head2 - RESPONSE

The C<-> tag is used to indicate a response to a matched trigger. A single
response to a single trigger is called an "atomic response." When more than one
response is given to a single trigger, the collection of responses become a
"random response," where a response is chosen randomly from the list. Random
responses can also use a C<{weight}> tag to improve the likelihood of one response
being randomly chosen over another.

=head3 Atomic Response

A single response to a single trigger makes an Atomic Response. The bot will
respond pretty much the same way each time the trigger is matched.

Examples:

  + hello bot
  - Hello human.

  + my name is *
  - Nice to meet you, <star>.

  + i have a (@colors) shirt
  - You're not the only one that has a <star> shirt.

=head3 Random Response

Multiple responses to a single trigger will be chosen randomly.

  + hello
  - Hey there!
  - Hello!
  - Hi, how are you?

  + my name is *
  - Nice to meet you, <star>.
  - Hi, <star>, my name is <bot name>.
  - <star>, nice to meet you.

=head3 Weighted Random Response

When using random responses, it's possible to give weight to them to change the
likelihood that a response will be chosen. In this example, the response of
"Hello there" will be much more likely to be chosen than would the response of
"Hi".

  + hello
  - Hello there!{weight=50}
  - Hi.

When the C<{weight}> tag isn't used, a default weight of 1 is implied for that
response. The C<{weight}> should always be a number greater than zero and must
be an integer (no decimal point).

=head2 % PREVIOUS

The C<%> command is for drawing the user back to finish a short discussion. Its
behavior is similar to using topics, but is implied automatically and used for
short-term things. It's also less strict than topics are; if the client replies
in a way that doesn't match, a normal reply is given anyway. For example:

  + knock knock
  - Who's there?

  + *
  % who is there
  - <star> who?

  + *
  % * who
  - lol! <star>! That's hilarious!

The text of the C<%> command looks similar to the text next to the trigger. In
essence, they work the same; the only difference is that the C<%> command matches
the last thing that the I<bot> sent to you.

Here's another example:

  + i have a dog
  - What color is it?

  + (@colors)
  % what color is it
  - That's an odd color for a dog.

In that case, if the client says "I have a dog," the bot will reply asking what
color it is. Now, if I tell it the color in my next message, it will reply back
and tell me what an odd color that is. However, if I change the topic instead and
say something else to the bot, it will answer my new question anyway. This is in
contrast to using topics, where I'd be stuck inside of the topic until the bot
resets the topic to C<random>.

Similarly to the wildcards in C<+ Trigger>, the wildcards matched in the
C<% Previous> command are put into C<E<lt>botstarE<gt>>. See L<"TAGS"> for
more information.

=head2 ^ CONTINUE

The C<^> command is used to continue the text of a lengthy previous command down
to the new line. It can be used to extend any other command. Example:

  + tell me a poem
  - Little Miss Muffit sat on her tuffet\n
  ^ in a nonchalant sort of way.\n
  ^ With her forcefield around her,\n
  ^ the Spider, the bounder,\n
  ^ Is not in the picture today.

Note that when the C<^> command continues the previous command, no spaces or
line breaks are implied at the joining of the two lines. The C<\s> and C<\n>
tags must be explicitly defined where needed.

=head2 @ REDIRECT

The C<@> command is used to redirect an entire response to appear as though the
client asked an entirely different question. For example:

  + my name is *
  - Nice to meet you, <star>.

  + call me *
  @ my name is <star>

If the client says "call me John", the bot will redirect it as though the client
actually said "my name is John" and give the response of "Nice to meet you,
John."

=head2 * CONDITION

The C<*> command is used with conditionals when replying to a trigger. Put simply,
they compare two values, and when the comparison is true the associated response
is given. The syntax is as follows:

  * value symbol value => response

The following inequality symbols may be used:

  ==  equal to
  eq  equal to (alias)
  !=  not equal to
  ne  not equal to (alias)
  <>  not equal to (alias)
  <   less than
  <=  less than or equal to
  >   greater than
  >=  greater than or equal to

In each of the value places, tags can be used to i.e. insert client or bot
variables.

Examples:

  + am i a boy or a girl
  * <get gender> eq male   => You told me you were a boy.
  * <get gender> eq female => You told me you were a girl.
  - You never told me what you were.

  + am i your master
  * <id> eq <bot master> => Yes, you are.
  - No, you're not my master.

  + my name is *
  * <get name> eq <star>    => I know, you told me that already.
  * <get name> ne undefined => Did you get a name change?<set name=<star>>
  - <set name=<star>>Nice to meet you, <star>.

It's recommended practice to always include at least one response in case all
of the conditionals return false.

B<NOTE:> Conditionals are tried in the order they appear in the RiveScript
document, and the next condition is tried when the previous ones are false.

=head2 // COMMENT

The C<//> command is for putting comments into your RiveScript document. The
C-style multiline comment syntax C</* */> is also supported.

Comments on their own line should be ignored by all interpreters. For inline
comments, only the C<//> format is acceptable. If you want a literal C<//> in
your RiveScript data, escape at least one of the symbols, i.e. C<\//> or C<\/\/>
or C</\/>.

Examples:

  // A single regular comment

  /*
    This comment can span
    multiple lines
  */

  > begin // The "BEGIN" block
    + request // This is required
    - {ok}    // An {ok} means to get a real reply
  < begin//End the begin block

=head1 OBJECT MACROS

An C<object macro> is a piece of program code that is processed by the interpreter
to give a little more "kick" to the RiveScript. All objects are required to define
the programming language they use. Ones that don't should result in vociferous
warnings by the interpreter.

Objects should be able to be declared inline within RiveScript code, however they
may also be defined by the program utilizing the interpreter as well. All objects
should receive, at a minimum, some kind of reference to the RiveScript interpreter
object that called them.

Here is an example of a simple Perl object that encodes a bit of text into
MD5 or Base64.

  > object encode perl
    my ($obj,$method,@args) = @_;
    my $msg = join(" ",@args);

    use Digest::MD5 qw(md5_hex);
    use MIME::Base64 qw(encode_base64);

    if ($method eq 'md5') {
      return md5_hex($msg);
    }
    else {
      return encode_base64($msg);
    }
  < object

To call an object within a response, call it in the format of:

  <call>object_name arguments</call>

For example:

  + encode * in md5
  - The MD5 hash of "<star>" is: <call>encode md5 <star></call>

  + encode * in base64
  - The Base64 hash of "<star>" is: <call>encode base64 <star></call>

In the above examples, C<encode> calls on the object named "encode", which we
defined above; C<md5> and C<base64> calls on the method name, which is received
by the object as C<$method>. Finally, C<@args> as received by the object would
be the value of E<lt>starE<gt> in this example.

C<$obj> in this example would be a reference to the RiveScript interpreter.

=head1 TAGS

Tags are bits of text inserted within the argument space of a RiveScript command.
As a general rule of thumb, tags with E<lt>angle bracketsE<gt> are for setting
and getting a variable or for inserting text. Tags with {curly brackets} modify
the text around them, such as to change the formatting of enclosed text.

No tags can be used within C<! Definition> and C<E<gt> Label> under any
circumstances.

Unless otherwise specified, all of the tags can be used within every RiveScript
command.

=head2 E<lt>starE<gt>, E<lt>star1E<gt> - E<lt>starNE<gt>

The C<E<lt>starE<gt>> tags are used for matching responses. See
L<"+ TRIGGER"> for usage examples.

The C<E<lt>starE<gt>> tags can NOT be used within C<+ Trigger>.

=head2 E<lt>botstarE<gt>, E<lt>botstar1E<gt> - E<lt>botstarNE<gt>

If the trigger included a C<% Previous> command, C<E<lt>botstarE<gt>> will match
any wildcards that matched the bot's previous response.

  + ask me a question
  - What color's your {random}shirt shoes socks{/random}

  + *
  % what colors your *
  - I wouldn't like <star> as a color for my <botstar>.

=head2 E<lt>input1E<gt> - E<lt>input9E<gt>; E<lt>reply1E<gt> - E<lt>reply9E<gt>.

The input and reply tags insert the previous 1 to 9 things the client said, and
the last 1 to 9 things the bot said, respectively. When these tags are used with
C<+ Trigger>, they should be formatted against substitutions first. This way, the
bot might be able to detect when the client is repeating themself or when they're
repeating the bot's replies.

  + <reply1>
  - Don't repeat what I say.

  + <input1>
  * <input1> eq <input2> => That's the second time you've repeated yourself.
  * <input1> eq <input3> => If you repeat yourself again I'll stop talking to you.
  * <input1> eq <input4> => That's it. I'm done talking to you.{topic=blocked}
  - Please don't repeat yourself.

C<E<lt>inputE<gt>> and C<E<lt>replyE<gt>> are aliases for C<E<lt>input1E<gt>> and
C<E<lt>reply1E<gt>>, respectively.

=head2 E<lt>idE<gt>

The C<E<lt>idE<gt>> tag inserts the client's ID, as told to the RiveScript
interpreter when the client's ID and message were passed in.

=head2 E<lt>botE<gt>

Insert a bot variable, which was previously defined via the C<! Definition>
L<"var"> commands.

  + what is your name
  - I am <bot name>, a chatterbot created by <bot company>.

  + my name is <bot name>
  - <set name=<bot name>>What a coincidence, that's my name too!

The C<E<lt>botE<gt>> tag allows assignment as well (which deprecates the old
C<{!...}> tag.

  + set mood to (happy|angry|sad)
  * <get master> == true => <bot mood=<star>>Updated my mood.
  - Only my botmaster can do that.

=head2 E<lt>envE<gt>

Insert a global variable, which was previously defined via C<! Definition>
L<"global"> commands.

  + is debug mode enabled
  * <env debug> == 1 => Yes, debug mode is active.
  - No, debug mode is set to "<env debug>"

The C<E<lt>envE<gt>> tag allows assignment as well (which deprecates the old
C<{!...}> tag).

  + turn debug mode on
  * <get master> == true => <env debug=1>Debug mode enabled.
  - You can't turn debug mode on.

=head2 E<lt>getE<gt>, E<lt>setE<gt>

Get and set a client variable. These variables are local to the user ID that is
chatting with the bot.

  + my name is *
  - <set name=<star>>Nice to meet you, <star>.

E<lt>getE<gt> can be used within C<+ Trigger>, but E<lt>setE<gt> can not.

=head2 E<lt>addE<gt>, E<lt>subE<gt>, E<lt>multE<gt>, E<lt>divE<gt>

Add, subtract, multiply, and divide a numeric client variable, respectively.

  + give me 5 points
  - <add points=5>I've added 5 points to your account.

These tags can not be used within C<+ Trigger>.

=head2 {topic=...}

Change the client's topic. This tag can only be used with C<* Condition> and
C<- Response>.

=head2 {weight=...}

When used with C<- Response>, this will weigh the response more heavily to be
chosen when random responses are available. When used with C<+ Trigger>, this
sets that trigger to have a higher matching priority.

=head2 {@...}, E<lt>@E<gt>

Perform an inline redirection. This should work like a regular redirection but
is embedded within another response. This tag can only be used with
C<- Response>, and in the response part of a C<* Condition>.

E<lt>@E<gt> is an alias for {@E<lt>starE<gt>}

  + your *
  - I think you meant to say "you are" or "you're", not "your". {@you are <star>}

=head2 {!...}

Perform an inline definition. This can be used just like the normal
C<! Definition> command from within a reply. This tag can only be used
with C<- Response>.

B<This tag is deprecated>. This tag's purpose was to redefine a global or bot
variable on the fly. Instead, the env and bot tags allow assignment.

  + set bot mood to *
  - <bot mood=<star>>Bot mood set to <star>.

=head2 {random}...{/random}

Insert a sub-set of random text. This tag can NOT be used with C<+ Trigger>. Use
the same array syntax as when defining arrays (separate single-word groups with
spaces and multi-word groups with pipes).

  + say something random
  - This {random}sentence statement{/random} has a random {random}set of words|gang of vocabulary{/random}.

=head2 {person}...{/person}, E<lt>personE<gt>

Process L<"person"> substitutions on a group of text.

  + say *
  - Umm... "<person>"

In that example, if the client says "say you are a robot", the bot should reply,
"Umm... "I am a robot.""

E<lt>personE<gt> is an alias for {person}E<lt>starE<gt>{/person}.

=head2 {formal}...{/formal}, E<lt>formalE<gt>

Formalize A String Of Text (Capitalize Every First Letter Of Every Word).

  + my name is *
  - Nice to meet you, <formal>.

E<lt>formalE<gt> is an alias for {formal}E<lt>starE<gt>{/formal}.

=head2 {sentence}...{/sentence}, E<lt>sentenceE<gt>

Format a string of text in sentence-case (capitilizing only the first letter
of the first word of each sentence).

E<lt>sentenceE<gt> is an alias for {sentence}E<lt>starE<gt>{/sentence}.

=head2 {uppercase}...{/uppercase}, E<lt>uppercaseE<gt>

FORMAT A STRING OF TEXT INTO UPPERCASE.

E<lt>uppercaseE<gt> is an alias for {uppercase}E<lt>starE<gt>{/uppercase}.

=head2 {lowercase}...{/lowercase}, E<lt>lowercaseE<gt>

format a string of text into lowercase.

E<lt>lowercaseE<gt> is an alias for {lowercase}E<lt>starE<gt>{/lowercase}.

=head2 {ok}

This is used only with the "request" trigger within the BEGIN block. It tells
the interpreter that it's okay to go and get a real response to the client's
message.

=head2 \s

Inserts a white space character. This is useful with the C<^ Continue>
command.

=head2 \n

Inserts a line break character.

=head2 \/

Inserts a forward slash.

=head2 \#

Inserts a pound symbol.

=head1 INTERPRETER IMPLEMENTATION

Interpreters of RiveScript should follow these guidelines when interpreting
RiveScript code. This details some of the priorities for processing tags and
sorting internal data structures. This part of the document should be
programming-language-independent.

=head2 STANDARD GLOBAL VARIABLES

The interpreter must support the following standard global variables:

  depth = a recursion limit before an attempt to fetch a reply will be abandoned.

It's recommended to also have a C<debug> variable for consistency, but it may
not be applicable.

The C<depth> variable is strongly encouraged, though. It's to set a user-defineable
recursion limit when fetching a response. For example, a pair of triggers like
this will cause infinite recursion:

  + one
  @ two

  + two
  @ one

The interpreter should protect itself against such possibilities and provide a
C<depth> variable to allow the user to adjust the recursion limit.

  ! global depth = 25

=head2 PARSING GUIDELINES

Interpreters should parse all of the RiveScript documents ahead of time and
store them in an efficient way in which replies can be looked up quickly.

=head3 Sorting +Triggers

Triggers should be sorted in a "most specific first" order. That is:

  1. Atomic triggers first. Sort them so that the triggers with the most amount
     of words are on top. For multiple triggers with the same amount of words,
     sort them by length, and then alphabetically if there are still matches
     in length.
  2. Sort triggers that contain optionals in their triggers next. Sort them in
     the same manner as the atomic triggers.
  3. Sort triggers containing wildcards next. Sort them by the number of words
     that aren't wildcards. The order of wildcard sorting should be as follows:

     A. Alphabetic wildcards (_)
     B. Numeric wildcards (#)
     C. Global wildcards (*)

  4. The very bottom of the list will be a trigger that simply matches * by
     itself, if it exists. If triggers of only _ or only # exist, sort them in
     the same order as in step 3.

=head3 Sorting %Previous

C<% Previous> triggers should be sorted in the same manner as C<+ Triggers>, and
associated with the reply group that they belong to (creating pseudotopics for
each C<% Previous> is a good way to go).

=head3 Syntax Checking

It will be helpful if the interpreter also offers syntax checking and will give
verbose warnings when it tries to parse something that doesn't follow standards.
When possible, it should try to correct the error, but should still emit a
warning so that the author might fix it.

It would also be good practice to keep track of file names and line numbers of
each parsed command, so that syntax warnings can direct the author to the exact
location where the problem occurred.

=head2 REPLY FETCHING

When attempting to get a response to a client's message, the interpreter should
support the sending of a "sender ID" along with the message. This would preferably
be a screen name or handle of the client who is sending the message, and the
interpreter should be able to keep different groups of user variables for each
user ID. The E<lt>idE<gt> tag should substitute for the user's ID.

If the BEGIN block was defined in any of the loaded RiveScript documents, it should
be tried for the "request" trigger. That is, this trigger should be matched:

  > begin
    + request
    - {ok}
  < begin

The interpreter should make the request for that trigger in the context of the
calling user, and allow it to change the user's topic or set a user variable
immediately. Do not process any other tags that are present in the response (see
L<"TAG PRIORITY">).

If the response contains the C<{ok}> tag, then make a second request to try to
match the client's actual message. When a response was found, substitute the
C<{ok}> tag from the BEGIN response with the text of the actual response the
client wanted, and then process any remaining tags in the BEGIN response.
Finally, return the reply to the client.

When fetching responses, the following order of events should happen.

  1. Build in a system of recursion prevention. Since replies can redirect to
     other replies, there's the possibility of deep recursion. The first thing
     that the reply fetching routine should do is prevent this from getting out
     of control.
  2. Dig through the triggers under the client's current topic. Check to see if
     there are any %Previous commands on any of these topics and see if they
     match the bot's last message to the client. If so, make sure the client's
     current message matches the trigger in question. If so, we have a response
     set; skip to step 4.
  3. Find a trigger that matches the client's message. If one is found, we have
     a response set; continue to step 4.

  4. If we found a reply set, process the reply. First check if this reply set
     has a "solid redirection" (an @ command). If so, recurse the response
     routine with the redirection trigger and resume from step 1. Break when an
     eventual response was returned.
  5. Process conditionals if they exist in order. As soon as one of them returns
     true, we have a response and break. If none are true, continue to step 6.
  6. See if there is more than one response to this trigger. If any of the random
     responses has a {weight}, take that into account as a random response is
     chosen. If we have a reply now, break.
  7. If there is still no reply, insert a generic "no reply" error message.

When a reply was obtained, then tags should be executed on them in the order
defined under L<"TAG PRIORITY">.

=head2 TAG PRIORITY

=head3 Within BEGIN/Request

Within the "request" response of the BEGIN block, the following tags can be
executed prior to getting a real response for the client's message:

  {topic}
  <set>

All other tags, especially modifier tags, must be held off until the final
response has been given. Substitute C<{ok}> for the final response, and then
process the other tags.

Things like this should be able to work:

  > begin

    + request
    * <get name> eq undefined => {topic=new_user}{ok}
    * <bot mood> eq happy     => {ok}
    * <bot mood> eq angry     => {uppercase}{ok}{/uppercase}
    * <bot mood> eq sad       => {lowercase}{ok}{/lowercase}
    - {ok}

  < begin

=head3 Within +Trigger

All tags that appear within the context of C<+ Trigger> must be processed prior
to any attempts to match on the trigger.

=head3 Within Replies

The order that the tags should be processed within a response or anywhere else
that a tag is allowed is as follows:

  <star>      # Static text macros
  <input>     #
  <reply>     #
  <id>        #
  \s          #
  \n          #
  \\          #
  \#          #
  {random}    # Random text insertion (which may contain other tags)
  <person>    # String modifiers
  <formal>    #
  <sentence>  #
  <uppercase> #
  <lowercase> #
  <bot>*      # Insert bot variables
  <env>*      # Insert environment variables
  <set>*      # User variable modifiers
  <add>*      #
  <sub>*      #
  <mult>*     #
  <div>*      #
  <get>*      # Get user variables
  {topic}     # Set user topic
  <@>         # Inline redirection
  <call>      # Object macros.

* The variable manipulation tags should all be processed "at the same time",
not in any particular order. This will allow, for example, the following sort
of trigger to work:

  + my name is *
  * <get name> != undefined =>
    ^ <set oldname=<get name>>I thought your name was <get oldname>?
    ^ <set name=<formal>>
  - <set name=<formal>>Nice to meet you.

In older implementations of RiveScript, `set` tags were processed earlier than
`get` making it impossible to copy variables. Implementations should process
this group of tags from the most-embedded outward.

An easy way to do this is with a regular expression that matches a tag that
contains no other tag, and make multiple passes until no tags remain that match
the regexp:

  /<([^<]+?)>/

=head1 REVERSE COMPATIBILITY

RiveScript 2.00 will have limited backwards compatibility with RiveScript 1.x
documents. Here is a full breakdown of the differences:

  RiveScript Changes from 1.02 to 2.00
  ------------------------------------

  REMOVED:

  - Variants of !DEFINITION
    - ! addpath
    - ! include
    - ! syslib
  - RiveScript Libraries (RSL files)
  - RiveScript Packages  (RSP files)
    - These made code management messy. Keep your own
      brain's files together!

  COMPATIBLE CHANGES:

  - Object macros now require the programming language to be defined.
    - Old way: > object encode
    - New way: > object encode perl
  - The ^CONTINUE command can extend every command.
  - Most tags can be used with almost every command.
  - Topics can inherit triggers from other topics now.

  INCOMPATIBLE CHANGES:

  - Conditionals work differently now. Instead of comparing variables to values,
    they compare values to values, and each value can <get> variables to compare.
    - Old way: * name       =  Bob => Hello Bob!
    - New way: * <get name> eq Bob => Hello Bob!
  - Conditionals no longer use a single = for "equal to" comparison. Replace it
    with either == or "eq".
  - Object macros will receive a reference to the RiveScript object as their first
    argument.
  - Objects are called in a new <call> syntax instead of the old &object one.

  NEW THINGS:

  - {weight} is a valid tag in triggers now to increase matching priority.
  - <env> has been added for calling global variables.
  - <botstar> has been added for wildcard matching on %previous.
  - Conditionals have more inequality comparisons now:
    "==" and "eq"        : equal to
    "!=", "ne", and "<>" : not equal to

Nice interpreters might be able to fix some old RiveScript code to make them work.
For example, if a condition is found that has one equals sign instead of two, it
could print a warning that it's detected RiveScript 1.x code in action and
automatically adjust it to 2.x standards, and perhaps reparse the entire file or
group of files, assuming that they are RiveScript 1.x code and fix these
inconsistencies altogether.

Or perhaps there will just be a converter tool created that would go through code
that it already assumes will be RiveScript 1.x and update it to 2.x standards.

=head1 REVISIONS

  Rev 12 - Nov 30, 2014
  - Added implementation guidelines for dealing with variable-setting tags.

  Rev 11 - Jun 13, 2013
  - Clarify the ability for the <bot> and <env> tags to be used for assignment.

  Rev 10 - May 15, 2012
  - Deprecated the {!...} tag. It was intended for reassigning global or bot
    variables. Instead use <env name=value>, <bot name=value>.

  Rev 9 - Jul 31, 2009
  - Added more explicit details on the usage of the BEGIN block, under the
    section on >Labels / "begin"
  - Revised the WD, fixing some typos.

  Rev 8 - Jul 30, 2009
  - The proper format for the `! version` line is to be `! version = 2.00`,
    and not `! version 2.00`
  - Included the "includes" option for triggers and changed how "inherits"
    works.

  Rev 7 - Dec  4, 2008
  - Topics are able to inherit additional triggers that belong to different
    topics, in the "> topic alpha inherits beta" syntax.
  - Added more documentation to the "! array" section of the document. Also
    check that section for some changes to the way arrays should be processed by
    the interpreter.
  - Deprecated the # command for inline comments. Use only // and /* */.

  Rev 6 - Sep 15, 2008
  - Updated the section about # for inline comments: when used next to a
    +Trigger, there should be at least 2 spaces before the # symbol and 1 space
    after, to avoid confusion with # as a wildcard character.

  Rev 5 - Jul 22, 2008
  - Added two new variants of the wildcard: # will match only numbers and _ will
    match only letters. * will still match anything at all.

  Rev 4 - Jun 19, 2008
  - Rearranged tag priorities:
    - <bot> and <env> moved higher up.

  Rev 3 - Apr  2, 2008
  - Typo fix: under the !person section, the examples were using !sub
  - Inconsistency fix: under %Previous it was saying the wildcards were
    unmatchable, but this isn't the case (they go into <botstar>).
  - Typo fix: under OBJECT MACROS, fixed the explanation of the code to match
    the new object syntax.
  - Inconsistency fix: <@> can be used in the response portion of conditionals.
  - Rearranged the tag priorities:
    - String modifiers (person - lowercase) come in higher priority than
      {random}
    - <env> comes in after <bot>
  - Typo fix: updated the object syntax (<call>) in the priority list.

  Rev 2 - Feb 18, 2008
  - Moved {random} to higher tag priority.
  - Change the &object syntax to <call>
  - Added the <env> variable.
  - Added the <botstar> variable.

  Rev 1 - Jan 15, 2008
  - Added the {priority} tag to triggers, to increase a trigger's matching
    priority over others, even when another trigger might be a better match
    to the client's message.

=head1 DISCLAIMER

Note that this document is only a working draft of the RiveScript 2.00
specification and may undergo numerous changes before a final standard is
agreed on. Changes to this document after the creation date on January 14, 2008
will be noted in a change log.

http://www.rivescript.com/

=cut
