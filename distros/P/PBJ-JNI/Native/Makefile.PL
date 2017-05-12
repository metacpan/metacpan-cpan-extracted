# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can use, redistribute and/or
# modify it under the same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.3 2002/01/01 20:41:53 liang Exp $

use strict;
use File::Find;
use File::Basename;
use Config;
use ExtUtils::MakeMaker;

use vars qw(@java_so);

my ($java_home, @so_path, $my_objects);
my ($i, $this_dir, $l_list, $answer, @dir_list);
my (@libjvm_dir_list, @libjava_dir_list, @libhpi_dir_list);
my (@path);
my $os = $^O;
my $so = $Config{so};
my $obj_ext = $Config{obj_ext};

### ask about where is java installed.
@path = split /:/, $ENV{"PATH"};
for ($i = 0; $i < $#path; $i++) {
  if (-e $path[$i] . "/java") {
    # omit the current directory (bin).
    $java_home = dirname($path[$i]);
  }
}
print "\n";
print "Where is Java installed (aka JAVA_HOME)?\n";
print "For example, in JDK for Linux, it is usually /usr/java/jdkx.x.x.\n";
print "[$java_home]: ";
$answer = <STDIN>;
chomp($answer);
$java_home = $answer unless $answer eq "";

if(! -d $java_home) {
    die "Sorry but I have to know where is Java installed.";
}

### get path for libjava.so
sub get_libjava_dir {
  if (basename($File::Find::name) eq "libjava.$so") {
    $this_dir = $File::Find::dir;
  }
}
@dir_list = ($java_home);
find(\&get_libjava_dir, @dir_list);
die unless ($this_dir ne "");
push(@java_so, $this_dir);
$l_list = " -lpthread -ljava";

### get path for libjvm.so
sub get_libjvm_dir {
  if (basename($File::Find::name) eq "libjvm.$so") {
    push(@libjvm_dir_list, $File::Find::dir);
  }
}
@dir_list = ($java_home);
find(\&get_libjvm_dir, @dir_list);
print "\n";
print "There are the following JVMs you can choose from,\n";
for (my $i = 0; $i <= $#libjvm_dir_list; $i++) {
  print "($i) " . $libjvm_dir_list[$i] . "\n";
}
print "Which JVMs you want to use: ";
$answer = <STDIN>;
chomp($answer);
$answer = 0 unless ($answer ne "");
push(@java_so, $libjvm_dir_list[$answer]);
$l_list .= " -ljvm";

if ($libjvm_dir_list[$answer] =~ /\/classic/) {
  ### get path libhpi.so
  sub get_libhpi_dir {
    if (basename($File::Find::name) eq "libhpi.$so") {
      push(@libhpi_dir_list, $File::Find::dir);
    }
  }
  @dir_list = ($java_home);
  find(\&get_libhpi_dir, @dir_list);
  print "\nThere are the following JVM types you can choose from:\n";
  for (my $i = 0; $i <= $#libhpi_dir_list; $i++) {
    print "($i) " . $libhpi_dir_list[$i] . "\n";
  }
  print "Which type do you want to use: ";
  $answer = <STDIN>;
  chomp($answer);
  $answer = 0 unless ($answer ne "");
  push(@java_so, $libhpi_dir_list[$answer]);
  $l_list .= " -lhpi";
}

#print join(" ", map { "-L$_" } @java_so) . $l_list . "\n";

print "\n";

WriteMakefile(
	      'NAME'	=> 'PBJ::JNI::Native',
	      'VERSION_FROM' => 'Native.pm',
	      'LIBS'	=> join(" ", map { "-L$_" } @java_so) . $l_list,
	      'DEFINE'	=> '',
	      'INC'	=> "-I$java_home/include -I$java_home/include/$os",
	      'OBJECT'  => "Utils$obj_ext Native$obj_ext",
	      "AUTHOR"  => 'Ping Liang <ping@cpan.org>',
	      "PMLIBDIRS" => [ 'java' ],
	      "depend" => { "\$(OBJECT)" => '$(INST_ARCHAUTODIR)/libCallback.so' },
	      "clean" => { FILES => "Callback.h Callback.class libCallback.so" },
	     );

sub MY::postamble {
  '
Callback.h: $(INST_ARCHAUTODIR)/Callback.class
	javah -classpath $(INST_ARCHAUTODIR) Callback

$(INST_ARCHAUTODIR)/Callback.class: Callback.java
	javac -d $(INST_ARCHAUTODIR) Callback.java
	javac -d $(INST_ARCHAUTODIR) CallbackTest.java

$(INST_ARCHAUTODIR)/libCallback.$(DLEXT): Callback$(OBJ_EXT)
	$(LD) $(LDDLFLAGS) $(OPTIMIZE) -o $@ Callback$(OBJ_EXT)

Callback$(OBJ_EXT): Callback.c Callback.h
	$(CCCMD) $(INC) $(CCFLAGS) $(OPTIMIZE) -I$(PERL_INC) -o $@ Callback.c
';
}

