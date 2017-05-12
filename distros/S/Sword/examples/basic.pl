#!/usr/bin/env perl
use strict;
use warnings;

use Sword;
use List::Util qw( first );

my $library = Sword::Manager->new;

print "Your library contains:\n\n";
for my $module (sort { $a->type cmp $b->type } @{ $library->modules }) {
    print "    ", $module->type, ": ", $module->name, " - ", 
	  $module->description, "\n";
}

print "\n";

# Try a preferred list of Bibles...
my $bible = $library->get_module('ESV')
         || $library->get_module('KJV');

# Or find any Bible...
$bible = first { $_->type eq 'Biblical Texts' } @{ $library->modules };

if ($bible) {
    $bible->set_key('John 3:16'); # can us abbrevs, like jn3.16
    my $verse = $bible->render_text;
    print "John 3:16: $verse\n";
}

else {
    print "No Bible was found in your library. You may need to open your Sword software to install one.\n";
}

print "\n\n";

my $dict = $library->get_module('WebstersDict');
if ($dict) {
    $dict->set_key('dictionary');
    my $description = $dict->description;
    print "According to $description:\n\n";
    print $dict->render_text, "\n";
}
