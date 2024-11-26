use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use PDL::Core::Dev;
use Devel::CheckLib;
use File::Which;

# Here we check for working curses/ncurses
# and the corresponding "curses.h" and "ncurses/curses.h"
#
# (1) Determine which library we have: curses or ncurses
# (2) determine which include path
# (3) determine which include file
# (4) confirm configuration
# (5) write Makefile or dummy as appropriate

sub _read_pipe {
   my (@command) = @_;
   open( my $fh, '-|', @command) or die "Unable to run @command: $!";
   chomp(my $output = do { local $/; <$fh> });
   $output;
}

my @possible_headers = qw( curses.h ncurses/curses.h ncurses.h ncurses/ncurses.h ncursesw/ncurses.h );
my $found_header;
foreach my $incl (@possible_headers) {
    if (eval { check_lib(header=>$incl) }) {
       $found_header = $incl;
       last;
    }
}

sub conf_via_ncurses_config {
   return () unless $found_header;
   # NOTE the ncurses*-config executables are shell scripts so `sh` is
   # required.
   return () unless File::Which::which('sh');
   my @nc_configs = qw(
      ncurses6-config
      ncursesw6-config
      ncurses5-config
      ncursesw5-config
   );
   for my $nc_conf (@nc_configs) {
      local $ENV{NCURSES_CONFIG_PROG} = $nc_conf;
      # NOTE which() can not find the script on Windows because it does have
      # have a PATHEXT suffix. For now, just try to run it anyway.
      next unless File::Which::which($nc_conf) || $^O eq 'MSWin32';
      if( eval { (my $version = _read_pipe(qw(sh -c), '$NCURSES_CONFIG_PROG --version')) =~ / \A [0-9.]+ \Z /x } ) {
         my $cflags = _read_pipe(qw(sh -c), '$NCURSES_CONFIG_PROG --cflags');
         my $libs   = _read_pipe(qw(sh -c), '$NCURSES_CONFIG_PROG --libs');
         return (
            header => $found_header,
            inc    => $cflags,
            libs   => $libs,
         );
      }
   }
   return ();
}

sub conf_via_checklib {
   return () unless $found_header;
   my $libstring;
   foreach my $libr ( qw( curses ncurses ncursesw ) ) {
      if (eval { check_lib(lib=>$libr) }) {
         $libstring = '-l' . $libr;
         last;
      }
   }
   if( defined $libstring ) {
      return (
         header => $found_header,
         inc    => '',
         libs   => $libstring,
      );
   }
   return ();
}

my %conf_data = conf_via_ncurses_config();
%conf_data = conf_via_checklib() unless %conf_data;
die "Curses capable library not found" if !%conf_data;

my @pack = (["browser.pd", qw(Browser PDL::IO::Browser)]);
my %hash = pdlpp_stdargs(@pack);
$hash{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'} = '7.14';
$hash{CONFIGURE_REQUIRES}{'PDL::Core::Dev'} = 0;
$hash{CONFIGURE_REQUIRES}{'Devel::CheckLib'} = 0;
$hash{CONFIGURE_REQUIRES}{'File::Which'} = 0;
$hash{PREREQ_PM}{'PDL'} = '2.095';
$hash{OBJECT} .= ' browse$(OBJ_EXT)';
$hash{clean}{FILES} .= ' browse$(OBJ_EXT) browse$(EXE_EXT) Browser.c Browser.pm Browser.xs Browser$(OBJ_EXT)';
$hash{DEFINE} .= ' -DCURSES=' . '\\"' . $conf_data{header} . '\\"';
$hash{INC} .= ' ' . $conf_data{inc} if $conf_data{inc};
$hash{LIBS}[0] .= $conf_data{libs};

# Add genpp rule
sub MY::postamble { pdlpp_postamble(@pack); }

WriteMakefile(
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.016',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-IO-Browser/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-IO-Browser.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-IO-Browser',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  %hash,
);
