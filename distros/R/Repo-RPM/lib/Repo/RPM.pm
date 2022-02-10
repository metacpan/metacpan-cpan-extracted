package Repo::RPM;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

use FindBin;
use lib $FindBin::Bin;

use strict;
use warnings FATAL => 'all';

use POSIX;

use IO::Handle;
use File::Basename;
use File::Temp;

use DBI;

use Repo;

use RPM4;


sub html_template_location_path
{
  return Repo::library_location_path() . "/Repo/html";
}


sub get_pkg_name
{
  my $rpm = shift;

  my $shell_name = <<`SHELL`;
rpm --queryformat "%{NAME}" -qp $rpm 2>/dev/null
exit 0
SHELL

  return $shell_name;
}

sub get_pkg_version
{
  my $rpm = shift;

  my $shell_version = <<`SHELL`;
rpm --queryformat "%{VERSION}" -qp $rpm 2>/dev/null
exit 0
SHELL

  return $shell_version;
}

sub get_pkg_release
{
  my $rpm = shift;

  my $shell_release = <<`SHELL`;
rpm --queryformat "%{RELEASE}" -qp $rpm 2>/dev/null
exit 0
SHELL

  return $shell_release;
}

sub get_pkg_arch
{
  my $rpm = shift;

  my $shell_arch = <<`SHELL`;
rpm --queryformat "%{ARCH}" -qp $rpm 2>/dev/null
exit 0
SHELL

  return $shell_arch;
}

sub get_pkg_name_parts
{
  my $rpm = shift;
  my %parts;

  my $shell_parts = <<`SHELL`;
rpm --queryformat "%{NAME} %{VERSION} %{RELEASE} %{ARCH}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my @list = split( " ", $shell_parts );

  $parts{'name'}    = $list[0];
  $parts{'version'} = $list[1];
  $parts{'release'} = $list[2];
  $parts{'arch'}    = $list[3];

  return %parts;
}


