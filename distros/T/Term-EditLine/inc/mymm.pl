package mymm;

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker ();
use File::Copy ();
use File::Spec ();

sub myWriteMakefile
{
  my %args = @_;

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
    $args{BUILD_REQUIRES}->{'Alien::Editline'} = '0.07';
  }

  $args{CC}        = $cc;
  $args{LD}        = $ld;
  $args{LIBS}      = [ $libs ];
  $args{CCFLAGS}   = $ccflags;
  $args{INC}       = '-I.';
  $args{realclean} = { FILES => 'const-c.inc const-xs.inc' };

  ExtUtils::MakeMaker::WriteMakefile(%args);

  # these files are #included by EditLine.xs, and need to exist
  # before the .xs can be compiled.  If ExtUtils::Constant isn't
  # available then fall back on pre-generated copies.
  if(eval { require ExtUtils::Constant; 1 })
  {
    my @names = (qw(CC_ARGHACK CC_CURSOR CC_EOF CC_ERROR CC_FATAL CC_NEWLINE
                   CC_NORM CC_REDISPLAY CC_REFRESH CC_REFRESH_BEEP EL_ADDFN
                   EL_BIND EL_CLIENTDATA EL_ECHOTC EL_EDITMODE
                   EL_EDITOR EL_GETCFN EL_HIST EL_PROMPT EL_RPROMPT EL_SETTC
                   EL_SETTY EL_SIGNAL EL_TELLTC EL_TERMINAL H_ADD H_APPEND
                   H_CLEAR H_CURR H_END H_ENTER H_FIRST H_FUNC H_GETSIZE H_LAST
                   H_LOAD H_NEXT H_NEXT_EVENT H_NEXT_STR H_PREV H_PREV_EVENT
                   H_PREV_STR H_SAVE H_SET H_SETSIZE),
                # EL_BUILTIN_GETCFN is (NULL), not an integer; a plain IV
                # constant can't hold a pointer value, so surface it to
                # Perl as undef instead.
                { name => 'EL_BUILTIN_GETCFN', type => 'UNDEF', macro => 'EL_BUILTIN_GETCFN' });
    ExtUtils::Constant::WriteConstants(
      NAME         => 'Term::EditLine',
      NAMES        => \@names,
      DEFAULT_TYPE => 'IV',
      C_FILE       => 'const-c.inc',
      XS_FILE      => 'const-xs.inc',
    );
  }
  else
  {
    foreach my $file (qw( const-c.inc const-xs.inc ))
    {
      my $fallback = File::Spec->catfile('fallback', $file);
      File::Copy::copy($fallback, $file) or die "Can't copy $fallback to $file: $!";
    }
  }
}

1;
