#!/usr/local/bin/perl -w

require 5.004;
use strict;
use lib '../lib';
use Parse::Template;

my %ancestor = 
  (
   'TOP' => q!ANCESTOR template: %%"'$part' part ->\n" . CHILD()%%!,
   'ANCESTOR' => q!ANCESTOR template: %%"'$part' part"%%!,
  );

my %parent =
  (
   'PARENT' => q!PARENT template:  %%"'$part' part ->\n" . ANCESTOR()%%!,
  );

my %child = 
  (
   'CHILD' => q!CHILD template:  %%"'$part' part ->\n" . PARENT() . "\n"%%!,
  );


my $A = new Parse::Template (%ancestor);
my $P = $A->new(%parent);
my $C = $P->new(%child);
print $C->TOP();

1;
__END__