# Table D-9 Special package requirement names and versions:
# --------------------------------+---------+-------------------------------------------------
#  Name                           | Version | Specifies
# --------------------------------+---------+-------------------------------------------------
#  Lsb                            | 1.3     | The package conforms to the Linux
#                                 |         | Standards Base RPM format.
# --------------------------------+---------+-------------------------------------------------
#  rpmlib(VersionedDependencies)  | 3.0.3-1 | The package holds dependencies or prerequisites
#                                 |         | that have versions associated with them.
# --------------------------------+---------+-------------------------------------------------
#  rpmlib(PayloadFilesHavePrefix) | 4.0-1   | File names in the archive have a “.” prepended
#                                 |         | on the names.
# --------------------------------+---------+-------------------------------------------------
#  rpmlib(CompressedFileNames)    | 3.0.4-1 | The package uses the RPMTAG_DIRINDEXES,
#                                 |         | RPMTAG_DIRNAME and RPMTAG_BASENAMES tags for
#                                 |         | specifying file names.
# --------------------------------+---------+-------------------------------------------------
#  /bin/sh                        | NA      | Indicates a requirement for the Bourne shell
#                                 |         | to run the installation scripts.
# --------------------------------+---------+-------------------------------------------------

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub skip_provides_requires_fields
{
  my $line = shift;
  my @list;

  # remove rest GLIBC_ versioning, architectures, version comparisons, and
  # some special requires because we are working with self-sufficient REPO:
  #
  @list = split( " ", $line );
  $line = $list[0];
  @list = split( "[(]", $line );
  $line = $list[0];

  if( $line =~ m/^Lsb/ )               { $line = ""; }
  if( $line =~ m/^config$/ )           { $line = ""; }
  if( $line =~ m/^group$/ )            { $line = ""; }
  if( $line =~ m/^user$/ )             { $line = ""; }
  if( $line =~ m/^rpmlib/ )            { $line = ""; }

  if( $line =~ m/^(.+):(.+)/ )         { $line = ""; }     # like 'rpm:/usr/bin/rpmbuild', 'apache:/usr/sbin/httpd', ...
  if( $line =~ m/^\/bin\// )           { $line = ""; }
  if( $line =~ m/^\/sbin\// )          { $line = ""; }
  if( $line =~ m/^\/usr\// )           { $line = ""; }

  if( $line =~ m/^ld64/ )              { $line = "glibc"; }
  if( $line =~ m/^libc/ )              { $line = "glibc"; }
  if( $line =~ m/^libdl/ )             { $line = "glibc"; }

  if( $line =~ m/\.so\./ )             { $line = ""; }
  if( $line =~ m/\.so$/ )              { $line = ""; }

  return $line;
}

sub get_pkg_requires
{
  my $rpm = shift;
  my @requires;

  my $shell_requires = <<`SHELL`;
rpm -qpR $rpm 2>/dev/null
exit 0
SHELL
  my @reqs = split( "\n", $shell_requires );
  foreach my $line ( @reqs )
  {
    $line =~ s/^\s+|\s+$//;

    $line = skip_provides_requires_fields( $line );
    next if( $line eq "" );

    push @requires, $line;
  }

  @requires = uniq( @requires );

  return @requires;
}

sub get_pkg_provides
{
  my $rpm = shift;
  my @provides;

  my $shell_provides = <<`SHELL`;
rpm --provides -qp $rpm 2>/dev/null
exit 0
SHELL
  my @provs = split( "\n", $shell_provides );
  foreach my $line ( @provs )
  {
    $line =~ s/^\s+|\s+$//;

    $line = skip_provides_requires_fields( $line );
    next if( $line eq "" );

    push @provides, $line;
  }

  @provides = uniq( @provides );

  return @provides;
}

sub get_pkg_files
{
  my $rpm = shift;
  my @files;

  my $shell_files = <<`SHELL`;
rpm -qpl $rpm 2>/dev/null
exit 0
SHELL
  my @list = split( "\n", $shell_files );
  foreach my $line ( @list )
  {
    $line =~ s/^\s+|\s+$//;
    push @files, $line;
  }

  return @files;
}

sub get_pkg_scripts
{
  my $rpm = shift;
  my @scripts;

  my $shell_scripts = <<`SHELL`;
rpm --scripts -qp $rpm 2>/dev/null
exit 0
SHELL
  my @lines = split( "\n", $shell_scripts );
  foreach my $line ( @lines )
  {
    $line =~ s/\s+$//;
    push @scripts, $line;
  }

  if( scalar @scripts ) { return join( "\n", @scripts ) . "\n"; }
  else                  { return ""; }
}

sub get_pkg_size
{
  my $rpm = shift;

  my $shell_size = <<`SHELL`;
rpm --queryformat "%{SIZE}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $size = $shell_size;
  $size =~ s/^\s+|\s+$//;

  return $size;
}

sub encode_spec_symbols
{
  my $desc = shift;

  $desc =~ s/\&/&#38;/g;
  $desc =~ s/\</&#60;/g;
  $desc =~ s/\>/&#62;/g;
  $desc =~ s/\*/&#42;/g;
  $desc =~ s/\(/&#40;/g;
  $desc =~ s/\)/&#41;/g;

  $desc =~ s/\"/&#34;/g;
  $desc =~ s/\'/&#39;/g;

  return $desc;
}

sub decode_spec_symbols
{
  my $desc = shift;

  $desc =~ s/&#39;/\'/g;
  $desc =~ s/&#34;/\"/g;

  $desc =~ s/&#41;/\)/g;
  $desc =~ s/&#40;/\(/g;
  $desc =~ s/&#42;/\*/g;
  $desc =~ s/&#62;/\>/g;
  $desc =~ s/&#60;/\</g;
  $desc =~ s/&#38;/\&/g;

  return $desc;
}


sub get_pkg_summary
{
  my $rpm = shift;

  my $shell_summary = <<`SHELL`;
rpm --queryformat "%{SUMMARY}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $summary = $shell_summary;
  $summary =~ s/^\s+|\s+$//;

  $summary = encode_spec_symbols( $summary );

  return $summary;
}


sub get_pkg_description
{
  my $rpm = shift;

  my $shell_description = <<`SHELL`;
rpm --queryformat "%{DESCRIPTION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $description = $shell_description;
  $description =~ s/^\s+|\s+$//;

  $description = encode_spec_symbols( $description );

  return $description;
}

sub get_pkg_distribution
{
  my $rpm = shift;

  my $shell_distribution = <<`SHELL`;
rpm --queryformat "%{DISTRIBUTION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $distribution = $shell_distribution;
  $distribution =~ s/^\s+|\s+$//;

  return $distribution;
}

sub get_pkg_group
{
  my $rpm = shift;

  my $shell_group = <<`SHELL`;
rpm --queryformat "%{GROUP}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $group = $shell_group;
  $group =~ s/^\s+|\s+$//;

  return $group;
}

sub get_pkg_license
{
  my $rpm = shift;

  my $shell_license = <<`SHELL`;
rpm --queryformat "%{LICENSE}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $license = $shell_license;
  $license =~ s/^\s+|\s+$//;

  return $license;
}

sub get_pkg_os
{
  my $rpm = shift;

  my $shell_os = <<`SHELL`;
rpm --queryformat "%{OS}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $os = $shell_os;
  $os =~ s/^\s+|\s+$//;

  return $os;
}

sub get_pkg_rpmversion
{
  my $rpm = shift;

  my $shell_rpmversion = <<`SHELL`;
rpm --queryformat "%{RPMVERSION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $rpmversion = $shell_rpmversion;
  $rpmversion =~ s/^\s+|\s+$//;

  return $rpmversion;
}

sub get_pkg_sourcerpm
{
  my $rpm = shift;

  my $shell_sourcerpm = <<`SHELL`;
rpm --queryformat "%{SOURCERPM}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $sourcerpm = $shell_sourcerpm;
  $sourcerpm =~ s/^\s+|\s+$//;

  return $sourcerpm;
}

sub get_pkg_sourceurl
{
  my $rpm = shift;

  my $shell_sourceurl = <<`SHELL`;
rpm --queryformat "%{URL}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $sourceurl = $shell_sourceurl;
  $sourceurl =~ s/^\s+|\s+$//;

  return $sourceurl;
}

################################################################
# Read DEVICES table from RPM:
#

#
# http://permissions-calculator.org
#
sub text2spec_mode
{
  my $tmode = shift;
  my $smode = '0';

  foreach my $ugo ( $tmode =~ /^.(.{3})(.{3})(.{3})/ )
  {
    $ugo =~ /[SsTt]/ && ($smode += 1);
  }
  return $smode;
}

sub text2oct_mode
{
  my $tmode = shift;
  my $omode = '0';

  if( $tmode =~ /^.(.{3})(.{3})(.{3})/ )
  {
    my ($u, $g, $o) = ($1, $2, $3);
    my ($sm, $um, $gm, $om) = (0, 0, 0, 0);

    $u =~ /r/ && ($um += 4);
    $u =~ /w/ && ($um += 2);
    $u =~ /x/ && ($um += 1);
    if( $u =~ /s/ ) { $um += 1; $sm += 4; }
    $u =~ /S/ && ($sm += 4);

    $g =~ /r/ && ($gm += 4);
    $g =~ /w/ && ($gm += 2);
    $g =~ /x/ && ($gm += 1);
    if( $g =~ /s/ ) { $gm += 1; $sm += 2; }
    $g =~ /S/ && ($sm += 2);

    $o =~ /r/ && ($om += 4);
    $o =~ /w/ && ($om += 2);
    $o =~ /x/ && ($om += 1);
    if( $o =~ /t/ ) { $om += 1; $sm += 1;}
    $o =~ /T/ && ($sm += 1);

    $omode = $sm . $um . $gm . $om;
  }
  return $omode;
}

sub get_pkg_devtable
{
  my $rpm = shift;
  my $args;
  my %devs;

  $args = "-vit --numeric-uid-gid";

  my $shell_output = <<`SHELL`;
rpm2cpio $rpm | cpio $args 2>/dev/null
exit 0
SHELL

  # remove space between MAJOR, MINOR :
  $shell_output =~ s/,[ ]+/,/g;

#                            | permissions               | no          | uid/gid                   | size          | date: Mmm DD YYYY                                | file
# ---------------------------+---------------------------+-------------+---------------------------+---------------+--------------------------------------------------+---------
  while( $shell_output =~ m!^([\-bcpdlrwxSsTt]{10})[ \t]+([0-9]+)[ \t]+([0-9]+)[ \t]+([0-9]+)[ \t]+([0-9,]+)[ \t]+([A-Za-z]{3})[ \t]+([0-9]{1,2})[ \t]+([0-9]{4})[ \t]+(.+)$!gm )
  {
    my $perm  = $1;
    my $uid   = $3;
    my $gid   = $4;
    my $size  = $5;
    my $dev   = $9;

    # remobe leading './' from file name
    $dev =~ s/^\.\///g;

    my ($name, $type, $smode, $mode, $owner, $major, $minor, $start, $inc, $count);

    $perm =~ s/^\s+|\s+$//g;
    $uid  =~ s/^\s+|\s+$//g;
    $gid  =~ s/^\s+|\s+$//g;
    $size =~ s/^\s+|\s+$//g;
    $dev  =~ s/^\s+|\s+$//g;

    $owner = $uid . ":" . $gid;

    $name = "/" . $dev;
    $type = substr($perm, 0, 1);
    $mode = text2oct_mode( $perm );

    $type =~ tr/-/f/;
    $smode = text2spec_mode( $perm );

    if( ($smode or 
         $type eq "b" or $type eq "c" or $type eq "s" or 
         $type eq "p" or $uid ne "0" or $gid ne "0"
        ) and $type ne "l"
      )
    {

      if( $type eq "b" or $type eq "c" )
      {
        ($major, $minor) = split( /,/, $size );
        $devs{$name} = $type . "\t" . $mode . "\t" . $uid . "\t" . $gid . "\t" . $major . "\t" . $minor;
      }
      else
      {
        $devs{$name} = $type . "\t" . $mode . "\t" . $uid . "\t" . $gid;
      }

    }
  }
  return %devs;
}

#
# End of Read DEVICES table from RPM.
#
################################################################


################################################################
# Read whole available information from RPM:
#
# PKG          (TEXT)  (NOT NULL) - basename of package tarball
#
# using --queryformat option:
# --------------------------
# NAME         (TEXT)  (NOT NULL)
# VERSION      (TEXT)  (NOT NULL)
# RELEASE      (TEXT)  (NOT NULL)
# ARCH         (TEXT)  (NOT NULL)
#
# SIZE         (INT)(INTEGER)(8-byte signed integer) размер в байтах
# SUMMARY      (TEXT)
# DESCRIPTION  (TEXT)
# DISTRIBUTION (TEXT)
#
# GROUP        (TEXT)
# LICENSE      (TEXT)
# OS           (TEXT) как правило 'linux'
# RPMVERSION   (TEXT)
# SOURCERPM    (TEXT)
# URL          (TEXT) это месторасположение оригинальных исходников
#
# using RPM requests -qpl, -qpR, --provides, --scripts:
# ----------------------------------------------------
# REQUIRES     (TEXT)
# PROVIDES     (TEXT)
# SCRIPTS      (TEXT)
# LIST         (TEXT)
#
# by list CPIO content:
# --------------------
# DEVTABLE     (TEXT)
#
sub read_package
{
  my $rpm = shift;
  my %package;

  $package{'pkg'}          = basename( $rpm );

  # NAME, VERSION, RELEASE, ARCH
  my $shell_output = <<`SHELL`;
rpm --queryformat "%{NAME} %{VERSION} %{RELEASE} %{ARCH}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my @list = split( " ", $shell_output );

  $package{'name'}         = $list[0];
  $package{'version'}      = $list[1];
  $package{'release'}      = $list[2];
  $package{'arch'}         = $list[3];

  # SIZE
  my $shell_size = <<`SHELL`;
rpm --queryformat "%{SIZE}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $size = $shell_size;
  $size =~ s/^\s+|\s+$//;

  $package{'size'}         = $size;

  # SUMMARY
  my $shell_summary = <<`SHELL`;
rpm --queryformat "%{SUMMARY}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $summary = $shell_summary;
  $summary =~ s/^\s+|\s+$//;

  $summary = encode_spec_symbols( $summary );

  $package{'summary'}      = $summary;

  # DESCRIPTION
  my $shell_description = <<`SHELL`;
rpm --queryformat "%{DESCRIPTION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $description = $shell_description;
  $description =~ s/^\s+|\s+$//;

  $description = encode_spec_symbols( $description );

  $package{'description'}  = $description;

  # DISTRIBUTION
  my $shell_distribution = <<`SHELL`;
rpm --queryformat "%{DISTRIBUTION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $distribution = $shell_distribution;
  $distribution =~ s/^\s+|\s+$//;

  $package{'distribution'} = $distribution;

  # GROUP
  my $shell_group = <<`SHELL`;
rpm --queryformat "%{GROUP}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $group = $shell_group;
  $group =~ s/^\s+|\s+$//;

  $package{'group'}        = $group;

  # LICENSE
  my $shell_license = <<`SHELL`;
rpm --queryformat "%{LICENSE}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $license = $shell_license;
  $license =~ s/^\s+|\s+$//;

  $package{'license'}      = $license;

  # OS
  my $shell_os = <<`SHELL`;
rpm --queryformat "%{OS}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $os = $shell_os;
  $os =~ s/^\s+|\s+$//;

  $package{'os'}           = $os;

  # RPM VERSION
  my $shell_rpmversion = <<`SHELL`;
rpm --queryformat "%{RPMVERSION}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $rpmversion = $shell_rpmversion;
  $rpmversion =~ s/^\s+|\s+$//;

  $package{'rpmversion'}   = $rpmversion;

  # SOURCE RPM (basename)
  my $shell_sourcerpm = <<`SHELL`;
rpm --queryformat "%{SOURCERPM}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $sourcerpm = $shell_sourcerpm;
  $sourcerpm =~ s/^\s+|\s+$//;

  $package{'sourcerpm'}    = $sourcerpm;

  # URL (original sources/project URL)
  my $shell_sourceurl = <<`SHELL`;
rpm --queryformat "%{URL}" -qp $rpm 2>/dev/null
exit 0
SHELL
  my $sourceurl = $shell_sourceurl;
  $sourceurl =~ s/^\s+|\s+$//;

  $package{'url'}          = $sourceurl;

  my $line;

  #
  # REQUIRES (as a text)
  #
  my $requires = "";
  my @reqs = get_pkg_requires( $rpm );
  foreach $line ( @reqs ) { $requires .= $line . "\n"; }

  $package{'requires'}     = $requires;

  #
  # PROVIDES (as a text)
  #
  my $provides = "";
  my @provs = get_pkg_provides( $rpm );
  foreach $line ( @provs ) { $provides .= $line . "\n"; }

  $package{'provides'}     = $provides;

  #
  # SCRIPTS (as a text)
  #
  my $scripts = get_pkg_scripts( $rpm );

  $package{'scripts'}     = $scripts;

  #
  # LIST (as a text)
  #
  my $list = "";
  my @files = get_pkg_files( $rpm );
  foreach $line ( @files ) { $list .= $line . "\n"; }

  $package{'list'}         = $list;

  #
  # DEVTABLE (as a text)
  #
  my $devtable = "";
  my %devices = get_pkg_devtable( $rpm );

#  $devtable .= "# device table\n\n";
#  $devtable .= "# <name>\t\t<type>\t<mode>\t<uid>\t<gid>\t<major>\t<minor>\t<start>\t<inc>\t<count>\n";

  foreach my $dev ( sort keys %devices )
  {
    $devtable .= $dev . "\t\t" .  $devices{$dev} . "\n";
  }

  $package{'devtable'}     = $devtable;

  return %package;
}


# сортировка по возрастанию ID представленного числом
sub ascending { $a <=> $b }
# сортировка по    убыванию ID представленного числом
sub descending { $b <=> $a }

sub write_database
{
  my $dbname = shift; # basename of SQLite DB file
  my $repo   = shift; # reference of %repo HASH

  my $path = $repo->{'path'};
  my %packages = %{ $repo->{'packages'} };
  my $common_devtable = "";

  if( $dbname eq "" ) { $dbname = ".repo.db"; }

  #
  # Remove old database:
  #
  # if( -e $path . "/" . $dbname ) { unlink( $path . "/" . $dbname ); }
  if( -e $path . "/" . $dbname ) { rename( $path . "/" . $dbname, $path . "/" . $dbname . ".back" ); }

  ##############################################################
  # Fill SQLite Database:
  #
  my $driver   = "SQLite"; 
  my $database = $path . "/" . $dbname;
  my $dsn      = "DBI:$driver:dbname=$database";
  my $userid   = "";
  my $passwd   = "";
  my $dbh      = DBI->connect( $dsn, $userid, $passwd, { RaiseError => 1, PrintError => 0 } );

  if( ! $dbh )
  {
    print STDERR "write_database: cannot open DB: " . $DBI::errstr . "\n";
    if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
    return 0;
  }

  $dbh->do( "PRAGMA synchronous = OFF" );
  $dbh->do( "PRAGMA cache_size = 512000" );

  my ( $stmt, $sth );

  $stmt = qq(CREATE TABLE REPO
             (ID INT PRIMARY KEY     NOT NULL,
              TYPE           TEXT    NOT NULL,
              URL            TEXT    NOT NULL,
              PATH           TEXT,
              DISTRIBUTION   TEXT,
              DEVTABLE       TEXT););
  $sth = $dbh->do( $stmt );
  if( $sth < 0 )
  {
    print STDERR "write_database: cannot create REPO table: " . $DBI::errstr . "\n";
    $dbh->disconnect();
    if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
    return 0;
  }

  $stmt = qq(INSERT INTO REPO (ID,TYPE,URL,PATH,DISTRIBUTION,DEVTABLE)
             VALUES (1, "$repo->{'type'}", "$repo->{'url'}", "$repo->{'path'}", "$repo->{'distribution'}", "" ));
  $sth = $dbh->do( $stmt );
  if( ! $sth )
  {
    print STDERR "write_database: cannot fill REPO table: " . $DBI::errstr . "\n";
    $dbh->disconnect();
    if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
    return 0;
  }

  $stmt = qq(CREATE TABLE PACKAGES
             (ID              INT  PRIMARY KEY  NOT NULL,
              PKG            TEXT               NOT NULL,
              NAME           TEXT               NOT NULL,
              VERSION        TEXT               NOT NULL,
              RELEASE        TEXT               NOT NULL,
              ARCH           TEXT               NOT NULL,
              SIZE            INT,
              SUMMARY        TEXT,
              DESCRIPTION    TEXT,
              DISTRIBUTION   TEXT,
              GRP            TEXT,
              LICENSE        TEXT,
              OS             TEXT,
              RPMVERSION     TEXT,
              SOURCERPM      TEXT,
              URL            TEXT,
              REQUIRES       TEXT,
              PROVIDES       TEXT,
              SCRIPTS        TEXT,
              LIST           TEXT,
              DEVTABLE       TEXT););
  $sth = $dbh->do( $stmt );
  if( $sth < 0 )
  {
    print STDERR "write_database: cannot create PACKAGES table: " . $DBI::errstr . "\n";
    $dbh->disconnect();
    if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
    return 0;
  }

  foreach my $id ( sort ascending keys %packages )
  {

    $stmt = qq(INSERT INTO PACKAGES (ID,PKG,NAME,VERSION,RELEASE,ARCH,SIZE,
                                     SUMMARY,DESCRIPTION,DISTRIBUTION,GRP,
                                     LICENSE,OS,RPMVERSION,SOURCERPM,URL,
                                     REQUIRES,PROVIDES,SCRIPTS,LIST,DEVTABLE)
               VALUES ($id, ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ));

    # to avoid truble with quotes we use $dbh->prepare(), $dbh->execute() instead of $dbh->do():
    $sth = $dbh->prepare( $stmt );
    if( ! $sth )
    {
      print STDERR "write_database: cannot fill PACKAGES table: " . $DBI::errstr . "\n";
      $dbh->disconnect();
      if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
      return 0;
    }
    $sth->execute( $packages{$id}{'pkg'},
                   $packages{$id}{'name'},
                   $packages{$id}{'version'},
                   $packages{$id}{'release'},
                   $packages{$id}{'arch'},
                   $packages{$id}{'size'},
                   $packages{$id}{'summary'},
                   $packages{$id}{'description'},
                   $packages{$id}{'distribution'},
                   $packages{$id}{'group'},
                   $packages{$id}{'license'},
                   $packages{$id}{'os'},
                   $packages{$id}{'rpmversion'},
                   $packages{$id}{'sourcerpm'},
                   $packages{$id}{'url'},
                   $packages{$id}{'requires'},
                   $packages{$id}{'provides'},
                   $packages{$id}{'scripts'},
                   $packages{$id}{'list'},
                   $packages{$id}{'devtable'} );

    #
    # Collect Device Tables
    #
    my $devtable = $packages{$id}{'devtable'};
    if( $devtable ne "" ) { $common_devtable .= $devtable }
  }

  if( $common_devtable ne "" )
  {
    my $devtable = "";

    $devtable .= "# device table\n\n";
    $devtable .= "# <name>\t\t<type>\t<mode>\t<uid>\t<gid>\t<major>\t<minor>\t<start>\t<inc>\t<count>\n";
    $devtable .= $common_devtable;

    $stmt = qq(UPDATE REPO set DEVTABLE = "$devtable" where ID=1;);
    $sth = $dbh->do( $stmt );
    if( ! $sth )
    {
      print STDERR "write_database: cannot set DEVTABLE in  REPO table: " . $DBI::errstr . "\n";
      $dbh->disconnect();
      if( -e $path . "/" . $dbname . ".back" ) { rename( $path . "/" . $dbname . ".back", $path . "/" . $dbname ); }
      return 0;
    }
  }

  $dbh->disconnect();

  return 1;
}

sub read_repository
{
  my $url    = shift; # URL of original repository
  my $path   = shift; # path to local mirror

  my (%repo, %packages, @pkglist);

  if( ! defined $url or $url eq "" )
  {
    print STDERR "read_repository: mising repository URL\n";
    return %repo;
  }
  if( ! -d $path )
  {
    print STDERR "read_repository: $path is not a directory\n";
    return %repo;
  }
  if( ! -f $path . "/.pkgs.list" )
  {
    print STDERR "read_repository: mising .pkgs.list file\n";
    return %repo;
  }

  $repo{'type'} = "RPM"; # RPM, DEB, PACMAN
  $repo{'url'}  = $url;
  $repo{'path'} = $path;

  #
  # read LIST from file:
  #
  open(my $fh, "<", $path . "/.pkgs.list")
    or die "Failed to open file: $!\n";
  while( <$fh> )
  {
    chomp; 
    push @pkglist, $_;
  }
  close $fh;

  #
  # fill packages HASH packages = { id => %package, ... }:
  #
  my $id = 1;
  foreach my $pkg ( @pkglist )
  {
    my %package = read_package( $path . "/" . $pkg );
    $packages{$id} = \%package;
    $id++;
# only for testing:
#    last if( $id > 10 ); # for testing first packages
  }

  $repo{'packages'} = \%packages;

  #
  # Set DISTRIBUTION using first package:
  # ------------------------------------
  # NOTE:
  #   Probably it will help to get DISTRONAME,
  #   and DISTROVERSION by reading DISTRIBUTION
  #   entry from REPO table.
  #
  $repo{'distribution'} = $packages{1}{'distribution'};

  return %repo;
}


sub read_database
{
  my $dbname = shift; # DB file name
  my $path   = shift; # path to local mirror

  if( $dbname eq "" ) { $dbname = ".repo.db"; }

  my (%repo, %packages);

  if( ! -e $path . "/" . $dbname )
  {
    print STDERR "read_database: mising DB file: " . $path . "/" . $dbname . "\n";
    return %repo;
  }

  ##############################################################
  # Read SQLite Database:
  #
  my $driver   = "SQLite"; 
  my $database = $path . "/" . $dbname;
  my $dsn      = "DBI:$driver:dbname=$database";
  my $userid   = "";
  my $passwd   = "";
  my $dbh      = DBI->connect( $dsn, $userid, $passwd, { RaiseError => 1, PrintError => 0 } );

  if( ! $dbh )
  {
    print STDERR "create_repo_database: cannot open DB: " . $DBI::errstr . "\n";
    return %repo;
  }

  $dbh->do( "PRAGMA synchronous = OFF" );
  $dbh->do( "PRAGMA cache_size = 512000" );

  my ( $stmt, $sth, $ret, @row );

  #
  # Read table REPO:
  #
  $stmt = qq( SELECT TYPE, URL, PATH, DISTRIBUTION, DEVTABLE from REPO where ID=1;);
  $sth  = $dbh->prepare( $stmt );
  $ret  = $sth->execute();
  if( $ret < 0 )
  {
    print STDERR "read_database: cannot read REPO table: " . $DBI::errstr . "\n";
    $sth->finish();
    $dbh->disconnect();
    return %repo;
  }

  if( @row = $sth->fetchrow_array() )
  {
    $repo{'type'}         = $row[0]; # RPM, DEB, PACMAN
    $repo{'url'}          = $row[1];
    $repo{'path'}         = $row[2];
    $repo{'distribution'} = $row[3];
    $repo{'devtable'}     = $row[4];

    $sth->finish();
  }
  else
  {
    print STDERR "read_database: cannot read row from REPO table: " . $DBI::errstr . "\n";
    $sth->finish();
    $dbh->disconnect();
    return %repo;
  }

  #
  # Read table PACKAGES:
  #
  $stmt = qq( SELECT ID,PKG,NAME,VERSION,RELEASE,ARCH,SIZE,SUMMARY,DESCRIPTION,
                     DISTRIBUTION,GRP,LICENSE,OS,RPMVERSION,SOURCERPM,URL,REQUIRES,
                     PROVIDES,SCRIPTS,LIST,DEVTABLE from PACKAGES;);
  $sth  = $dbh->prepare( $stmt );
  $ret  = $sth->execute();
  if( $ret < 0 )
  {
    print STDERR "read_database: cannot read PACKAGES table: " . $DBI::errstr . "\n";
    $sth->finish();
    $dbh->disconnect();
    return %repo;
  }

  while( @row = $sth->fetchrow_array() )
  {
    my $id                         = $row[ 0];

    $packages{$id}{'pkg'}          = $row[ 1];
    $packages{$id}{'name'}         = $row[ 2];
    $packages{$id}{'version'}      = $row[ 3];
    $packages{$id}{'release'}      = $row[ 4];
    $packages{$id}{'arch'}         = $row[ 5];
    $packages{$id}{'size'}         = $row[ 6];
    $packages{$id}{'summary'}      = $row[ 7];
    $packages{$id}{'description'}  = $row[ 8];
    $packages{$id}{'distribution'} = $row[ 9];
    $packages{$id}{'group'}        = $row[10];
    $packages{$id}{'license'}      = $row[11];
    $packages{$id}{'os'}           = $row[12];
    $packages{$id}{'rpmversion'}   = $row[13];
    $packages{$id}{'sourcerpm'}    = $row[14];
    $packages{$id}{'url'}          = $row[15];
    $packages{$id}{'requires'}     = $row[16];
    $packages{$id}{'provides'}     = $row[17];
    $packages{$id}{'scripts'}      = $row[18];
    $packages{$id}{'list'}         = $row[19];
    $packages{$id}{'devtable'}     = $row[20];
  }
  $sth->finish();

  $dbh->disconnect();
  #
  # End of Reading SQLite Database.
  ##############################################################

  $repo{'packages'} = \%packages;

  return %repo;
}


################################################################
# Working with REPO HASH:
#

#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
# Returns package with first found ID .
#
sub find_first_package
{
  my $repo    = shift;
  my $pkgname = shift;

  my %package;

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {
      return %{ $packages{$id} };
    }
  }

  return %package;
}

#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
# Returns package with last found ID .
#
sub find_last_package
{
  my $repo    = shift;
  my $pkgname = shift;

  my %package;

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort descending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {
      return %{ $packages{$id} };
    }
  }

  return %package;
}

#
# Arguments:
#   \%repo     - REPO HASH ;
#   $pkgname   - the name of package to find .
#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
# Returns package with MAX version.
#
sub find_package
{
  my $repo    = shift;
  my $pkgname = shift;

  my %package;
  my $id;

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };

  foreach $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {
      my %pkg = %{ $packages{$id} };

      if( %pkg )
      {
        if( ! %package )
        {
          %package = %pkg;
        }
        else
        {
          my $version1 = $package{'version'} . "-" . $package{'release'};
          my $version2 = $pkg{'version'}     . "-" . $pkg{'release'};
          if( rpmvercmp( $version1, $version2 ) < 0 )
          {
            %package = %pkg;
          }
        }
      }
    }
  }

  return %package;
}

