
=Embedded

Literal text with an \EMBED{lang=html}<i>embedded</i>\END_EMBED part.

Here we go for more.

\EMBED{lang=HTML}

<i>This is embedded <b>HTML</b>.</i>

\END_EMBED

Here the literal \EMBED{lang=perl}"text"\END_EMBED continues.

\EMBED{lang=PERL}

# build a message
my $msg="Perl may be embedded as well.";

# and supply it
$msg;

\END_EMBED

\EMBED{lang=filtered}This part should be filtered out.\END_EMBED

Perl Point \EMBED{lang=pp}can \EMBED{lang=pp}be \EMBED{lang=pp}nested\END_EMBED\END_EMBED\END_EMBED.

Well.