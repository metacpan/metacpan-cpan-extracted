use Config;
use File::Basename qw(basename dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '';

open(OUT,">$file") or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
#!/usr/bin/perl
use strict;
use lib qw(lib);
use base qw(Package::Base);
use File::Spec::Functions;
use Term::ANSIColor;

my $VERSION = 0.01;

use constant USAGE => "Usage: $0 My::Module\n";

#use constant OPT => <<_OPT_;
#
#_OPT_

my $fail         = colored('FAILED','red');
my $pass         = colored('  OK  ','green');

my $pack = shift @ARGV or print USAGE and exit(1);


make_directories($pack);
make_files($pack);

sub make_directories {
  my $pack = shift;
  my $base = mangle_pack($pack);

  my @tier = split '-',$base;
  pop @tier;

  my @dirs = (
              $base,
              catfile($base,'lib'),
              catfile($base,'t'),
              catfile($base,'bin'),
             );

  my @t = ();
  while(@tier){
    unshift @t, catfile($base,'lib',@tier);
    pop @tier;
  }
  push @dirs, @t;

  my $dformat = "mkdir %-50s [%s]%s\n";
  foreach my $dir (@dirs){
    if(mkdir($dir)){
      print sprintf($dformat,$dir,$pass,'');
    } else {
      print sprintf($dformat,$dir,$fail,colored(" $!",'red'));
    }
  }
}

sub make_files {
  my $pack = shift;
  my $base = mangle_pack($pack);

  my $fformat = "file  %-50s [%s]%s\n";

  #Changes
  if(make_file_Changes($pack)){
    print sprintf($fformat,catfile($base,'Changes'),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,'Changes'),$fail,colored(" $!",'red'));
  }

  #MANIFEST
  if(make_file_MANIFEST($pack)){
    print sprintf($fformat,catfile($base,'MANIFEST'),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,'MANIFEST'),$fail,colored(" $!",'red'));
  }

  #Makefile.PL
  if(make_file_Makefile($pack)){
    print sprintf($fformat,catfile($base,'Makefile.PL'),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,'Makefile.PL'),$fail,colored(" $!",'red'));
  }

  #README
  if(make_file_README($pack)){
    print sprintf($fformat,catfile($base,'README'),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,'README'),$fail,colored(" $!",'red'));
  }

  #pkg_config.in
  if(make_file_pkgconfig($pack)){
    print sprintf($fformat,catfile($base,'pkg_config.in'),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,'pkg_config.in'),$fail,colored(" $!",'red'));
  }

  #t/$base.t
  if(make_file_test($pack)){
    print sprintf($fformat,catfile($base,"t","$base.t"),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,"t","$base.t"),$fail,colored(" $!",'red'));
  }

  #lib/foo/bar.pm
  my @dirs = split '::',$pack;
  my $lib = pop @dirs;
  $lib .= '.pm';
  if(make_file_lib($pack)){
    print sprintf($fformat,catfile($base,"lib",@dirs,$lib),$pass,"");
  } else {
    print sprintf($fformat,catfile($base,"lib",@dirs,$lib),$fail,colored(" $!",'red'));
  }
}

sub make_file_lib {
  my $pack = shift;
  my $base = mangle_pack($pack);
  my @dirs = split '::', $pack;
  my $file = pop @dirs;
  $file .= '.pm';

  open(O,">",catfile($base,'lib',@dirs,$file)) or return 0;
  print O <<_END_;
=head1 NAME

$pack - DESCRIPTION of Class

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

=head2 Reporting Bugs

=head1 AUTHOR

Author E<lt>author\@localhostE<gt>

=head1 SEE ALSO


=head1 COPYRIGHT AND LICENSE

FIXME

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut


# Let the code begin...

package $pack;
use strict;
use base qw(Package::Base::Devel);
our \$VERSION = '0.01';

1;
_END_
  close(O);
}

sub mangle_pack {
  my $pack = shift;
  $pack =~ s/::/-/g;
  return $pack;
}