#
# Arguments:
#   \%repo     - REPO HASH ;
#   $pkgname   - the name of package to find ;
#   $version   - the package version ;
#   $release   - the package release (optional) .
#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
# If RELEASE is not defined then returns package with MAX RELEASE number.
#
sub find_package_version
{
  my $repo    = shift;
  my $pkgname = shift;
  my $version = shift;
  my $release = shift;

  my %package;
  my $id;

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %package;
  }

  if( ! defined $version or $version eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };

  foreach $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {
      my %pkg = %{ $packages{$id} };

      if( %pkg )
      {
        if( ! defined $release or $release eq "" )
        {
          #
          # find latest release:
          #
          my $version1 = $pkg{'version'};
          if( rpmvercmp( $version1, $version ) == 0 )
          {
            if( ! %package )
            {
              %package = %pkg;
            }
            else
            {
              my $release1 = $package{'release'};
              my $release2 = $pkg{'release'};

              if( rpmvercmp( $release1, $release2 ) < 0 )
              {
                %package = %pkg;
              }

            }
          }
        }
        else
        {
          #
          # find exact version with release:
          #
          my $version1 = $pkg{'version'} . "-" . $pkg{'release'};
          my $version2 = $version . "-" . $release;
          if( rpmvercmp( $version1, $version2 ) == 0 )
          {
            %package = %pkg;
          }
        }
      }
    }
  }

  return %package;
}

