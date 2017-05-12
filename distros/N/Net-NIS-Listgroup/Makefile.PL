#
# $Id: Makefile.PL,v 1.12 2003-01-21 15:44:14-05 mprewitt Exp $
#  
#  Lisgroup Makefile
#
#  Run:
#  
#    perl Makefile.PL 
#    make
#    make install
# 
#  To change the install prefix, pass a --prefix option to 'perl Makefile.PL' as in:
#  
#    perl Makefile.PL --prefix=/usr/local/
#
# --------------------------------------------------------------------------
#
# This file is part of listgroup
#
# listgroup is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
# 
# listgroup is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;

my $opt_prefix;

GetOptions(
    "prefix:s"=>\$opt_prefix,
);

my ( $y, $m, $d ) = (localtime(time))[5, 4, 3];
$y += 1900;
$m++;

$m = "0$m" if $m < 9;
$d = "0$d" if $d < 9;

my $release = "$y$m$d";
my $version = "1.0.0";

my %opts =  (
    ABSTRACT      => 'Utilities to view the nis netgroup map',
    AUTHOR        => 'Marc Prewitt <mprewitt@chelsea.net>',
    NAME          => 'Net',
    DISTNAME      => 'Net-NIS-Listgroup',
    VERSION       => $version,
    DEFINE        => '-DMAKEFILE_PL_VER=' . (qw$Revision: 1.12 $)[1],
    dist          => { COMPRESS=>'gzip -9f', SUFFIX => 'gz',
                     ZIP=>'/usr/bin/zip',ZIPFLAGS=>'-rl'},
    INST_SCRIPT   => './blib/bin',
    EXE_FILES     => [ 'listgroup', 'make_cron' ],
    PREREQ_PM     => { 'Getopt::Long' => 0, 'Net::NIS' => 0 }
);

# Uncomment the next line to customize the install location
# or run:
#
#  perl Makefile.PL --prefix=/opt/mtop/
#
#$opts{PREFIX} = "/usr/local/";

$opts{PREFIX} = $opt_prefix if $opt_prefix;

WriteMakefile( %opts );
