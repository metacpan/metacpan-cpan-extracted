# Perform pdl demos on terminals

package PDLA::Demos::Routines;

# Copyright (C) 1998 Tuomas J. Lukka.
# All rights reserved, except redistribution
# with PDLA under the PDLA License permitted.

use Carp;
use PDLA;

@ISA="Exporter";
@EXPORT = qw/comment act actnw output/;

$SIG{__DIE__} = sub {die Carp::longmess(@_);};

sub home() {
   if (-e '/usr/bin/tput') {
      system 'tput clear';
   } elsif ( $^O eq 'MSWin32' ) {
      system 'cls';
   }
}

sub comment($) {
   home();
   print "----\n";
   print $_[0];
   my $prompt = "---- (press enter)";
   defined($PERLDL::TERM) ? $PERLDL::TERM->readline($prompt) : ( print $prompt, <> );
}

sub act($) {
   home();
   my $script = $_[0];
   $script =~ s/^(\s*)output/$1print/mg;
   print "---- Code:";
   print $script;
   print "---- Output:\n";
   my $pack = (caller)[0];
#	eval "package $pack; use PDLA; $_[0]";
   eval "package $pack; use PDLA; $_[0]";
   print "----\nOOPS!!! Something went wrong, please make a bug report!: $@\n----\n" if $@;
   my $prompt = "---- (press enter)";
   defined($PERLDL::TERM) ? $PERLDL::TERM->readline($prompt) : ( print $prompt, <> );
}

sub actnw($) {
   home();
   my $script = $_[0];
   $script =~ s/^(\s*)output/$1print/mg;
   print "---- Code:";
   print $script;
   print "---- Output:\n";
   my $pack = (caller)[0];
#	eval "package $pack; use PDLA; $_[0]";
   eval "package $pack; use PDLA; $_[0]";
   print "----\n";
   print "----\nOOPS!!! Something went wrong, please make a bug report!: $@\n----\n" if $@;
}

sub output {print @_}