#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
sub find_package_by_tarball
{
  my $repo    = shift;
  my $tarball = shift;

  my %package;

  if( ref( $repo ) ne "HASH" or $tarball eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'pkg'} eq $tarball )
    {
      return %{ $packages{$id} };
    }
  }

  return %package;
}

#
# Returns PACKAGE HASH { pkg => "tarball", name => "pkgname", ... }
#
sub find_package_by_provides
{
  my $repo    = shift;
  my $pattern = shift;

  my %package;

  $pattern =~ s,/,\/,g;

  if( ref( $repo ) ne "HASH" or $pattern eq "" )
  {
    return %package;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    my @provides = split( "\n", $packages{$id}{'provides'} );
    if( grep { /^$pattern$/ } @provides )
    {
      return %{ $packages{$id} };
    }
  }

  return %package;
}


#
# Returns HASH { $pkg{'name'} => STRING"$pkg{'name'} $pkg{'name'} ... " }
#
sub package_requires
{
  my $repo    = shift;
  my $pkgname = shift;

  my ( %requires, @packages );

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %requires;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {

      my %package = %{ $packages{$id} };
      my @reqs    = split( "\n", $package{'requires'} );

      $requires{$package{'name'}} = "";

      foreach my $req ( @reqs )
      {
        my %pkg;

        if( %pkg = find_package( $repo, $req ) )
        {
          #
          # if REQ is a PACKAGE NAME:
          #
          if( $pkg{'name'} ne $package{'name'} )
          {
            $requires{$package{'name'}} = $requires{$package{'name'}} . " " .  $pkg{'name'};
          }
        }
        else
        {
          if( %pkg = find_package_by_provides( $repo, $req ) )
          {
            #
            # if REQ is a PACKAGE REQUIRE (such as libc.so.6):
            #
            if( $pkg{'name'} ne $package{'name'} )
            {
              $requires{$package{'name'}} = $requires{$package{'name'}} . " " .  $pkg{'name'};
            }
          }
        }
      }
      #
      # remove duplicates:
      #
      @packages = uniq( split( " ", $requires{$package{'name'}} ) );
      $requires{$package{'name'}} = join( " ", @packages );
    }
  }

  return %requires;
}


