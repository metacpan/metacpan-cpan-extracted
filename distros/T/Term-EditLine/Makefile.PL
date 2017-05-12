BEGIN {
  unless(eval q{ use 5.008001; 1}) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker 6.52;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $cc      = $Config{cc};
my $ld      = $Config{ld};
my $libs    = '';
my $ccflags = $Config{ccflags};
my $alien   = 1;

foreach my $pkg_config ($ENV{PKG_CONFIG}, 'pkg-config', 'pkgconf')
{
  next unless defined $pkg_config;
  next if defined $ENV{ALIEN_INSTALL_TYPE} && $ENV{ALIEN_INSTALL_TYPE} eq 'share';

  system $pkg_config, '--exists', 'libedit';
  if($? == 0)
  {
    chomp(my $add_ccflags = `$pkg_config --cflags libedit`);
    $ccflags = join ' ', $add_ccflags, $ccflags;
    $libs   = `$pkg_config --libs libedit`;
    chomp $libs;
    $alien  = 0;
    last;
  }
}

if($alien)
{
  $cc = '$(FULLPERL) -Iinc -MAlien::Base::Wrapper=Alien::Editline -e cc --';
  $ld = '$(FULLPERL) -Iinc -MAlien::Base::Wrapper=Alien::Editline -e ld --';
}

WriteMakefile(
    'NAME'		=> 'Term::EditLine',
    'VERSION_FROM'	=> 'lib/Term/EditLine.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'Test::More' => 0.96,
    },
    'CONFIGURE_REQUIRES' => {
      "ExtUtils::MakeMaker" => "6.52",
    },
    'BUILD_REQUIRES' => {
      $alien ? ("Alien::Editline" => '0.07') : (),
    },
    'MIN_PERL_VERSION'  => '5.008001',
    'ABSTRACT_FROM'     => 'lib/Term/EditLine.pm',
    'AUTHOR'            => [ 'Graham Ollis <plicease@cpan.org>', 'Ulrich Burgbacher, <ulrich@burgbacher.net>' ],
    'CC'                => $cc,
    'LD'                => $ld,
    'LIBS'		=> [ $libs ], 
    'CCFLAGS'           => $ccflags,
    'INC'		=> '-I.', 
    'LICENSE'           => 'Perl_5',
    'realclean'         => { FILES => 'const-c.inc  const-xs.inc Term-EditLine-*' },
    'META_MERGE'        => {
      "meta-spec" => { version => 2 },
      "resources" => {
        "bugtracker" => {
          "web" => "https://github.com/plicease/Term-EditLine/issues",
        },
        "homepage" => "http://perl.wdlabs.com/Term-EditLine/",
        "repository" => {
          'type' => 'git',
          'url'  => 'git://github.com/plicease/Term-EditLine.git',
          'web'  => 'https://github.com/plicease/Term-EditLine.git',
        },
      },
    },
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CC_ARGHACK CC_CURSOR CC_EOF CC_ERROR CC_FATAL CC_NEWLINE
		 CC_NORM CC_REDISPLAY CC_REFRESH CC_REFRESH_BEEP EL_ADDFN
		 EL_BIND EL_BUILTIN_GETCFN EL_CLIENTDATA EL_ECHOTC EL_EDITMODE
		 EL_EDITOR EL_GETCFN EL_HIST EL_PROMPT EL_RPROMPT EL_SETTC
		 EL_SETTY EL_SIGNAL EL_TELLTC EL_TERMINAL H_ADD H_APPEND
		 H_CLEAR H_CURR H_END H_ENTER H_FIRST H_FUNC H_GETSIZE H_LAST
		 H_LOAD H_NEXT H_NEXT_EVENT H_NEXT_STR H_PREV H_PREV_EVENT
		 H_PREV_STR H_SAVE H_SET H_SETSIZE));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Term::EditLine',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
