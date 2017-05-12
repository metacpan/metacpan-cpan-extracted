package Statistics::RserveClient;
use strict;


    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    our $VERSION = '0.12'; #VERSION

    @ISA         = qw(Exporter);
    our @EXPORT = qw( TRUE FALSE );

    our @EXPORT_OK = (
       'XT_NULL',       'XT_INT',
        'XT_DOUBLE',     'XT_STR',
        'XT_LANG',       'XT_SYM',
        'XT_BOOL',       'XT_S4',
        'XT_VECTOR',     'XT_LIST',
        'XT_CLOS',       'XT_SYMNAME',
        'XT_LIST_NOTAG', 'XT_LIST_TAG',
        'XT_LANG_NOTAG', 'XT_LANG_TAG',
        'XT_VECTOR_EXP', 'XT_VECTOR_STR',
        'XT_ARRAY_INT',  'XT_ARRAY_DOUBLE',
        'XT_ARRAY_STR',  'XT_ARRAY_BOOL_UA',
        'XT_ARRAY_BOOL', 'XT_RAW',
        'XT_ARRAY_CPLX', 'XT_UNKNOWN',
        'XT_FACTOR',     'XT_HAS_ATTR',
    );
 
    our %EXPORT_TAGS = (
        xt_types => [
            'XT_NULL',       'XT_INT',
            'XT_DOUBLE',     'XT_STR',
            'XT_LANG',       'XT_SYM',
            'XT_BOOL',       'XT_S4',
            'XT_VECTOR',     'XT_LIST',
            'XT_CLOS',       'XT_SYMNAME',
            'XT_LIST_NOTAG', 'XT_LIST_TAG',
            'XT_LANG_NOTAG', 'XT_LANG_TAG',
            'XT_VECTOR_EXP', 'XT_VECTOR_STR',
            'XT_ARRAY_INT',  'XT_ARRAY_DOUBLE',
            'XT_ARRAY_STR',  'XT_ARRAY_BOOL_UA',
            'XT_ARRAY_BOOL', 'XT_RAW',
            'XT_ARRAY_CPLX', 'XT_UNKNOWN',
            'XT_FACTOR',     'XT_HAS_ATTR',
        ]
    );


#################### main pod documentation begin ###################

=head1 NAME

Statistics::RserveClient - An Rserve Client library for the R statistics platform.

=head1 SYNOPSIS

  use Statistics::RserveClient::Connection;

  my $cnx = new Statistics::RserveClient::Connection('localhost');
  my @result = $cnx->evalString("x='Hello, world!'; x");

=head1 DESCRIPTION

Rserve provides a connection-oriented network interface to the R
statistical platform. The Statistics::RserveClient package provides a
Perl client library to enable interaction with Rserve from within Perl
applications.

Using RserveClient, your Perl application can pass strings to Rserve
for evaluation by R. The results are returned as Perl arrays.

=head1 USAGE

  use Statistics::RserveClient::Connection;

  my $cnx = new Statistics::RserveClient::Connection('localhost');
  my @result = $cnx->evalString("x='Hello, world!'; x");


=head1 BUGS

This library does not yet support the full rserve protocol. For
example, long packets are not supported.

=head1 SUPPORT

Please visit http://github.com/djun-kim/Statistics--RserveClient to
view/file bug reports and feature requests and to browse additional
documentation.

=head1 AUTHOR

    Djun M. Kim
    CPAN ID: DJUNKIM
    Cielo Systems Inc.
    info@cielosystems.com
    http://github.org/djun-kim/Statistics--RserveClient/wiki

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

This software was partially funded through the financial assistance of
the University of British Columbia, via a Teaching and Learning
Enhancement Fund project led by Dr. Bruce Dunham (UBC Statistics).

The author would also like to thank Dr. Davor Cubranic (UBC
Statistics) for many improvements to the code, in particular most of
the tests.

=head1 SEE ALSO

