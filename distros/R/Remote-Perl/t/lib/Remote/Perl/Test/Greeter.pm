use strict;
use warnings;
package Remote::Perl::Test::Greeter;

my $TAGLINE = do { local $/; <DATA> };
chomp $TAGLINE;

sub greet       { "Hello, $_[0]!" }
sub tagline     { $TAGLINE }
sub interpreter { $^X }

1;
__DATA__
Spreading greetings since 1987.