#sub delete_element_by_name
#{
#  my @dlist = @{ shift @_ };
#  my $name  =    shift;
#
#  if( defined $name )
#  {
#    my @deletion = ();
#    while( my ($index, $dname) = each( @dlist ) )
#    {
#      if( $dname eq $name )
#      {
#        splice @dlist, $index, 1;
#        last;
#      }
#    }
#  }
#  return @dlist;
#}
#
# This (void) function() changes array taken by reference.
#
sub delete_element_by_name
{
  my $dlist = shift;
  my $name  = shift;

  if( defined $name )
  {
    my @deletion = ();
    while( my ($index, $dname) = each( @{ $dlist } ) )
    {
      if( $dname eq $name )
      {
        splice @{ $dlist }, $index, 1;
        last;
      }
    }
  }
}


sub remove_cyclic_requires
{
  my $name     = shift;
  my $pname    = shift;
  my $requires = shift;

  if( ref( $requires ) ne "HASH" )
  {
    return;
  }

  #
  # packages with already resolved requires
  #
  my @packages = sort( keys %{ $requires } );

  if( grep { /^$pname$/ } @packages )
  {
    my @rlist = split( " ", $requires->{$pname} );
    foreach my $rname ( @rlist )
    {
      if( grep { /^$rname$/ } @packages )
      {
        if( grep { /^$name$/ } @rlist )
        {
          delete_element_by_name( \@rlist, $name );
          $requires->{$pname} = join( " ", @rlist );
        }
        else
        {
          remove_cyclic_requires( $name, $rname, $requires, \@packages );
        }
      }
    }
  }
}



#
# Arguments:
#   \%repo     - REPO HASH ;
#   \%requires - the requires HASH (is empty on first call) ;
#   $root      - the package name (is empty "" or special name 'all' on first call) ;
#   \@list     - the list of package names .
#
# Returns:
#   HASH { $pkg{'name'} => STRING"$pkg{'name'} $pkg{'name'} ... " }
#
sub build_requires
{
  my $repo     = shift;
  my $requires = shift;
  my $root     = shift;
  my @list     = @{ shift @_ };

  ##############################################################
  # remove non-existent names:
  #
  my @deletion = ();
  foreach my $pname ( @list )
  {
    my %pkg = find_package( $repo, $pname );
    if( ! %pkg )
    {
      push ( @deletion, $pname );
    }
  }
  foreach my $n ( @deletion )
  {
    delete_element_by_name( \@list, $n );
  }
  #
  # End of deletion non-existent names.
  ##############################################################


  if( ref( $repo ) ne "HASH" or scalar(@list) == 0 )
  {
    return %{ $requires };
  }

  if( $root eq "" ) { $root = "all"; }

  $requires->{$root} = join( " ", @list );

  foreach my $name ( @list )
  {
    my @packages = sort( keys %{ $requires } );

    #
    # Skip packages with already built requires:
    #
    if( ! grep { /^$name$/ } @packages )
    {
      my %reqs;
      my $req = "";

      if( %reqs = package_requires( $repo, $name ) )
      {
        $req =  $reqs{$name};
        $req =~ s/^\s+|\s+$//;

        ##############################################################
        # remove non-existent names:
        #
        @deletion = ();
        my @dlist = split( " ", $req );
        foreach my $pname ( @dlist )
        {
          my %pkg = find_package( $repo, $pname );
          if( ! %pkg )
          {
            push ( @deletion, $pname );
          }
        }
        foreach my $n ( @deletion )
        {
          delete_element_by_name( \@dlist, $n );
        }
        $req = join( " ", @dlist );
        #
        # End of deletion non-existent names.
        ##############################################################


        ######################################################
        #
        #  Remove cyclic requres:
        #  =====================
        #
        #  Если какой-либо пакет из списка зависимостей пакета
        #  с именем '$name' уже находится среди обработанных
        #  пакетов (т.е. находится в списке @packages) и в его
        #  зависимостях присутствует пакет с тем же именем
        #  '$name', то данный пакет надо удалить из списка
        #  зависимостей пакета.
        #
        #  Далее осуществляется поиск многоступенчатых циклов.
        #
        my @rlist = split( " ", $req );
        foreach my $rpkg ( @rlist )
        {
          if( grep { /^$rpkg$/ } @packages )
          {
            my @rlist2 = split( " ", $requires->{$rpkg} );
            if( grep { /^$name$/ } @rlist2 )
            {
              delete_element_by_name( \@rlist, $rpkg );
              $requires->{$rpkg} = join( " ", @rlist );
            }
            else
            {
              remove_cyclic_requires( $name, $rpkg, \%{ $requires } );
            }
          }
        }
        #
        ######################################################

        $requires->{$name} = $req;

        if( $req ne "" )
        {
          my @rlist = split( " ", $req );
          build_requires( $repo, $requires, $name, \@rlist );
        }
      }
    }
  }

  return %{ $requires };
}

