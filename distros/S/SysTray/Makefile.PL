use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

if ($^O =~ /linux/) {
  # get KDE include dir
  my $kde_dir = `kde-config --prefix`;
  chomp $kde_dir;
  die "Could not get KDE headers folder" unless ($kde_dir);
  print "KDE componenets direcotry: $kde_dir\n";
  my $kde_include = "$kde_dir/include/kde";
  
  my $qt_dir = $ENV{'QTDIR'};
  die "Could not get QT componenets direcotry" unless ($qt_dir);
  print "QT componenets direcotry: $qt_dir\n";
  my $qt_include = "$qt_dir/include";

  `$qt_dir/bin/moc src/linux/tray.h -o src/linux/tray.moc.cpp`;
  `$qt_dir/bin/moc src/linux/mainwnd.h -o src/linux/mainwnd.moc.cpp`;

  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # the contents of the Makefile that is written.
  WriteMakefile(
      NAME              => 'SysTray',
      VERSION_FROM      => 'lib/SysTray.pm', # finds $VERSION
      PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM  => 'lib/SysTray.pm', # retrieve abstract from module
         AUTHOR         => '') : ()),
      LIBS              => ["-L/usr/X11R6/lib -L$qt_dir/lib -L$kde_dir/lib -lkdecore -lkdeui -lkhtml -ldl -lz -lm -lresolv -lpthread"], # e.g., '-lm'
      DEFINE            => '-DHAVE_CONFIG_H -DQT_THREAD_SUPPORT -D_REENTRANT -DPIC', # e.g., '-DHAVE_SOMETHING'
      INC               => "-I. -Isrc/linux -I$kde_include -I$qt_include -I/usr/X11R6/include", # e.g., '-I. -I/usr/include/other'
      OPTIMIZE          => '-O2 -fno-exceptions -fno-check-new -fPIC',
  	# Un-comment this if you add C files to link with later:
      OBJECT            => 'src/linux/tray.o src/linux/tray.moc.o src/linux/mainwnd.o src/linux/mainwnd.moc.o src/linux/kde_wrap.o SysTray.o', # link all the C files too
      CC                => 'g++',
      LD                => 'g++',
  );
} elsif ($^O =~ /Win32/) {
  WriteMakefile(
      NAME              => 'SysTray',
      VERSION_FROM      => 'lib/SysTray.pm', # finds $VERSION
      PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM  => 'lib/SysTray.pm', # retrieve abstract from module
         AUTHOR         => '') : ()),
      LIBS              => [':nosearch -lshell32 -lgdi32 -luser32'],
      INC               => "-I. -Isrc/win", # e.g., '-I. -I/usr/include/other'
      #LIBS              => [':nosearch -lcomctl32 -lcomdlg32 -lshell32 -lgdi32 -luser32 -lversion '],
      #C                 => [ "win_wrap.cpp" ], 
      OBJECT            => 'src/win/win_wrap.obj SysTray.obj', # link all the C files too
  );
} elsif ($^O =~ /darwin/) {
  WriteMakefile(
      NAME              => 'SysTray',
      VERSION_FROM      => 'lib/SysTray.pm', # finds $VERSION
      PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM  => 'lib/SysTray.pm', # retrieve abstract from module
         AUTHOR         => '') : ()),
      DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
      LIBS              => [ '-lobjc' ],
      INC               => "-I. -Isrc/osx -ObjC -arch i386 -arch ppc",
      dynamic_lib       => {
                          'OTHERLDFLAGS' =>
                          " -framework Foundation -framework AppKit -lobjc -arch i386 -arch ppc"
                        },
      OBJECT            => 'src/osx/TrayMenu.o src/osx/osx_wrap.o SysTray.o', # link all the C files too
  );
} else {
  die "Don't know how to write Makefile for $^O";
}

package MY;

sub c_o {
  # Tell the Makefile to put the .o files with the .c ones
  my $inherited = shift->SUPER::c_o(@_);
  if($^O =~ /darwin/) { # Mac
    $inherited =~ s{\$\*.c\n}{\$\*.c -o \$\*.o\n}mg;
  } elsif($^O =~ /Win32/) {     # Microsoft
    $inherited =~ s{\$\*.c\n}{\$\*.c -Fo\$\*.obj\n}mg;
  } else {                      # Linux/Other
    $inherited =~ s{\$\*.cpp\n}{\$\*.cpp -o \$\*.o\n}mg;
  }
  return $inherited;
}
