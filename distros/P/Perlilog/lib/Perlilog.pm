#
# This file is part of the Perlilog project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

require 5.004;
use Perlilog::PLerror;
package Perlilog;
use Perlilog::PLerror;
use strict 'vars';

BEGIN {
  @Perlilog::warnings = ();
  %Perlilog::classes = ();
  $SIG{__WARN__} = sub {
    my ($class) = ($_[0] =~ /unquoted string.*?\"(.*?)\".*may clash/i);
    if (defined $class) {
      push @Perlilog::warnings, $_[0]; 
    } else {
      warn ($_[0])
    }
  };
}

END {
  $SIG{__WARN__} = sub {warn $_[0]; }; # Prevent an endless recursion
  foreach (@Perlilog::warnings) {
    my ($class) = ($_ =~ /unquoted string.*?\"(.*?)\".*may clash/i);
    warn ($_) 
      unless (defined $Perlilog::classes{$class});
  }
}

# We use explicit package names rather than Perl 5.6.0's "our", so
# perl 5.004 won't yell at us.

@Perlilog::ISA = (Exporter);
@Perlilog::EXPORT = qw[&init &override &underride &inherit &inheritdir &interface &interfaceclass
		       &constreset &definedclass &globalobj &execute];
$Perlilog::VERSION = '1.0';
$Perlilog::STARTTIME = localtime();

$Perlilog::perlilogflag = 0;
$Perlilog::globalobject=();
$Perlilog::interface_rec = undef;
@Perlilog::interface_excuses = ();

unless ($Perlilog::perlilogflag) {
  $Perlilog::perlilogflag = 1; # Indicate that this clause has been run once
  $Perlilog::errorcrawl='system';
  $Perlilog::callbacksdepth = 0; # This indicates when callbacks are going on.
  undef $Perlilog::wrong_flag;

  #For unloaded classes: Value is [classfile, parent class, first-given classname].
  %Perlilog::classes = ('PL_hardroot', 1);
  %Perlilog::objects = ();
  @Perlilog::VARS=(undef, undef); # First two variables may be addressed accidentally
  @Perlilog::EQVARS=(undef, undef); # The first two point to themselves.
  @Perlilog::interface_classes = ();
  $Perlilog::objectcounter = 0;
  
  {
    my $home = $INC{'Perlilog.pm'};
    ($home) = ($home =~ /^(.*)Perlilog\.pm$/);
    blow("Failed to resolve Perlilog.pm's directory")
      unless (defined $home);
    $Perlilog::home = $home;
  }

  $Perlilog::classhome = "${Perlilog::home}Perlilog/sysclasses/";
  inherit('root',"${Perlilog::classhome}PLroot.pl",'PL_hardroot');
  inherit('codegen',"${Perlilog::classhome}PLcodegen.pl",'root');
  inherit('verilog',"${Perlilog::classhome}PLverilog.pl",'codegen');
  inherit('global',"${Perlilog::classhome}PLglobal.pl",'codegen');
  inherit('port',"${Perlilog::classhome}PLport.pl",'root');
  inherit('interface',"${Perlilog::classhome}PLinterface.pl",'verilog');
  inherit('site_init',"${Perlilog::classhome}site_init.pl",'PL_hardroot');
}

sub init {
  site_init -> init;
}
sub inherit {
  my $class = shift;
  my $file = shift;
  my $papa = shift;

  puke("Attempt to create the already existing class \'$class\'\n")
    if $Perlilog::classes{$class};

  puke("No parent class defined for \'$class\'\n")
    unless (defined $papa);
  $Perlilog::classes{$class} = [$file, $papa, $class];
  # The following two lines are a Perl 5.8.0 bug workaround (early
  # versions). Google "stash autoload" for why.
  undef ${"${class}::Perlilog_dummy_variable"}; 
  undef ${"${class}::Perlilog_dummy_variable"}; # No single use warning...
  return 1;
}

sub inheritdir {
  my $dir = shift;
  my $papa = shift;

  ($dir) = ($dir =~ /^(.*?)[\/\\]*$/); # Remove trailing slashes

  blow("Nonexistent directory \'$dir\'\n")
    unless (-d $dir);

  do_inheritdir($dir, $papa);
  return 1;
}

sub do_inheritdir {
  my $dir = shift;
  my $papa = shift;

  ($dir) = ($dir =~ /^(.*?)[\/\\]*$/); # Remove trailing slashes

  return unless (opendir(DIR,$dir));
  my @files=sort readdir(DIR);
  closedir(DIR);
  my @dirs = ();
  my %newclasses = ();

  foreach my $file (@files) {
    next if (($file eq '.') || ($file eq '..'));
    my $thefile = $dir.'/'.$file;

    if (-d $thefile) {
      next unless ($file =~ /^[a-zA-Z][a-zA-Z0-9_]*$/);
      push @dirs, $file, $thefile;
    } else {
      my ($class) = ($file =~ /^([a-zA-Z][a-zA-Z0-9_]*)\.pl$/i);
      next unless (defined $class);
      $class = lc $class; # Lowercase the class
      blow("inheritdir: Attempt to create the already existing class \'".$class.
	   "\' with \'$thefile\' (possibly symbolic link loop?)\n")
	if ($Eobj::classes{$class});
      inherit($class, $thefile, $papa);
      $newclasses{$class} = 1;
    }
  }
  while ($#dirs > 0) { # At least two entries...
    my $newpapa = lc shift @dirs;
    my $descend = shift @dirs;
    
    blow("inheritdir: Could not descend to directory \'$descend\' because there was no \'".
	 $newpapa.".pl\' file in directory \'$dir\'\n")
      unless ($newclasses{$newpapa});
    do_inheritdir($descend, $newpapa);
  }
}

sub override {
  my $class = shift;
  my $file = shift;
  my $papa = shift;

  unless ($Perlilog::classes{$class}) {
    return inherit($class, $file, $papa)
      if defined ($papa);
    puke("Tried to override nonexisting class \'$class\', and no alternative parent given\n");
  }

  puke("Attempt to override class \'$class\' after it has been loaded\n")
    unless ref($Perlilog::classes{$class});

  # Now create a new name for the previous class pointer

  my $newname=$class.'_PL_';
  my $i=1;
  while (defined $Perlilog::classes{$newname.$i}) {$i++;}
  $newname=$newname.$i;
  
  # This is the operation of overriding

  $Perlilog::classes{$newname}=$Perlilog::classes{$class};
  $Perlilog::classes{$class}=[$file, $newname, $class];

  # The following two lines are a Perl 5.8.0 bug workaround (early
  # versions). Google "stash autoload" for why.
  undef ${"${newname}::Perlilog_dummy_variable"};
  undef ${"${newname}::Perlilog_dummy_variable"}; # No single use warning

  return 1;
}

sub underride {
  my $class = shift;
  my $file = shift;

  unless ($Perlilog::classes{$class}) {
    puke("Tried to underride a nonexisting class \'$class\'\n");
  }

  puke("Attempt to underride class \'$class\' after it has been loaded\n")
    unless ref($Perlilog::classes{$class});

  # Now create a new name for the previous class pointer

  my $newname=$class.'_PL_';
  my $i=1;
  while (defined $Perlilog::classes{$newname.$i}) {$i++;}
  $newname=$newname.$i;
  
  my $victim = $class;

 # Now we look for the grandfather
 SEARCH: while (1) {
    my $parent = ${$Perlilog::classes{$victim}}[1];
    if (${$Perlilog::classes{$parent}}[2] ne $class) { # Same family?
      last SEARCH;
    } else {
      $victim = $parent; # Climb up the family tree
    }
  }
  # This is the operation of parenting

  $Perlilog::classes{$newname}=[$file, ${$Perlilog::classes{$victim}}[1], $class];
  ${$Perlilog::classes{$victim}}[1]=$newname;

  # The following two lines are a Perl 5.8.0 bug workaround (early
  # versions). Google "stash autoload" for why.
  undef ${"${newname}::Perlilog_dummy_variable"};
  undef ${"${newname}::Perlilog_dummy_variable"}; # No single use warning.
  return 1;
}

#definedclass:
#0 - not defined, 1 - defined but not loaded, 2 - defined and loaded

sub definedclass {
  my $class = shift;
  my $p = $Perlilog::classes{$class};
  return 0 unless (defined $p);
  return 1 if ref($p);
  return 2;
}

sub interfaceclass {
  my $class = shift;
  puke("The class \'$class\' is not defined, and hence cannot be declared as an interface class\n")
    unless (definedclass($class));
  push @Perlilog::interface_classes, $class;
}

sub classload {
  my ($class, $schwonz) = @_;
  my $p = $Perlilog::classes{$class};
  my $err;

  blow($schwonz."Attempt to use undeclared class \'$class\'\n")
    unless (defined $p);

  # If $p isn't a reference, the class has been loaded.
  # This trick allows recursive calls.
  return 1 unless ref($p);

  $Perlilog::classes{$class} = 1;

  my ($file, $papa, $original) = @{$p};

  classload($papa, $schwonz); # Make sure parents are loaded

  # Now we create the package wrapping

  my $d = "package $class; use strict 'vars'; use Perlilog::PLerror;\n";
  $d.='@'.$class."::ISA=qw[$papa];\n";

  # Registering MUST be the last line before the text itself,
  # since the line number is recorded. Line count in error
  # messages begin immediately after the line that registers.

  $d.="&Perlilog::PLerror::register(\'$file\');\n# line 1 \"$file\"\n";

  open (CLASSFILE, $file) || 
    blow($schwonz."Failed to open resource file \'$file\' for class \'$class\'\n");
  $d.=join("",<CLASSFILE>);
  close CLASSFILE;
  eval($d);
  blow ($schwonz."Failed to load class \'$original\':\n $@")
    if ($@);
}

sub globalobj {
  return $Perlilog::globalobject if (ref $Perlilog::globalobject);
  puke("Global object was requested before init() was executed\n");
}

sub constreset {
  return globalobj()->constreset(@_);
}

sub execute {
  globalobj()->execute();
}

sub interface {
  puke("Attempt to call 'interface' from within an interface object (use intobjects instead)\n")
    if (defined $Perlilog::interface_rec);

  my $g=globalobj();

  puke("interface() called with non-object item\n")
    if (grep {not ($g->isobject($_))} @_);

  $Perlilog::interface_rec = globalobj->get('MAX_INTERFACE_REC');
  @Perlilog::interface_excuses=();

  my @obj=intobjects(@_);

  undef $Perlilog::interface_rec;

  if (@obj) {
    foreach (@obj) {
      $_->sustain();
    }
    return $obj[0];
  } else {
    my $p;
    my @names=();

    foreach $p (@_) {
      if ($g->isobject($p)) {
	push @names, $p->who();
      } else {
	push @names, "(Non-object item)";
      }
    }

    my $excuses = "";
    chomp @Perlilog::interface_excuses;
    foreach (@Perlilog::interface_excuses) {
      $excuses.="$_\n";
    }
    
    $excuses = "No adequate interface object found\n"
      unless (length($excuses));

    wrong("Failed to interface between ports:\n".
	  join("\n", @names)."\n----------\n$excuses");
    return undef;
  }
}

sub intobjects {
  puke("intobjects should be called only from within interface classes\n")
    unless (defined $Perlilog::interface_rec);
  if ($Perlilog::interface_rec<0) {
    fishy("Maximal interface object recursion (MAX_INTERFACE_REC) was reached. ".
	  "Are the interface objects registered in the wrong order, or is the design ".
	  "very complex?\n");
    return ();
} 
  my $c;
  my @obj;
  $Perlilog::interface_rec--;
  
  foreach $c (@Perlilog::interface_classes) {
    @obj = $c->attempt(@_);
    if (@obj) {
      if (globalobj()->isobject($obj[0])) {
	$obj[0]->set('perlilog-ports-to-connect', @_);
	last;
      }
      push @Perlilog::interface_excuses, "class $c: ".$obj[0]
	if (defined ($obj[0]) && $obj[0]=~/[a-z]/i);
      @obj=();
    }
  }
  $Perlilog::interface_rec++;
  return @obj;      
}

# This routine attempts to keep lines below 80 chrs/lines
sub linebreak {
  my $data = shift;
  my $extraindent = shift;

  $extraindent = '' unless (defined $extraindent);

  my @chunks = split("\n", $data);

  foreach (@chunks) {
    my $realout = '';
    while (1) { # Not forever. We'll break this in proper time
      if (/^.{0,79}$/) { # The rest fits well...
	$realout .= $_;
	last;
      }
      # We try to break the line after a comma.
      my ($x, $y) = (/^(.{50,78},)\s*(.*)$/);
      # Didn't work? A whitespace is enough, then.
      ($x, $y) = (/^(.{50,79})\s+(.*)$/)
	unless (defined $x);
      # Still didn't work? Break at first white space.
      ($x, $y) = (/^(.{50,}?)\s+(.*)$/)
	unless (defined $x);
      
      # THAT didn't work? Give up. Just dump it all out.
      unless (defined $x) {
	$realout .= $_;
	last;
      } else { # OK, we have a line split!
	$realout .= $x."\n";
	$_ = $extraindent.$y; # The rest, only indented.
      }
    }
    $_ = $realout;
  }
  my $final = join("\n", @chunks);
  $final .= "\n" if ($data =~ /\n$/);
  return $final;
}

# Just empty packages (used by PLroot).
package PL_hardroot;
package PL_settable;
package PL_const;

# And now the magic of autoloading.
package UNIVERSAL;
use Perlilog::PLerror;
$UNIVERSAL::errorcrawl='skip';
%UNIVERSAL::blacklist=();

sub AUTOLOAD {
  my $class = shift;
  my $method = $UNIVERSAL::AUTOLOAD;
  my ($junk,$file,$line)=caller;
  my $schwonz = "at $file line $line";
  return undef if $method =~ /::SUPER::/;

  my ($package) = $method =~ /^(.*?)::/;
  $method =~ s/.*:://;

  my $name = ref($class);

  return undef if ($method eq 'DESTROY');
  
  print "$class, $package\n"  unless ($class eq $package);
  puke("Undefined function/method \'$method\' $schwonz\n")
    unless ($class eq $package);

  if ($name) {
    # Forgive. This is not our class anyway...
    return undef;
  }

  # Now we protect ourselves against infinite recursion, should
  # the classload call fail silently. This will happen if the
  # first attempt to call a method in a class is to a
  # method that isn't defined.
  puke("Undefined method \'$method\' in class \'$class\' $schwonz\n")
    if $UNIVERSAL::blacklist{$class};
  $UNIVERSAL::blacklist{$class}=1;

  &Perlilog::classload($class,
		       "While trying to load class \'$class\' due to call ".
		       "of method \'$method\' $schwonz:\n");
 
  #Just loaded the new class? Let's use it!
  return $class->$method(@_);
}

# Now have the "defineclass" subroutine defined, so we can use it to
# generate bareword warnings for anything but a class name.



1; # Return true

__END__

=head1 NAME

Perlilog - Verilog environment and IP core handling in Perl

=head1 SYNOPSIS

  use Perlilog; 

=head1 DESCRIPTION

The project is extensively documented in Perlilog's user guide, which can be downloaded at L<http://www.billauer.co.il/perlilog.html>.

In wide terms, Perlilog is a Perl environment for Verilog code manipulation. It supplies the Perl programmer
with several strong tools for managing Perl modules and connecting between them.

Originally, Perlilog was intended for integration of Verilog IP cores, but it's useful for the following
tasks as well:

=over 4

=item *

Scripts that generate Verilog code automatically

=item *

"Hook-up" of modules: Assigning pins, connecting to ASIC pads, etc.

=item *

Automatic generation of buses and bus controllers, with a variable number of members and parametrized
arbitration rules

=item *

Automatic generation of bridges when needed to interface between different bus protocols

=back

=head1 AUTHOR

Eli Billauer, E<lt>eli.billauer@gmail.comE<gt>

=head1 SEE ALSO

The Perlilog project's home page: L<http://www.billauer.co.il/perlilog.html>

The Eobj project: L<http://www.billauer.co.il/eobj.html>

=cut