sub make_file_Changes {
  my $pack = shift;
  my $base = mangle_pack($pack);

  my $localtime = localtime();

  open(O,">".catfile($base,"Changes")) or return 0;
  print O <<"_END_";
Revision history for Perl extension $pack.

0.01 $localtime
\t- original version; created by $0 $VERSION

_END_
  close(O);
  return 1;
}

sub make_file_MANIFEST {
  my $pack = shift;
  my $base = mangle_pack($pack);

  my $pm = catfile('lib',split '-',$base).'.pm';

  my $localtime = localtime();

  open(O,">".catfile($base,"MANIFEST")) or return 0;
  print O <<"_END_";
Changes
MANIFEST
Makefile.PL
README
pkg_config.in
t/$base.t
$pm
_END_
  close(O);
  return 1;
}

sub make_file_Makefile {
  my $pack = shift;
  my $base = mangle_pack($pack);

  open(O,">".catfile($base,"Makefile.PL")) or return 0;
  print O <<"_END_";
use lib 'lib';
use Package::Install;
my \%sources = (); #put source.PL => 'description' pairs in here
my \%mm_args = (
                  'NAME'      => '$base',
                  'VERSION'   => '0.01',
                  'PREREQ_PM' => {
                                   'Package-Tools' => 0.01,
                                 },
                  'ABSTRACT'  => 'Describe extension here',
                  'AUTHOR'    => 'Author <author\@localhost>',
               );

my \$install = Package::Install->new(
  interactive => 1,
  sources     => \%sources,
                                    );

\$install->write_makefile(\%mm_args);
_END_
  close(O);
  return 1;
}

sub make_file_README {
  my $pack = shift;
  my $base = mangle_pack($pack);

  my $pm = catfile('lib',split '-',$base).'.pm';

  my $localtime = localtime();

  open(O,">".catfile($base,"README")) or return 0;
  print O <<"_END_";
$pack version 0.01
======================================================================

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the
README file from a module distribution so that people browsing the
archive can use it get an idea of the modules uses. It is usually a
good idea to provide version information here so that people can
decide whether fixes for the module are worth downloading.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  blah blah blah

COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) Author blah blah blah

_END_
  close(O);
  return 1;
}

sub make_file_pkgconfig {
  my $pack = shift;
  my $base = mangle_pack($pack);

  open(O,">".catfile($base,"pkg_config.in"));

print O <<'_END_';
#########################
#options requiring integer
[option integer]
#arbitrary int
opt_integer = 1
ambiguous = 1

#options requiring integers
[option integers]
#arbitrary ints
opt_integers = 0 1 2

#########################
#options requiring float
[option float]
#arbitrary float
opt_float = 3.14

#options requiring floats
[option floats]
#arbitrary floats
opt_floats = 3.14 -1.62

#########################
#options requiring string
[option string]
#arbitrary string
opt_string = phi

#options requiring strings
[option strings]
#arbitrary strings
opt_strings = pi "psi phi"

#########################
#options requiring dir
[option dir]
#system dir
opt_dir = /etc

#options requiring dirs
[option dirs]
#system dirs
opt_dirs = /etc /tmp

#########################
#options requiring file
[option file]
#path to a file
opt_file = /etc/passwd

#options requiring files
[option files]
#paths to files
opt_files = /etc/passwd /etc/group

#########################
#executables
[executable]
#a h2xs drop-in for creating Package-Tools based distros
#bin/pstub.PL = yes
_END_
  close(O);
}

sub make_file_test {
  my $pack = shift;
  my $base = mangle_pack($pack);

  open(O,">".catfile($base,'t',"$base.t"));
  print O <<_END_;
#test harness for $pack
BEGIN {
  use strict;
  use Test::More;
  plan tests => 2;
  use_ok('$pack', 'loaded $pack');
}

#put your tests here
ok(1,'example test');
_END_
  close(O);
}
!NO!SUBS!

close(OUT) or die "Can't close $file: $!";
chmod(0755,$file) or die "Can't change permissions for $file: $!";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
1;
