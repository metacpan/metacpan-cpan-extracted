package R3;
# Copyright (c) 1999 Johan Schoen. All rights reserved.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( );

$VERSION = '0.31';

use R3::rfcapi;
use R3::conn;
use R3::func;
use R3::itab;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the documentation of the module.

=head1 NAME

R3.pm - Perl object oriented client interface to SAP R/3 using RFCSDK

=head1 SYNOPSIS

  use R3;
  $conn = new R3::conn (host=>$host, sysnr=>$sysnr, client=>$client,
  user=>$usr, passwd=>$passwd);
  $itab = new R3::itab ($conn, $table_name);
  $func = new R3::func ($conn, $func_name);
  ...

=head1 DESCRIPTION

R3.pm provides an object oriented interface to SAP's RFCSDK for
connection to an R/3 system. R3::conn is the object interface to R/3
connections. R3::itab is the object interface to ABAP internal tables.
R3::func is the object interface to ABAP RFC enabled functions.

=head1 AUTHOR

Johan Schoen, johan.schon@capgemini.se

=head1 SEE ALSO

perl(1), R3::conn(3), R3::func(3), R3::itab(3) and R3::rfcapi(3).

=cut
