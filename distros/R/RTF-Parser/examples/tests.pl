#!/usr/local/bin/perl -w

require 5.000;
use strict;

use Getopt::Long;
use File::Basename;

use vars qw/$BASENAME $DIRNAME/;

BEGIN {
    ( $BASENAME, $DIRNAME ) = fileparse($0);
}
use lib $DIRNAME;

select(STDOUT);

require RTF::HTML::Converter;
my $result;
my $self = new RTF::HTML::Converter( Output => \$result );

if (@ARGV) {
    foreach my $filename (@ARGV) {
        $self->parse_stream($filename);
        print $result;
        $result = '';
    }
} else {
    while (<DATA>) {
        s/\#.*//;
        next unless /\S/;
        print STDERR "-" x length($_), "\n";
        print STDERR "$_";
        print STDERR "-" x length($_), "\n";
        $self->parse_string($_);
        print $result;
        $result = '';
    }
}
__END__
#{} # Ok!
#{\par} # Ok!
#{string\par} # Ok!
#{\b bold {\i italic} bold \par} # Ok!
#{\b introduction \par } # Ok!
#{\b first B{\b0 mm{\b b}m}b} #!Ok
#{\b first B{\b0 mm{\b b}m}b\par} # !Ok
#{\i {\b first B{\b0 mm{\b b}m}b\par second B}} #!Ok
#{{\par }\b {Introduction\par }}
#{\pard\plain \b{Introduction\par }}
#{\b bold \i Bold Italic \i0 Bold again} # Ok!
#{\b bold {\i Bold Italic }Bold again} # Ok!
{\b bold \i Bold Italic \plain\b Bold again} # Ok!
