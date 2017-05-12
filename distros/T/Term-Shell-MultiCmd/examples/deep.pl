
# This example would demonstrate many commands, and deep tree. It's also a way
# to check out the beloved 'help -tree' feature.
#
# The commands would do as little as self description (narcissism never suited me, but yet)

use strict ;
use warnings ;
use lib 'lib', '../lib' ;
use Term::Shell::MultiCmd;
my $cmd = { help => " The default function.
All I do is printing my own name.",
            exec => sub {
                my ($o, %p) = @_ ;
                print "I am $p{ARG0}\n" ;
            },
          } ;

my $allCommands = <<AllCommands ;
a very deep command tree, by Dr. Seuss
as we all suspected, Dr. Seuss was a perl programmer
I could not, would not, in a house.
I would not, could not, with a mouse.
I would not eat them with a fox.
I would not eat them in a box.
I would not eat them here or there.
I would not eat them anywhere.
I would not eat green eggs and ham.
I do not like them, Sam-I-am
AllCommands


print <<"Hi" ;
$allCommands

To rebuild the sentences, try to use the command completion.
To see the whole command tree, try "help -t"
Hi

Term::Shell::MultiCmd
  -> new()
  -> populate ( map {$_ => $cmd } split /^/m, $allCommands )
  -> loop ;

