
require 5;
package Module::Versions::Report;
$VERSION = '1.06';
$PACKAGES_LIMIT = 10000;

=head1 NAME

Module::Versions::Report -- report versions of all modules in memory

=head1 SYNOPSIS

  use Module::Versions::Report;
  
  ...and any code you want...

This will run all your code normally, but then as the Perl
interpreter is about to exit, it will print something
like:

  Perl v5.6.1 under MSWin32.
   Modules in memory:
    attributes;
    AutoLoader v5.58;
    Carp;
    Config;
    DynaLoader v1.04;
    Exporter v5.562;
    Module::Versions::Report v1.01;
    HTML::Entities v1.22;
    HTML::HeadParser v2.15;
    HTML::Parser v3.25;
    [... and whatever other modules were loaded that session...]

Consider its use from the command line:

  % perl -MModule::Versions::Report -MLWP -e 1

  Perl v5.6.1 under MSWin32.
   Modules in memory:
    attributes;
    AutoLoader v5.58;
    [...]

=head1 DESCRIPTION

I often get email from someone reporting a bug in a module I've
written.  I email back, asking what version of the module it is,
what version of Perl on what OS, and sometimes what version of
some relevent third library (like XML::Parser).  They reply,
saying "Perl 5".  I say "I need the exact version, as reported
by C<perl -v>".  They tell me.  And I say "I, uh, also asked about
the version of my module and XML::Parser [or whatever]".  They say
"Oh yeah.  It's 2.27".  "Is that my module or XML::Parser?" 
"XML::Parser."  "OK, and what about my module's
version?"  "Ohyeah.  That's 3.11."  By this time, days have passed,
and what should have been a simple operation -- reporting the version
of Perl and relevent modules, has been needlessly complicated.

This module is for simplifying that task.  If you add "use
Module::Versions::Report;" to a program (especially handy if your
program is one that demonstrates a bug in some module), then when the
program has finished running, you well get a report detailing the all
modules in memory, and noting the version of each (for modules that
defined a C<$VERSION>, at least).

=head1 USING

=head2 Importing

If this package is imported then END block is set, and report printed to
stdout on a program exit, so use C<use Module::Versions::Report;> if you
need a report on exit or C<use Module::Versions::Report ();> otherwise
and call report or print_report functions yourself.

=cut

$Already = 0;

sub import {
  # so "use Module::Versions::Report;" sets up the END block, but
  # a mere "use Module::Versions::Report ();" doesn't.
  unless($Already) {
    eval 'END { print_report(); }';
    die "Extremely unexpected error in ", __PACKAGE__, ": $@" if $@;
    $Already = 1;
  }
  return;
}

=head2 report and print_report functions

The first one returns preformatted report as a string, the latter outputs
a report to stdout.

=cut

sub report {
  my @out;
  push @out,
    "\n\nPerl v",
    defined($^V) ? sprintf('%vd', $^V) : $],
    " under $^O ",
    (defined(&Win32::BuildNumber) and defined &Win32::BuildNumber())
      ? ("(Win32::BuildNumber ", &Win32::BuildNumber(), ")") : (),
    (defined $MacPerl::Version)
      ? ("(MacPerl version $MacPerl::Version)") : (),
    "\n"
  ;

  # Ugly code to walk the symbol tables:
  my %v;
  my @stack = ('');  # start out in %::
  my $this;
  my $count = 0;
  my $pref;
  while(@stack) {
    $this = shift @stack;
    die "Too many packages?" if $count > $PACKAGES_LIMIT;
    next if exists $v{$this};
    next if $this eq 'main'; # %main:: is %::

    #print "Peeking at $this => ${$this . '::VERSION'}\n";
    
    if(defined ${$this . '::VERSION'} ) {
      $v{$this} = ${$this . '::VERSION'};
      $count++;
    } elsif(
       defined *{$this . '::ISA'} or defined &{$this . '::import'}
# without perl version check on MacOS X's defualt perl things may seg fault
# for example Request Tracker 3.8's make test target fails additional tests
       or ($this ne '' and grep { ($] < 5.010 or ref $_ eq 'GLOB') and defined *{$_}{'CODE'} }
                           values %{$this . "::"})
       # If it has an ISA, an import, or any subs...
    ) {
      # It's a class/module with no version.
      $v{$this} = undef;
      $count++;
    } else {
      # It's probably an unpopulated package.
      ## $v{$this} = '...';
    }
    
    $pref = length($this) ? "$this\::" : '';
    push @stack, map m/^(.+)::$/ ? "$pref$1" : (), keys %{$this . '::'};
    #print "Stack: @stack\n";
  }
  push @out, " Modules in memory:\n";
  delete @v{'', '<none>'};
  foreach my $p (sort {lc($a) cmp lc($b)} keys %v) {
    #$indent = ' ' x (2 + ($p =~ tr/:/:/));
    push @out,  '  ',
      # $indent,
      $p, defined($v{$p}) ? " v$v{$p};\n" : ";\n";
  }
  push @out, sprintf "[at %s (local) / %s (GMT)]\n",
    scalar(localtime), scalar(gmtime);
  return join '', @out;
}

sub print_report { print '', report(); }

1;

=head1 COPYRIGHT AND DISCLAIMER

Copyright 2001-2003 Sean M. Burke. This library is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 MAINTAINER

Ruslan U. Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

__END__