rserve: (http://www.rforge.net/Rserve/)

R project: http://r-project.org

=cut

#################### main pod documentation end ###################

#use warnings;
#use autodie;

use constant FALSE => 0;
use constant TRUE  => 1;

use constant DebugLogfile  => "/tmp/rserve-debug.log";

open(DEBUGLOG, '>'.DebugLogfile) or die("can't open debug log: $!\n");

my %typeHash = ();

my $DEBUG = FALSE;

##
# =head2 debug()
#
# Usage     : debug("This is a debug message;");
# Purpose   : Prints a string to the debugging output stream.
# Argument  : A string to be output to the debug stream.
#
# =cut

sub debug($) {
  my $msg = shift;
  $msg = "debug [". caller() . "] $msg";
  print DEBUGLOG $msg if ($DEBUG);
  return 1;
}

##
# =head2 buf2str()
# 
#  Usage     : buf2str(\@buf);
#  Purpose   : Takes a (reference to) a given array and returns a string representation
#  Argument  : A reference to an array.
#  Returns   : A string representation of the given array.
#  Comments  : Utility routine, intended to help printing debugging output.
# 
# =cut

sub buf2str {
    my $r = shift;
    my @buf = @{$r};
    my $pbuf = "";
    for (my $idx = 0; $idx < @buf; $idx++) {
	my $c = $buf[$idx];
	my $ord = ord($c);
	if ($ord < ord('A')) {
	    $c = "";
	}
	$pbuf .= "[$idx:$ord:$c]";
	if ($idx % 8 == 7) {$pbuf .= "\n"};
    };
    return $pbuf;
}

# xpression type: NULL
use constant XT_NULL => 0;
$typeHash{0} = 'XT_NULL';

# xpression type: integer
use constant XT_INT => 1;
$typeHash{1} = 'XT_INT';

# xpression type: double
use constant XT_DOUBLE => 2;
$typeHash{2} = 'XT_DOUBLE';

# xpression type: String
use constant XT_STR => 3;
$typeHash{3} = 'XT_STR';

# xpression type: language construct (currently content is same as list)
use constant XT_LANG => 4;
$typeHash{4} = 'XT_LANG';

# xpression type: symbol (content is symbol name: String)
use constant XT_SYM => 5;
$typeHash{5} = 'XT_SYM';

# xpression type: RBool
use constant XT_BOOL => 6;
$typeHash{6} = 'XT_BOOL';

# xpression type: S4 object
#  @since Rserve 0.5
use constant XT_S4 => 7;
$typeHash{7} = 'XT_S4';

# xpression type: generic vector (RList)
use constant XT_VECTOR => 16;
$typeHash{16} = 'XT_VECTOR';

# xpression type: dotted-pair list (RList)
use constant XT_LIST => 17;
$typeHash{17} = 'XT_LIST';

# xpression type: closure
# (there is no java class for that type (yet?).
# Currently the body of the closure is stored in the content
# part of the REXP. Please note that this may change in the future!)
use constant XT_CLOS => 18;
$typeHash{18} = 'XT_CLOS';

# xpression type: symbol name
# @since Rserve 0.5
use constant XT_SYMNAME => 19;
$typeHash{19} = 'XT_SYMNAME';

# xpression type: dotted-pair list (w/o tags)
# @since Rserve 0.5
use constant XT_LIST_NOTAG => 20;
$typeHash{20} = 'LIST_NOTAG';

# xpression type: dotted-pair list (w tags)
# @since Rserve 0.5
use constant XT_LIST_TAG => 21;
$typeHash{21} = 'LIST_TAG';

# xpression type: language list (w/o tags)
# @since Rserve 0.5
use constant XT_LANG_NOTAG => 22;
$typeHash{22} = 'LANG_NOTAG';

# xpression type: language list (w tags)
# @since Rserve 0.5
use constant XT_LANG_TAG => 23;
$typeHash{23} = 'LANG_TAG';

# xpression type: expression vector
use constant XT_VECTOR_EXP => 26;
$typeHash{26} = 'VECTOR_EXP';

# xpression type: string vector
use constant XT_VECTOR_STR => 27;
$typeHash{27} = 'VECTOR_STR';

# xpression type: int[]
use constant XT_ARRAY_INT => 32;
$typeHash{32} = 'ARRAY_INT';

# xpression type: double[]
use constant XT_ARRAY_DOUBLE => 33;
$typeHash{33} = 'ARRAY_DOUBLE';

# xpression type: String[] (currently not used, Vector is used instead)
use constant XT_ARRAY_STR => 34;
$typeHash{34} = 'ARRAY_STR';

# internal use only! this constant should never appear in a REXP
use constant XT_ARRAY_BOOL_UA => 35;
$typeHash{35} = 'XT_ARRAY_BOOL_UA';

# xpression type: RBool[]
use constant XT_ARRAY_BOOL => 36;
$typeHash{36} = 'XT_ARRAY_BOOL';

# xpression type: raw (byte[])
# @since Rserve 0.4-?
use constant XT_RAW => 37;
$typeHash{37} = 'XT_RAW';

# xpression type: Complex[]
# @since Rserve 0.5
use constant XT_ARRAY_CPLX => 38;
$typeHash{38} = 'ARRAY_CPLX';

# xpression type: unknown; no assumptions can be made about the content
use constant XT_UNKNOWN => 48;
$typeHash{48} = 'XT_UNKNOWN';

# xpression type: RFactor; this XT is internally generated (ergo is
# does not come from Rsrv.h) to support RFactor class which is built
# from XT_ARRAY_INT
use constant XT_FACTOR => 127;
$typeHash{127} = 'XT_FACTOR';

# used for transport only - has attribute
use constant XT_HAS_ATTR => 128;
$typeHash{128} = 'HAS_ATTR';

sub import {

    Statistics::RserveClient->export_to_level( 1, @_ );

}


1;
# The preceding line will help the module return a true value
