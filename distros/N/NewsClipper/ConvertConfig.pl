#!/usr/bin/perl
# use perl                                  -*- mode: Perl; -*-

use strict;

# The version of the config
my $NC_CONFIG_VERSION = '1.30';

my $VERSION = 0.40;

#-------------------------------------------------------------------------------

die <<EOF
$0 /path/NewsClipper.cfg

Run this program to modernize a NewsClipper.cfg file from a version of News
Clipper prior to $NC_CONFIG_VERSION
EOF
  if $#ARGV == -1 || $ARGV[0] =~ /^-/;

my $configFile = $ARGV[0];
open CFG,$configFile or die "Can't open \"$configFile\": $!\n";
my $code = join '',<CFG>;
close CFG;

my $old_code = $code;

my $old_version = GetNewsClipperVersion($code);

if (defined $old_version && $old_version >= $NC_CONFIG_VERSION)
{
  print <<"  EOF";
Your existing NewsClipper.cfg file is for News Clipper version
$old_version, and this ConverConfig will update up to version
$NC_CONFIG_VERSION. No need to update.
  EOF
  exit;
}

if ($old_version < 1.18)
{
  $code = ConvertHandlerConfig($code);
  $code = AddAutoDownload($code);
  $code = AddFTP($code);
}

if ($old_version < 1.21)
{
  $code = AddUpdateNewsClipperVersion($code,$NC_CONFIG_VERSION);
}

if ($old_version < 1.29)
{
  $code = AddTagText($code);
  $code = AddChmod($code);
  $code = AddLogging($code);
  $code = UpdateOptionNames($code);
  $code = AddUpdateNewsClipperVersion($code,$NC_CONFIG_VERSION);
}

if ($old_version < 1.30)
{
  $code = AddEmail($code);
  $code = AddUpdateNewsClipperVersion($code,$NC_CONFIG_VERSION);
}

if ($old_code eq $code)
{
  print "No change to NewsClipper.cfg -- nothing written\n";
}
else
{
  WriteConfig($configFile,$code);
}

#-------------------------------------------------------------------------------

sub ConvertHandlerConfig
{
  my $code = shift;

  my $imgCache;
  ($code,$imgCache) = ExtractImgCache($code);

  $code =~ s/\n*1;\n*/\n\n/s;

  $code .=<<"  EOF";
# -----------------------------------------------------------------------------

\%NewsClipper::Handler::Filter::cacheimages::handlerconfig = (

$imgCache
);

# -----------------------------------------------------------------------------

1;
  EOF

  return $code;
}

#-------------------------------------------------------------------------------