sub sort_by_name
{
  if( $a eq "all" )    { return -1; }
  elsif( $b eq "all" ) { return  1; }
  else                 { return $a cmp $b; }
}

#
# Arguments:
#   \%requires - the requires HASH
#
# Returns:
#   VOID
#
sub print_requires
{
  my $requires = shift;
  my $file     = shift;

  my %requires = %{ $requires };

  my $fh;
  open( $fh, "> $file" );
  if( ! $fh )
  {
    print STDERR "print_requires: cannot open file: " . $file . "\n";
    return;
  }

  foreach my $key (sort sort_by_name keys %requires )
  {
    print $fh "\n" . $key . ": " . $requires{$key} . "\n";
  }

  close $fh;
}


#
# Fill package CARD with short package description:
# ------------------------------------------------
#
# Returns PACKAGE CARD HASH { pkg => "tarball", name => "pkgname", ... }
#
sub package_card
{
  my $repo    = shift;
  my $pkgname = shift;

  my (%card, %package);

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return %card;
  }

  if( %package = find_package( $repo, $pkgname ) )
  {
    $card{'name'}        = $package{'name'};
    $card{'version'}     = $package{'version'};
    $card{'release'}     = $package{'release'};
    $card{'description'} = $package{'summary'};
    $card{'arch'}        = $package{'arch'};
    $card{'size'}        = $package{'size'};
    $card{'license'}     = $package{'license'};
    $card{'tarball'}     = $package{'pkg'};
  }
  else
  {
    $card{'name'} = $pkgname;
  }

  return %card;
}


#
# Arguments:
#   \%requires - the requires HASH
#
# Returns:
#   HASH { $pkg{'name'} => sequence index }
#
sub build_install_sequence
{
  my $requires = shift;

  my %sequence;
  my $order = 0;

  #
  # Copy REQUIRES into new DEPS hash:
  #
  my %deps; @deps{ keys %{ $requires }} = values %{ $requires };

  my $count = scalar( keys %deps );

  #
  # independed packages:
  #
  foreach my $pname ( keys %deps )
  {
    if( $deps{$pname} eq "" )
    {
      $sequence{$pname} = ++$order;
      delete $deps{$pname};
    }
  }

  #
  # packages with dependencies:
  #
  for( my $i = 0; $i < $count; ++$i )
  {
    my @installed = keys %sequence;

    foreach my $key ( sort keys %deps )
    {
      my $ok = 1;
      my @pnames = split( " ", $deps{$key} );

      if( $key ne "all" )
      {
        foreach my $pname ( @pnames )
        {
          if( ! grep { $_ eq $pname } @installed )
          {
            $ok = 0;
          }
        }

        if( $ok == 1 )
        {
          $sequence{$key} = ++$order;

          delete $deps{$key};
        }
      }
    }
  }

  return %sequence;
}


#
# Arguments:
#   \%sequence - the requires HASH
#
# Returns:
#   VOID
#
sub print_install_sequence
{
  my $sequence = shift;
  my $file     = shift;

  my %sequence = %{ $sequence };

  my $fh;
  open( $fh, "> $file" );
  if( ! $fh )
  {
    print STDERR "print_install_sequence: cannot open file: " . $file . "\n";
    return;
  }

  foreach my $pkg (sort { $sequence{$a} <=> $sequence{$b} } keys %sequence )
  {
    print $fh sprintf( "%5d", $sequence{$pkg} ) . ": " . $pkg . "\n";
  }

  close $fh;
}

#
# Arguments:
#   \%repo     - REPO HASH ;
#   \%sequence - the sequence HASH .
#
# Returns:
#   VOID
#
sub print_used_rpms
{
  my $repo     = shift;
  my $sequence = shift;
  my $file     = shift;

  my %sequence = %{ $sequence };

  my $fh;
  open( $fh, "> $file" );
  if( ! $fh )
  {
    print STDERR "print_install_sequence: cannot open file: " . $file . "\n";
    return;
  }

  foreach my $pname (sort { $sequence{$a} <=> $sequence{$b} } keys %sequence )
  {
    my %pkg;

    if( %pkg = find_package( $repo, $pname ) )
    {
      print $fh sprintf( "%5d", $sequence{$pname} ) . ": " . $pkg{'pkg'} . "\n";
    }
  }

  close $fh;
}


#
# Arguments:
#   \%repo     - REPO HASH ;
#   \%requires - the requires HASH .
#
# Returns:
#   HASH { $pkg{'name'} => "name", $pkg{'children'} = %pkg, ... }
#
sub build_requires_tree
{
  my $repo     = shift;
  my $requires = shift;

  my (%tree, %subtrees, $root);

  if( ref( $repo ) ne "HASH" or ref( $requires ) ne "HASH" )
  {
    return %tree;
  }

  #
  # Copy REQUIRES into new DEPS hash:
  #
  my %deps; @deps{ keys %{ $requires }} = values %{ $requires };

  #####################
  #
  # NOTE: if single package has not requires then tree will bw empty.
  #
  #####################

  #
  # Skip node 'all' if this is requires of one package only:
  #
  my @list = split( " ", $deps{'all'} );
  if( scalar( @list ) == 1 )
  {
    $root = $list[0];
    %tree = package_card( $repo, $root );
    delete $deps{'all'};
  }
  else
  {
    $root = "all";
    %tree = package_card( $repo, $root );
  }

  my $count = scalar( keys %deps );

  my %sequence;
  my $order = 0;


  #
  # independed packages:
  #
  foreach my $pname ( keys %deps )
  {
    if( $deps{$pname} eq "" )
    {
      $sequence{$pname} = ++$order;

      my %pkg = package_card( $repo, $pname );
      $subtrees{$pname} = \%pkg;

      delete $deps{$pname};
    }
  }

  #
  # packages with dependencies:
  #
  for( my $i = 0; $i < $count; ++$i )
  {
    my @installed = keys %sequence;

    foreach my $key ( sort keys %deps )
    {
      my $ok = 1;
      my @pnames = split( " ", $deps{$key} );

      if( $key ne $root )
      {
        foreach my $pname ( @pnames )
        {
          if( ! grep { $_ eq $pname } @installed )
          {
            $ok = 0;
          }
        }

        if( $ok == 1 )
        {
          $sequence{$key} = ++$order;

          my %pkg = package_card( $repo, $key );
          foreach my $pname ( @pnames )
          {
            my $child = $subtrees{$pname};
            push( @{ $pkg{'children'}}, $child );
          }
          $subtrees{$key} = \%pkg;

          delete $deps{$key};
        }
      }
    }
  }

  if( ! defined $deps{$root} or $deps{$root} eq "" )
  {
    return %tree;
  }

  my @pnames = split( " ", $deps{$root} );
  foreach my $pname ( @pnames )
  {
    my $child = $subtrees{$pname};
    push( @{ $tree{'children'}}, $child );
  }

  return %tree;
}


