
#

use File::Find ;
sub finder {
  ($me, @search) = @_ ;
  my @paths = () ;
  find( sub {push @paths, $File::Find::name if /$me/ }, @search) ;
  return @paths ; 
}

my @cgi_paths	= qw(/usr/local/nagios /usr/lib/nagios /opt) ;
my @cfg_paths	= qw(/usr/local/nagios /usr/local/etc /etc /opt) ;

=begin comment

Want to edit Report.pm to change the paths in the constant statements.

use constant CGI_PATH                   => '/usr/lib/nagios/cgi/' ;
use constant LYNX                       => '/usr/bin/lynx' ;
use constant WGET                       => '/usr/bin/wget' ;

Note that WGET is only set if lynx is _not_ found.

=end comment

=cut

my @found = &finder('avail.cgi',@cgi_paths) ;
warn <<WARN
** Can't find Nagios availability CGI in '@cgi_paths'.
Unless this is a mistake can only use 'web_page' to get availability reports. 

WARN
  unless @found ;
my $avail_cgi = shift @found ;

my @found = &finder('lynx', split /:/, $ENV{PATH}) ;
warn "Can't find lynx in $PATH. Looking for wget." 
  unless @found ;
my $lynx = @found ? shift @found : '' ;

my $wget = '' ;
unless ( $lynx ) {
  @found = &finder('wget', split /:/, $ENV{PATH}) ;
  warn <<WARN
** Can't find either lynx or wget in $PATH.
Unless this is a mistake, can only use 'local_cgi' to get availability reports.

WARN
    unless @found ;
  $wget = @found ? shift @found : '' ;
}

=begin comment

# DATE FORMAT OPTION
# This option determines how short dates are displayed. Valid options
# include:
#       us              (MM-DD-YYYY HH:MM:SS)
#       euro            (DD-MM-YYYY HH:MM:SS)
#       iso8601         (YYYY-MM-DD HH:MM:SS)
#       strict-iso8601  (YYYY-MM-DDTHH:MM:SS)
#

date_format=euro

=end comment

=cut

   @found = &finder('nagios.cfg', @cfg_paths) ;
warn <<WARN
** Can't find Nagios configuration file 'nagios.cfg' in '@cfg_paths'.
This is necessary to set the constant EURO_DATE in the module so that
the date of a down is correctly interpreted.
Will leave EURO_DATE set. Hand edit Report.pm or submit PR.

WARN
  unless @found ;

my $nag_cfg = @found ? shift @found : '' ;
my $euro_date = 1 ;

if ( $nag_cfg ) {
  open C, '<', $nag_cfg
    or warn "Can't open '$nag_cfg' for input: $!" ;

  my $date_format = '' ;

  while ( <C> ) {
    $date_format = $1, last
      if /^date_format=(\w+)/ ;
  }

  $euro_date = $date_format && ($date_format eq 'euro') ? 1 : 0 ;
}

my $lynx_or_wget = !! ($lynx || $wget) ;
my ($cgi_path)   = $avail_cgi =~ m|^(.+?/)avail\.cgi| ;
my $use_lynx     = !! $lynx ;

my $mod_file     = 'Report.pm' ;

open F, '<', $mod_file
  or die "Can't open '$mod_file' for input: $!" ;

undef $/ ;

$_ = <F> ;

rename $mod_file, "$mod_file.bak"
  or die "Can't rename '$mod_file' to '$mod_file.bak': $!" ;

s{ ( use \s+ constant \s+ LYNX         \s+ => ) \s+ \S+ }{$1 '$lynx'}smx ;
s{ ( use \s+ constant \s+ WGET         \s+ => ) \s+ \S+ }{$1 '$wget'}smx ;
s{ ( use \s+ constant \s+ CGI_PATH     \s+ => ) \s+ \S+ }{$1 '$cgi_path'}smx ;
s{ ( use \s+ constant \s+ EURO_DATE    \s+ => ) \s+ \S+ }{$1 $euro_date}smx ;

close F ;

open F, '>', $mod_file
  or die "Can't open '$mod_file' for output: $!" ;

print F $_ ;

close F ;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Nagios::Report',
    'VERSION_FROM' => 'Report.pm', # finds $VERSION
);