sub AddAutoDownload
{
  my $code = shift;

  my $auto_download_bugfix_updates=<<'  EOF';
# Automatically download any bugfix handlers. (Checks every few hours.)
'auto_download_bugfix_updates' => 'yes',

  EOF

  $code =~ s/\n+(\);\s*# --------------)/\n\n$auto_download_bugfix_updates$1/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub AddFTP
{
  my $code = shift;

  my ($outputFilesCode) = $code =~ /outputFiles.*?\[(.*?)\]/s;

  $outputFilesCode =~ s/(["'])\s*$/$1,/s;

  my $numFiles = ($outputFilesCode =~ tr/,//);


  my $ftp=<<'  EOF';
# ftpFiles allows you to ftp your output files to your web server. Make sure
# there is one set of data for each output file.  The first set applies to the
# first output file, the second set to the second output file, etc. If you
# don't want to FTP a file, just use {} for the information.
'ftpFiles' => [
  EOF

  $ftp .= "  {},\n" x $numFiles;

  $ftp .=<<'  EOF';
#  {'server'   => 'SERVER',
#   'username' => 'USER NAME',
#   'password' => 'PASSWORD',
#   'dir'      => 'DEST DIR'},
],
  EOF

  $code =~ s/('outputFiles.*?\]\s*,)\s*/$1\n\n$ftp\n/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub AddEmail
{
  my $code = shift;

  my ($ftp_file_code) = $code =~ /(ftp_files.*?\[.*?\].*?\n)/s;

  my $email=<<'  EOF';
# email_files allows you to email your output files to one or more email
# addresses. Make sure there is one set of emails for each output file.  The
# first set applies to the first output file, the second set to the second
# output file, etc. If you don't want to email a file, just use [] for the
# information. The example shows how to send one output file.
'email_files' => [
#  {'From'    => 'News Clipper <newsclipper@your.server>',
#   'To'      => 'First Person <person1@their.server>',
#   'Cc'      => '',
#   'Bcc'     => '',
#   'Subject' => 'Newsletter'},
],
  EOF

  $code =~ s/(ftp_files.*?\[.*?\].*?\n)/$1\n$email/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub GetNewsClipperVersion
{
  my $code = shift;

  my ($for_news_clipper_version) =
    $code =~ /'(?:for_news_clipper_version|forNewsClipperVersion)' *=> *(.*?) *,/s;

  # Ug. Pre "forNewsClipperVersion" days...
  if (!defined $for_news_clipper_version)
  {
    # A 1.18-style config file.
    if ($code =~ /ftpFiles/)
    {
      return 1.18;
    }
    else
    {
      return 1.00;
    }
  }
  else
  {
    return $for_news_clipper_version;
  }
}

# -----------------------------------------------------------------------------

sub AddUpdateNewsClipperVersion
{
  my $code = shift;
  my $NC_CONFIG_VERSION = shift;

  my ($nc_version_code,$for_news_clipper_version) =
    $code =~ /('(?:for_news_clipper_version|forNewsClipperVersion)' *=> *(.*?) *,)/s;

  if (defined $nc_version_code)
  {
    my $new_version_code = $nc_version_code;
    $new_version_code =~ s/\Q$for_news_clipper_version\E/$NC_CONFIG_VERSION/;
    $code =~ s/\Q$nc_version_code\E/$new_version_code/s;
  }
  else
  {
    my $new_version_code =<<"    EOF";
# This value lets News Clipper know if the configuration file is incompatible.
'forNewsClipperVersion' => $NC_CONFIG_VERSION,
    EOF
    $code =~ s/(\%config *= *\( *\n)/$1\n$new_version_code/s;
  }

  return $code;
}

# -----------------------------------------------------------------------------

sub AddTagText
{
  my $code = shift;

  my $add_code =<<EOF;
# The keyword to indicate News Clipper commands. The default is "newsclipper",
# which results in <!-- newsclipper ... --> as the default command comment.
'tag_text' => 'newsclipper',

EOF

  $code =~ s/(auto_download_bugfix.*?\n)(\);)/$1$add_code$2/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub AddChmod
{
  my $code = shift;

  my $add_code =<<EOF;
# Determines whether output files should be made executable as well as
# readable.
'make_output_files_executable' => 'yes',

EOF

  $code =~ s/(tag_text.*?\n)(\);)/$1$add_code$2/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub AddLogging
{
  my $code = shift;

  my $add_code =<<EOF;
# The location of the News Clipper debug and error log files. Set to "STDOUT"
# or "STDERR" to send to standard output or standard error.
'debug_log_file' => "\$home/.NewsClipper/logs/debug.log",
'run_log_file' => "\$home/.NewsClipper/logs/run.log",

# These values allow you to configure the old logs that are saved. After the
# log file reaches the max_log_file_size (in bytes), it is renamed and a new
# one is started. If there the max_number_of_log_files has been reached, then
# the oldest one is deleted before the logs are rotated. On Unix systems the
# old log files are zipped.
'max_number_of_log_files' => 7,
'max_log_file_size' => 1000000,

EOF

  $code =~ s/(tag_text.*?\n)(\);)/$1$add_code$2/s;

  return $code;
}

# -----------------------------------------------------------------------------

sub UpdateOptionNames
{
  my $code = shift;

  $code =~ s/forNewsClipperVersion/for_news_clipper_version/g;
  $code =~ s/regKey/registration_key/g;
  $code =~ s/inputFiles/input_files/g;
  $code =~ s/outputFiles/output_files/g;
  $code =~ s/ftpFiles/ftp_files/g;
  $code =~ s/handlerlocations/handler_locations/g;
  $code =~ s/modulepath/module_path/g;
  $code =~ s/cachelocation/cache_location/g;
  $code =~ s/maxcachesize/max_cache_size/g;
  $code =~ s/scriptTimeout/script_timeout/g;
  $code =~ s/socketTries/socket_tries/g;
  $code =~ s/socketTimeout/socket_timeout/g;

  return $code;
}

# -----------------------------------------------------------------------------

sub ExtractImgCache()
{
  my $code = shift;

  my $cacheImg;

  $code =~ s/\n*((# [^\n]+\n)*'imgcachedir'[^\n]*\n)/$cacheImg .= $1;"\n"/se;
  $code =~ s/\n*((# [^\n]+\n)*'imgcacheurl'[^\n]*\n)/$cacheImg .= $1;"\n"/se;
  $code =~ s/\n*((# [^\n]+\n)*'maximgcacheage'[^\n]*\n)/$cacheImg .= $1;"\n"/se;

  return ($code,$cacheImg);
}

#-------------------------------------------------------------------------------
sub WriteConfig($$)
{
  my $configFile = shift;
  my $code = shift;

  my $backup;

  for (my $i = 1; 1; $i++)
  {
    $backup = $configFile;
    $backup =~ s/$/.bak/i;
    $backup .= $i unless $i == 1;
    last unless -e $backup;
  }

  rename $configFile,$backup or
    warn "Couldn't not rename $configFile\n  to $backup. Skipping...\n"
      and return;
  open NEW, ">$configFile" or die "Can't open $configFile for writing: $!\n";
  print NEW $code;
  close NEW;

  print<<"  EOF";
- Config file $configFile
has been converted and saved. Check it to make sure everything look reasonable.
(The old configuration was renamed to $backup.)
  EOF
}