################################################################
#
# print JSON tree into file:
#

my $tree_depth  = 2;
my $tree_height = 0;
my $root_node   = 1;

my $distro_name    = "SUSE";
my $distro_version = "1.0";
my $url            = "http://suse.com";

sub print_package_head
{
  my ( $fh, $level, $pkg )  = @_;
  my $indent = "";

  $level *= 2;
  while( $level )
  {
    $indent .= " ";
    $level--;
  }
  print $fh $indent . "{\n";

  if( defined $pkg->{'name'} and $pkg->{'name'} eq "all" )
  {
    if( $root_node == 1 )
    {
      print $fh $indent . " \"distro\": [\n";
      print $fh $indent . "  \"" . $distro_name . "\",\n";
      print $fh $indent . "  \"" . $distro_version . "\",\n";
      print $fh $indent . "  \"" . $url . "\"\n";
      print $fh $indent . " ],\n";
    }
    print $fh $indent . " \"name\":     \"" . $pkg->{'name'} . "\"";
  }
  else
  {
    if( $root_node == 1 )
    {
      print $fh $indent . " \"distro\": [\n";
      print $fh $indent . "  \"" . $distro_name . "\",\n";
      print $fh $indent . "  \"" . $distro_version . "\",\n";
      print $fh $indent . "  \"" . $url . "\"\n";
      print $fh $indent . " ],\n";
    }
    print $fh $indent . " \"name\":              \"" . $pkg->{'name'}              . "\",\n";
    print $fh $indent . " \"version\":           \"" . $pkg->{'version'}           . "\",\n";
    print $fh $indent . " \"release\":           \"" . $pkg->{'release'}           . "\",\n";
    print $fh $indent . " \"description\":       \"" . $pkg->{'description'}       . "\",\n";
    print $fh $indent . " \"arch\":              \"" . $pkg->{'arch'}              . "\",\n";
    print $fh $indent . " \"size\":              \"" . $pkg->{'size'}              . "\",\n";
    print $fh $indent . " \"license\":           \"" . $pkg->{'license'}           . "\",\n";
    print $fh $indent . " \"tarball\":           \"" . $pkg->{'tarball'}           . "\"";
  }
}

sub print_package_start_children
{
  my $fh     = shift;
  my $level  = shift;
  my $indent = "";

  $level *= 2;
  while( $level )
  {
    $indent .= " ";
    $level--;
  }
  print $fh $indent . " \"children\": [\n";
}

sub print_package_finish_children
{
  my $fh     = shift;
  my $level  = shift;
  my $indent = "";

  $level *= 2;
  while( $level ) { $indent .= " "; $level--; }
  print $fh $indent . " ]\n";
}

sub print_package_tail
{
  my $fh     = shift;
  my $level  = shift;
  my $indent = "";

  $level *= 2;
  while( $level ) { $indent .= " "; $level--; }
  print $fh $indent . "}";
}

sub print_comma
{
  my $fh    = shift;
  my $comma = shift;

  if( $comma > 0 ) { print $fh ",\n"; }
  else             { print $fh  "\n"; }
}

sub print_tree
{
  my ($fh, $level, $last, $pkg) = @_;

  if( $tree_depth < $level ) { $tree_depth = $level; }

  print_package_head( $fh, $level, \%{$pkg} );
  $root_node = 0;

  if( $pkg->{'children'} )
  {
    print_comma( $fh, 1 );
    print_package_start_children( $fh, $level );

    my @a = @{$pkg->{'children'}};
    my $n = $#a;

    $tree_height += $n;

    foreach my $p ( @{$pkg->{'children'}} )
    {
      print_tree( $fh, $level + 1, $n--, \%{$p} );
    }

    print_package_finish_children( $fh, $level );
  }
  else
  {
    print_comma( $fh, 0 );
  }
  print_package_tail( $fh, $level );
  print_comma( $fh, $last );
}


sub distro_name
{
  my $repo = shift;
  my $name = "SUSE";

  if( ref( $repo ) ne "HASH" )
  {
    return "SUSE";
  }

  my $distribution = $repo->{'distribution'};
#  if( $distribution  =~ m!^([^:]+)[:]([^:]+)[:]([^:]+)[:]([^ ]+).*$!gm )
#  {
#    $name = $1 . " " . $2;
#  }
  if( $distribution  =~ m!^([\-a-zA-Z\ ]+)[ \t]+([0-9\.]+)$!gm )
  {
    $name = $1;
  }

  return $name;
}

sub distro_version
{
  my $repo = shift;
  my $vers = "1.0";

  if( ref( $repo ) ne "HASH" )
  {
    return $vers;
  }

  my $distribution = $repo->{'distribution'};
#  if( $distribution  =~ m!^([^:]+)[:]([^:]+)[:]([^:]+)[:]([^ ]+).*$!gm )
#  {
#    $vers = $3;
#  }
  if( $distribution  =~ m!^([\-a-zA-Z\ ]+)[ \t]+([0-9\.]+)$!gm )
  {
    $vers = $2;
  }

  return $vers;
}

sub distro_arch
{
  my $repo = shift;
  my $arch = "unknown";

  if( ref( $repo ) ne "HASH" )
  {
    return $arch;
  }

  my $distribution = $repo->{'distribution'};
  if( $distribution  =~ m!^([^:]+)[:]([^:]+)[:]([^:]+)[:]([^ ]+).*$!gm )
  {
    $arch = $4;
  }

  return $arch;
}

sub distro_url
{
  my $repo = shift;
  my $url  = "http://";

  if( ref( $repo ) ne "HASH" )
  {
    return $url;
  }

  my $distro_url = $repo->{'url'};
  if( defined $distro_url and $distro_url ne "" )
  {
    $url = $distro_url;
  }

  return $url;
}


#
# Arguments:
#   \%repo  - REPO HASH ;
#   \%tree  - the requires tree HASH ;
#   $file   - output file name .
#
# Returns:
#   $width, $height of requires tree .
#
sub print_json_tree
{
  my $repo = shift;
  my $tree = shift;
  my $file = shift;

  my $fhandle;

  if( ref( $repo ) ne "HASH" or ref( $tree ) ne "HASH" or ! defined $file or $file eq "" )
  {
    return 0, 0;
  }

  open( $fhandle, "> $file" );
  if( ! $fhandle )
  {
    print STDERR "print_json_tree: cannot open file: " . $file . "\n";
    return 0, 0;
  }

  $tree_depth  = 2;
  $tree_height = 0;
  $root_node   = 1;

  $distro_name    = distro_name( $repo );
  $distro_version = distro_version( $repo );
  $url            = distro_url( $repo );

  print_tree( $fhandle, 0, 0, $tree );

  close $fhandle;

  return $tree_depth, $tree_height;
}


