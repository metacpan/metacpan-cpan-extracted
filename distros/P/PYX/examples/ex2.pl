#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Parser;

# Open file.
my $file_handler = \*STDIN;
my $file = $ARGV[0];
if ($file) {
       if (! open(INF, '<', $file)) {
               die "Cannot open file '$file'.";
       }
       $file_handler = \*INF;
}

# PYX::Parser object.
my $parser = PYX::Parser->new(
'callbacks' => {
       	'start_element' => \&start_element,
       	'end_element' => \&end_element,
},
);
$parser->parse_handler($file_handler);

# Close file.
if ($file) {
       close(INF);
}

# Start element callback.
sub start_element {
       my ($self, $elem) = @_;
       print "Start of element '$elem'.\n";
       return;
}

# End element callback.
sub end_element {
       my ($self, $elem) = @_;
       print "End of element '$elem'.\n";
       return;
}