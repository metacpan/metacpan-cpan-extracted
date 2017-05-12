# This CPAN/Config.pm file has hand-crafted for Vanilla Perl style
# distributions as a good generic product-agnostic default.
# However, the first time you run the CPAN "firsttime" or "o conf init"
# type process, it will overwrite this file and everything will revert
# to flattened and hardcoded strings.




# Find the main distribution paths
use Config ();
my $root     =  $Config::Config{'prefix'};
   $root     =~ s/\\perl$//;
my $cpan     =  "$root\\cpan";
my $minicpan =  "$root\\minicpan";
my $windows  =  $ENV{'SYSTEMROOT'} || "C:\\WINDOWS";
my $system32 =  "$windows\\system32";




# Derive the CPAN Config
$CPAN::Config = {
  applypatch                    => q[],
  auto_commit                   => q[1],
  build_cache                   => q[20],
  build_dir                     => "$cpan\\build",
  build_dir_reuse               => q[0],
  build_requires_install_policy => q[yes],
  bzip2                         => q[],
  cache_metadata                => q[0],
  check_sigs                    => q[0],
  colorize_output               => q[0],
  colorize_print                => q[bold blue on_white],
  colorize_warn                 => q[bold red on_white],
  commandnumber_in_prompt       => q[0],
  cpan_home                     => $cpan,
  curl                          => q[],
  ftp                           => "$system32\\ftp.exe",
  ftp_passive                   => q[1],
  ftp_proxy                     => q[],
  getcwd                        => q[cwd],
  gpg                           => q[],
  gzip                          => q[],
  histfile                      => "$cpan\\histfile",
  histsize                      => q[100],
  http_proxy                    => q[],
  inactivity_timeout            => q[0],
  index_expire                  => q[1],
  inhibit_startup_message       => q[0],
  keep_source_where             => "$cpan\\sources",
  load_module_verbosity         => q[none],
  lynx                          => q[],
  make                          => "$root\\c\\bin\\dmake.exe",
  make_arg                      => q[],
  make_install_arg              => q[UNINST=1],
  makepl_arg                    => "LIBS=-L$root\\c\\lib INC=-I$root\\c\\include",
  mbuild_arg                    => q[],
  mbuild_install_arg            => q[--uninst 1],
  mbuildpl_arg                  => q[],
  ncftp                         => q[],
  ncftpget                      => q[],
  no_proxy                      => q[],
  pager                         => "$system32\\more.com",
  patch                         => q[],
  prefer_installer              => q[MB],
  prefs_dir                     => "$cpan\\prefs",
  prerequisites_policy          => q[follow],
  scan_cache                    => q[atstart],
  shell                         => "$system32\\cmd.exe",
  show_unparsable_versions      => q[0],
  show_upload_date              => q[1],
  show_zero_versions            => q[0],
  tar                           => q[],
  tar_verbosity                 => q[none],
  term_is_latin                 => q[0],
  term_ornaments                => q[0],
  test_report                   => q[0],
  unzip                         => q[],
  urllist                       => [
      q[http://cpan.pair.com/],
      -d $minicpan ? ($minicpan) : (),
  ],
  use_sqlite                    => q[1],
  wget                          => q[],
  yaml_load_code                => q[0],
  yaml_module                   => q[YAML],
};

1;