#
# Arguments:
#   \%repo   - REPO HASH ;
#   \%tree   - the requires tree HASH ;
#   $width   - number of intervals between nodes ;
#   $height  - number of intervals between nodes ;
#   $root    - name of requires tree ;
#   $bug_url - name of json tree data file;
#   $json    - name of json tree data file;
#   $file    - output file name .
#
# Returns:
#   TRUE if success .
#
sub print_html_tree
{
  my $repo    = shift;
  my $tree    = shift;
  my $width   = shift;
  my $height  = shift;
  my $root    = shift;
  my $bug_url = shift;
  my $json    = shift;
  my $file    = shift;

  my ($fhandle, $thandle);

  if( ref( $repo ) ne "HASH" or
      ref( $tree ) ne "HASH" or
      ! defined $file or $file eq "" or
      ! defined $json or $json eq ""    )
  {
    return 0;
  }

  $distro_name  = distro_name( $repo );
  if( $root eq "" )
  {
    $root = $tree->{'name'};
  }
  $width  = ($width + 4) * 160;
#  $height = ($height + 4) * 24;
  $height = ($height + 4) * 4;
  if( $height < 240 )
  {
    $height = 240;
  }

  my $template = html_template_location_path() . "/" . "requires_tree_html.template";


  open( $thandle, "<", $template );
  if( ! $thandle )
  {
    print STDERR "print_html_tree: cannot open template file: " . $template . "\n";
    return 0;
  }

  open( $fhandle, ">", $file );
  if( ! $fhandle )
  {
    print STDERR "print_html_tree: cannot open file: " . $file . "\n";
    return 0;
  }


  #
  # TEMPLATE: requires_tree_html.template
  #
  # replacements:
  #
  #   DISTRIBUTION
  #   BUG_URL
  #   ROOT
  #   SVG_WIDTH
  #   SVG_HEIGHT
  #   JSON_DATA_FILE

  while ( my $line = <$thandle> )
  {
    chomp $line;

    $line =~ s/\@DISTRIBUTION\@/$distro_name/g;
    $line =~ s/\@ROOT\@/$root/g;
    $line =~ s/\@SVG_WIDTH\@/$width/g;
    $line =~ s/\@SVG_HEIGHT\@/$height/g;
    $line =~ s/\@JSON_DATA_FILE\@/$json/g;
    $line =~ s/\@BUG_URL\@/$bug_url/g;

    print $fhandle $line . "\n";
  }

  close $fhandle;
  close $thandle;

  return 1;
}


################################################################
# short variants:
#

#
# Returns $pkg{'name'}
#
sub find_pkg_by_name
{
  my $repo    = shift;
  my $pkgname = shift;

  if( ref( $repo ) ne "HASH" or $pkgname eq "" )
  {
    return "";
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {
      return $packages{$id}{'name'};
    }
  }

  return "";
}

#
# Returns $pkg{'name'}
#
sub find_pkg_by_tarball
{
  my $repo    = shift;
  my $tarball = shift;

  if( ref( $repo ) ne "HASH" or $tarball eq "" )
  {
    return "";
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'pkg'} eq $tarball )
    {
      return $packages{$id}{'name'};
    }
  }

  return "";
}

#
# Returns $pkg{'name'}
#
sub find_pkg_by_provides
{
  my $repo    = shift;
  my $pattern = shift;

  $pattern =~ s,/,\/,g;

  if( ref( $repo ) ne "HASH" or $pattern eq "" )
  {
    return "";
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    my @provides = split( "\n", $packages{$id}{'provides'} );
    if( grep { /^$pattern$/ } @provides )
    {
      return $packages{$id}{'name'};
    }
  }

  return "";
}


#
# Returns HASH { $pkg{'name'} => STRING"$pkg{'name'} $pkg{'name'} ... " }
#
sub pkg_requires
{
  my $repo    = shift;
  my $pkgname = shift;

  my ( %requires, @packages );

  if( ref( $repo ) ne "HASH" )
  {
    return %requires;
  }

  my %packages = %{ $repo->{'packages'} };
  foreach my $id ( sort ascending keys %packages )
  {
    if( $packages{$id}{'name'} eq $pkgname )
    {

      my $package = $packages{$id}{'name'};
      my @reqs    = split( "\n", $packages{$id}{'requires'} );

      $requires{$package} = "";

      foreach my $req ( @reqs )
      {
        my $pkg = find_pkg_by_name( $repo, $req );
        if( $pkg ne "" ) { if( $pkg ne $package ) { $requires{$package} = $requires{$package} . " " .  $pkg; } }
        else
        {
          $pkg = find_pkg_by_provides( $repo, $req );
          if( $pkg ne "" ) { if( $pkg ne $package ) { $requires{$package} = $requires{$package} . " " .  $pkg; } }
        }
      }
      #
      # remove duplicates:
      #
      @packages = uniq( split( " ", $requires{$package} ) );
      $requires{$package} = join( " ", @packages );
    }
  }

  return %requires;
}


#
# End of Repo::RPM module.
#

1;
# The preceding line will help the module return a true value

__END__

=head1 NAME

Repo::RPM - perl module to create RPMs requires tree

=head1 DESCRIPTION

This module allow to create sqlite3 database from bunch of RPMs or SRPMs and build requires tree,
the list of RPMs names in installation order, and RPMs requires in the GNU Make format.

=head1 FUNCTIONS

=head2 read_repository( $url, $mirror )

Read RPMs are placed in $mirror local directory. The $url is a reference link to URL of RPMs downloaded
into $mirror directory, for example, "https://download.opensuse.org/source/distribution/leap/15.2/repo/oss/src/".

Example:

  use Repo;
  use Repo::RPM;

  my $version = "15.2";
  my $mirror = /home/user . "/" . "openSUSE-Leap-" . $version ."-src";

  my %repo = Repo::RPM::read_repository( $url, $mirror );

=head2 write_database( ".repo.db", \%repo );

Create and fill Sqlite3 database named $mirror . ".repo.db".

Example:

  my $ret = Repo::RPM::write_database( ".repo.db", \%repo );
  if( ! $ret )
  {
    print "write DB error\n";
  }

=head2 build_requires( \%repo, \%requires, "", \@list );

Create RPMs requires in the GNU Make format using RPMs names list.

Example:

  my $srpms_list = /home/user . "/input-srpm-names.list";

  my (%requires, %reqs);

  %requires = ();

  #
  # Get requires of packages from $srpms_list (where we have package names only):
  #
  my @list = ();
  my @rqlist = ();

  my (%pkg, $pkgname);

  #
  # read LIST from file:
  #
  open( my $fh, "<", $srpms_list )
    or die "Failed to open file: $!\n";
  while( <$fh> )
  {
    chomp; 
    push @rqlist, $_;
  }
  close $fh;

  foreach $pkgname ( @rqlist )
  {
    %pkg = Repo::RPM::find_package( \%repo, $pkgname );
    if( %pkg )
    {
      push @list, $pkgname;
    }
    else
    {
      print " package: '" . $pkgname . "': not found\n";
    }
  }

  @list = uniq( @list );

  #
  # NOTE: build_requires() find packages with MAX version.
  #
  %reqs = Repo::RPM::build_requires( \%repo, \%requires, "", \@list );

  #
  # Print dependencies in GNU Make style:
  #
  Repo::RPM::print_requires( \%requires, "requires-tree.make-deps" );

=head2 build_install_sequence( \%reqs )

Create the list of RPMs names in the build or installation order according to RPMs dependencies.

Example:

  my %sequence = Repo::RPM::build_install_sequence( \%reqs );

  #
  # Print packages in the installation/build order:
  #
  Repo::RPM::print_install_sequence( \%sequence, "requires-tree.build-sequence" );

  #
  # Print RPMs in the installation/build order:
  #
  Repo::RPM::print_used_rpms( \%repo, \%sequence, "requires-tree.used-rpms" );

=head2 build_requires_tree( \%repo, \%reqs );

This function builds the requires tree in the HTML format. When the requires tree is creates
the target HTML and JSON files can be printed out using print_json_tree() and print_html_tree()
functions:

Example:

  my %tree = Repo::RPM::build_requires_tree( \%repo, \%reqs );
  if( %tree )
  {
    my ($w, $h)  = Repo::RPM::print_json_tree( \%repo, \%tree, "requires-tree.json" );
    if( ! $w )
    {
      print "write json Error!\n";
    }
    else
    {
      my $ret = Repo::RPM::print_html_tree( \%repo, \%tree, $w, $h, "My Custom Distro (oss base)", "https://example.com", "requires-tree.json", "requires-tree.html" );
      if( $ret )
      {
        print "=====  Created Requires Thee file: " . "'requires-tree.html'" . "\n";
      }
    }
  }

=head1 SEE ALSO

L<rpm(8)>,

and RPM4::rpmvercmp(version1, version2) function used to compare RPMs versions.

=cut
