#!/usr/bin/perl
#
# #####################################################################	#
# netsymbols.pl	version 0.10	9-21-16, michael@bizsystems.com		#
#									#
#									#
#     COPYRIGHT 2008-2016 Michael Robinton <michael@bizsystems.com>	#
#									#
# This program is free software; you can redistribute it and/or modify	#
# it under the terms of either:						#
#									#
#  a) the GNU General Public License as published by the Free		#
#  Software Foundation; either version 2, or (at your option) any	#
#  later version, or							#
#									#
#  b) the "Artistic License" which comes with this distribution.	#
#									#
# This program is distributed in the hope that it will be useful,	#
# but WITHOUT ANY WARRANTY; without even the implied warranty of	#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either	#
# the GNU General Public License or the Artistic License for more 	#
# details.								#
#									#
# You should have received a copy of the Artistic License with this	#
# distribution, in the file named "Artistic".  If not, I'll be glad 	#
# to provide one.							#
#									#
# You should also have received a copy of the GNU General Public 	#
# License along with this program in the file named "Copying". If not,	#
# write to the 								#
#									#
#	Free Software Foundation, Inc.					#
#	59 Temple Place, Suite 330					#
#	Boston, MA  02111-1307, USA					#
#									#
# or visit their web page on the internet at:				#
#									#
#	http://www.gnu.org/copyleft/gpl.html.				#
# #####################################################################	#

package NetSymbols;
use diagnostics;
use Config;

my $doprint = 0;

my $conf = \%Config;

my $include = $conf->{usrinc};

sub new {
  return bless {}, __PACKAGE__;
}

my $grep = qx/which grep/;
chop $grep while $grep =~ /\n$/;

my $gfp = sub {
  my($mtch,$include) = @_;
  my $cmd = $grep . $mtch . $include .'/*'."\n";
  my @lines = qx/$cmd/;  
  print STDERR '# ', $cmd if $doprint;
  foreach (@lines) {
    chop $_ while $_ =~ /\s$/;
    print STDERR $_, "\n" if $doprint;
  }
  return @lines;
};

my (@fileAFs,@fileIFs,@fileIN6s);

sub mksymblArrays {
  @fileAFs  = $gfp->(' -rEl "define[[:space:]]+[AP]F_" ',$include);
  @fileIFs  = $gfp->(' -rEl "define[[:space:]]+IF" ',$include);
  @fileIN6s = $gfp->(' -rEl "define[[:space:]]+IN6_IF" ',$include);
}

### generate AF/PF families 

# list of troublesome symbols to ignore
my @donotuse = qw(
	AF_NETGRAPH
	PF_NETGRAPH
);

# list of wanted AF/PF symbols, ignore the rest
# this list should reflect the SOCKADDR's present
# in the header file "ni_fixups.h" plus a few symbols
#
my @wantafsyms = qw(
	AF_UNSPEC
	AF_INET
	AF_INET6
	AF_LOCAL
	AF_FILE
	AF_UNIX
	AF_MAX
	AF_PACKET
	AF_ROUTE
	AF_APPLETALK
	AF_ASH
	AF_X25
	AF_ECONET
	AF_IPX
	AF_ROSE
	AF_LINK
	AF_ISO
	AF_NUTSS
	AF_AX25
	AF_DECnet
	PF_UNSPEC
	PF_INET
	PF_INET6
	PF_LOCAL
	PF_FILE
	PF_UNIX
	PF_MAX
	PF_PACKET
	PF_ROUTE
	PF_APPLETALK
	PF_ASH
	PF_X25
	PF_ECONET
	PF_IPX
	PF_ROSE
	PF_LINK
	PF_ISO
	PF_NUTSS
	PF_AX25
	PF_DECnet
);


my(@slurp,%slurped,%fam,%unique);
my $endv = 0;			# maximum value found in defines

sub cleanslurp {
  undef @slurp;
  %slurped = ();
}

# file string, slurp switch full filename = 1
sub slurp {
  my($in,$sw) = @_;;
  $sw = 0 unless defined $sw;
#print STDERR "slurping $in\n";
  return if $slurped{$in};
  $slurped{$in} = 1;
  local *F;
  my $file = ($sw) ?
	$in : $Config{usrinc} .'/'. $in;
  open (F,$file) or return;
  my @new = <F>;
  close F;
#foreach (@new) {
#  print STDERR "$file => $_\n";
#}
  push @slurp, @new;
}

sub fslurp {
  foreach (@_) {
#print STDERR $_,"\n";
    slurp($_,1);	# tell slurp to use absolute file name
  }
}


# input:	hash pointer,
#		unique hash pointer or false
#		regular expression,
#		secondary regexp if enum (else undef)
#
sub fill {
  my($hp,$unique,$rgx1,$rgx2) = @_;
  my %enum;				# enumeration cache
  foreach(@slurp) {
    if ($_ =~ /^#\s*include\s+\<\s*([^\s>]+)/) {
#print STDERR "\tincfile $1\n";
      slurp($1);
      next;
    }
    if ($rgx2 && $_ =~ /$rgx2/) {
      my $pri = $1;
      my $sec = $2;
#print STDERR "IFF pri=$pri, sec=$sec\n";
     next if $2 =~ /[^0-9x]/;		# must be numeric or hex
      $sec = eval "$sec";
      $enum{$pri} = $sec;
      $endv = $sec if $endv < $sec;	# track maximum value
      next;
    }
    next unless $_ =~ /$rgx1/;
    my $pri = $1;
    my $sec = $2;
#print STDERR "pri=$pri, sec=$sec\n"; 
   if ($rgx2 && exists $enum{$pri} && $pri eq $sec) {
      $hp->{$pri} = $enum{$pri};
      next;
    } elsif ($sec =~ /[^0-9x]/) {	# if this is not a number
      next unless exists $hp->{$sec};	# should not happen
      $hp->{$pri} = $hp->{$sec};
    } else {
      $sec = eval "$sec";
      $hp->{$pri} = $sec;
      $endv = $sec if $endv < $sec;	# track maximum value
      next unless $unique;
      next if exists $unique->{$sec};
#print STDERR "unique $sec\t=> $pri\n";
      $unique->{$sec} = $pri;		# track 1st definition
    }
  }
}


# input: filehandle,
#	 symbol hash
#	 array of symbols synonyms
#
sub extradef {
  my($F,$sym,@syn) = @_;
#print STDERR "extra defs @syn\n";
  my $x;
  foreach(0..$#syn) {			# check each synonym
    if (exists $sym->{$syn[$_]}) {
      $x = $_;
      last;
    }
  }
#print STDERR qq|\n\tadvisory warning\n"@syn"\n\tnot defined\n| unless defined $x;
  return unless defined $x;

# define all undefined synonyms
#
  foreach(0..$#syn) {
    next if $_ == $x;
    my $newsym = $syn[$_];
    print $F "#ifndef $newsym\n# define $syn[$_] $syn[$x]\n#endif\n";
    $sym->{$newsym} = $sym->{$syn[$x]};
  }
}

my $XX = 1;	# 1 = original, 0 = new

sub gensyms {
  mksymblArrays();

  cleanslurp();
if ($XX) {
  slurp('sys/socket.h');			# parse sys/socket.h and its #includes
} else {
  fslurp(@fileAFs);
}
  fill(\%fam,\%unique,'^#\s*define\s+((?:A|P)F_[^\s]+)\s+([^\s]+)');
#  fill(\%fam,\%unique,'^#\s*define\s+((?:A|P)F_[^\s]{2,})\s+([^\s]+)');
# repeat in case symbol dependencies are out of order
  cleanslurp();
if ($XX) {
  slurp('sys/socket.h');
#slurp('sys/types.h');
} else {
  fslurp(@fileAFs);
}
  fill(\%fam,'','^#\s*define\s+((?:A|P)F_[^\s]+)\s+([^\s]+)');
#  fill(\%fam,'','^#\s*define\s+((?:A|P)F_[^\s]{2,})\s+([^\s]+)');


  my %ifs;
  cleanslurp();
if ($XX) {
  slurp('net/if.h');
  slurp('netinet/in.h') if -e '/usr/include/netinet/in.h';
  slurp('netinet/in_var.h') if -e '/usr/include/netinet/in_var.h';
} else {
  fslurp(@fileIFs);
  fslurp(@fileIN6s);
}
  fill(\%ifs,\%unique,'^#\s*define\s+(IF[^\s]+)\s+([^\s]+)','(IF[^\s]+)\s*\=\s*([^\s,]+)');
  fill(\%ifs,\%unique,'^#\s*define\s+(IN6_IF[^\s]+)\s+([^\s]+)','(IN6_IF[^\s]+)\s*\=\s*([^\s,]+)');

#foreach (keys %unique) {
#print STDERR "$_\t=> $unique{$_}\n";
#}
  cleanslurp();
if ($XX) {
  slurp('net/if.h');
  slurp('netinet/in.h') if -e '/usr/include/netinet/in.h';
  slurp('netinet/in_var.h') if -e '/usr/include/netinet/in_var.h';
} else {
  fslurp(@fileIFs);
  fslurp(@fileIN6s);
}
  fill(\%ifs,'','^#\s*define\s+(IF[^\s]+)\s+([^\s]+)','(IF[^\s]+)\s*\=\s*([^\s,]+)');
  fill(\%ifs,'','^#\s*define\s+(IN6_IF[^\s]+)\s+([^\s]+)','(IN6_IF[^\s]+)\s*\=\s*([^\s,]+)');

# dispose of troublesome symbols
  my %ru = reverse %unique;
  foreach my $symhsh (\%ifs,\%fam,\%ru) {
    foreach(@donotuse) {		# remove the ones that cause trouble
      delete $symhsh->{$_} if exists $symhsh->{$_};
    }
  }
  foreach my $symhsh(\%fam) {
    my @allsyms = keys %$symhsh;
    foreach my $havsym (@allsyms) {
      unless (grep {/$havsym/} @wantafsyms) {
        delete $symhsh->{$havsym};	# delete unneeded symbol here
        delete $ru{$havsym};		# and in unique hash
      }
    }
  }
  %unique = reverse %ru;

# fill done, bump max value
  ++$endv;
# we're going to ignore all that end value tracking because IFF's exceed I32
# I32 size. Use the max number that fits in an I32 and do IFF's another way
  $endv = (2**31) -1;

  mkdir 'lib' unless -e 'lib' && -d 'lib';
  mkdir 'lib/Net' unless -e 'lib/Net' && -d 'lib/Net';
  mkdir 'lib/Net/Interface' unless -e 'lib/Net/Interface' && -d 'lib/Net/Interface';

  open(NFe,'>lib/Net/Interface/NetSymbols.pm') or die "could not open NetSymbols.pm for write";
  open(NFx,'>netsymbolXS.inc') or die "could not open netsymbolXS.inc for write";
  open(NFc,'>netsymbolC.inc') or die "could not open netsymbolC.inc for write";
  open(NFt,'>ni_IFF_inc.c') or die "could not open ni_IFF_inc.c for write";
  open(NFz,'>ni_XStabs_inc.c') or die "could not open ni_XStabs_inc.c for write";

  print NFz q|/*	BEGIN ni_XStabs_inc.c
 * ************************************************************	*
 *	DO NOT ALTER THIS FILE					*
 *	IT IS WRITTEN BY Makefile.PL & inst/netsymbols.pl	*
 *	EDIT THOSE INSTEAD					*
 * ************************************************************	*
 * 	some of these symbols may be redundant			*
 * ************************************************************	*/

|;
# make defines for synonyms
  extradef(*NFc,\%fam,qw( PF_LOCAL PF_UNIX PF_FILE AF_LOCAL AF_FILE AF_UNIX )); # are all synonyms
  extradef(*NFc,\%fam,qw( PF_MAX AF_MAX ));
  extradef(*NFc,\%fam,qw( AF_PACKET PF_PACKET AF_ROUTE PF_ROUTE ));
  extradef(*NFc,\%fam,qw( AF_ISO PF_ISO AF_BRIDGE PF_BRIDGE ));
# this one is not correct...  extradef(*NFc,\%fam,qw( AF_NS PF_NS AF_NUTSS PF_NUTSS AF_ATM PF_ATM ));

  extradef(*NFc,\%ifs,qw( IFNAMSIZ IF_NAMESIZE ));

# Fix missing definition
  print NFc "#ifndef IFHWADDRLEN\n#define IFHWADDRLEN 6\n#endif\n";
  $ifs{IFHWADDRLEN} = 6;

# Add opening definition
  print NFc qq|
#define __NI_AF_TEST $endv
|;
  print NFz q|
const ni_iff_t ni_af_sym_tab[] = {
|;
### populate exports

  print NFe q|#!|. $conf->{perlpath} .q|
#
# DO NOT ALTER THIS FILE
# IT IS WRITTEN BY Makefile.PL and inst/netsymbols.pl
# EDIT THOSE INSTEAD
#
package Net::Interface::NetSymbols;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.01;

|;

  print NFx q|void
_net_af_syms()
    ALIAS:
|;

### populate IFF flags
#
  print NFt q|
/*	BEGIN ni_IFF_inc.c	include
 ****************************************************************
 *	DO NOT ALTER THIS FILE					*
 *	IT IS WRITTEN BY Makefile.PL & inst/netsymbols.pl	*
 *	EDIT THOSE INSTEAD					*
 ****************************************************************
 */

const ni_iff_t ni_iff_tab[] = {
|;

### populate C portion
#
  my @tmp = grep {/^AF/} keys %fam;	# tmp store AFs
  my @afs = sort { $fam{$a} <=> $fam{$b} } @tmp;

  @tmp = grep {/^PF/} keys %fam;
  my @pfs = sort { $fam{$a} <=> $fam{$b} } @tmp;

  my @ifs = keys %ifs;
# iffs are not unique so we can safely purge unwanted symbols here
  my @iffs = sort grep {/^IFF_/ && $_ !~ /IFF_DRV/} keys %ifs;
  my @iffIN6 = sort grep {/^IN6_IFF/} keys %ifs;

#foreach (@iffs) {
#  print STDERR "$_\t=> $ifs{$_}\n";
#}
  print NFe q|my @afs = qw(
|;

  foreach(@afs) {
    $_ =~ /AF_([^\s]+)/;
    print NFx "\t$_ = _NI_$_\n";
    print NFe "\t$_\n";
    print NFc qq|#ifdef $_\n\# define _NI_$_ $fam{$_}\n#else\n# define _NI_$_ $endv\n#endif\n|;
    print NFz qq|\t{$_,\t"|, (lc $1), qq|"},\n|;
  }
  print NFe q|);
my @pfs = qw(
|;
  foreach(@pfs) {
    $_ =~ /PF_([^\s]+)/;
    print NFx "\t$_ = _NI_$_\n";
    print NFe "\t$_\n";
    print NFc qq|#ifdef $_\n\# define _NI_$_ $fam{$_}\n#else\n# define _NI_$_ $endv\n#endif\n|;
    print NFz qq|\t{$_,\t"|, (lc $1), qq|"},\n|;
  }
  print NFz qq|\t{__NI_AF_TEST,\t"placeholder"}
};
|;

  print NFx qq|\t_NI_AF_TEST = __NI_AF_TEST
    PREINIT:
	SV * rv;
	int n, i;
    PPCODE:
	if (ix >= $endv) {
	    croak("%s is not implemented on this architecture", GvNAME(CvGV(cv)));
	}
	rv = sv_2mortal(newSViv(ix));
	n = sizeof(ni_af_sym_tab) / sizeof(ni_iff_t);
	for (i=0; i<n; i++) {
	    if (ni_af_sym_tab[i].iff_val == ix) {
		sv_setpv(rv,ni_af_sym_tab[i].iff_nam);
		break;
	    }
	}
	SvIOK_on(rv);
	XPUSHs(rv);
	XSRETURN(1);


int
_net_if_syms()
    ALIAS:
|;

  print NFe q|);
my @ifs = qw(
|;

  my $ifidx = 0;
  my $idxary = q|
const u_int64_t bigsymvals[] = {|;
  my $icoma = '';

  foreach (@ifs) {
    print NFe "\t$_\n";
    next if $_ =~ /IFF_/;
    print NFc qq|#ifdef $_\n\# define _NI_$_ $_\n#else\n# define _NI_$_ $endv\n#endif\n|;
#  print NFx "\t$_ = _NI_$_\n";
    print NFx "\t$_ = $ifidx\n";
    $idxary .= "$icoma\n\t$ifs{$_}";
    $icoma = ',';
    $ifidx++;
  }

  print NFz qq|
const ni_iff_t ni_sym_iff_tab[] = {
|;

  print NFe q|);
my @iffs = qw(
|;

  print NFx qq|    CODE:
	if (ix >= $endv) {
	    croak("%s is not implemented on this architecture", GvNAME(CvGV(cv)));
	}
	RETVAL = bigsymvals[ix];
    OUTPUT:
	RETVAL


void
_net_i2f_syms()
    ALIAS:
|;

  $comma = '';
  foreach(sort @iffs) {
    $_ =~ /IFF_([^\s]+)/;
    print NFc qq|#ifdef $_\n\# define _NI_$_ $_\n#else\n# define _NI_$_ $endv\n#endif\n|;
    print NFz qq|\t{$_,\t"|, (lc $1), qq|"},\n|;
    print NFe "\t$_\n";
#  print NFx "\t$_ = _NI_$_\n";
    print NFx "\t$_ = $ifidx\n";
    $idxary .= "$icoma\n\t$ifs{$_}";
    $ifidx++;
    next if $_ eq 'IFF_UP';	# special case handled separately
    print NFt qq|$comma\n\t\{$_,\t"$1"\}|;
    $comma = ',';
  }
  print NFt q|
};

#ifdef HAVE_STRUCT_IN6_IFREQ
const ni_iff_t ni_iff_tabIN6[] = {
|;

  print NFe q|);
my @iffIN6 = qw(
|;

  $comma = '';
  foreach(sort @iffIN6) {
    $_ =~ /IFF_([^\s]+)/;
    print NFc qq|#ifdef $_\n\# define _NI_$_ $_\n#else\n# define _NI_$_ $endv\n#endif\n|;
    print NFz qq|\t{$_,\t"|. (lc $1). qq|"},\n|;
    next if $_ eq 'IFF_UP';	# special case handled separately
    print NFe "\t$_\n";
#  print NFx "\t$_ = _NI_$_\n";
    print NFx "\t$_ = $ifidx\n";
    $idxary .= "$icoma\n\t$ifs{$_}";
    $ifidx++;
    print NFt qq|$comma\n\t\{$_,\t"$1"\}|;
    $comma = ',';
  }
  print NFz qq|\t{__NI_AF_TEST,\t"placeholder"}
};

$idxary
};
|;

  print NFt q|
};
#endif
/*	END ni_IFF_inc.c	include		*/
|;

  print NFe q|);
my %unique = (
|;

  my $utxt = '';
  foreach(sort {$a <=> $b} keys %unique) {
    $utxt .= "\t$_\t=> '". $unique{$_} ."',\n";
  }

  print NFe $utxt, q|);

my @iftype = qw(
    IPV6_ADDR_ANY
    IPV6_ADDR_UNICAST
    IPV6_ADDR_MULTICAST
    IPV6_ADDR_ANYCAST
    IPV6_ADDR_LOOPBACK
    IPV6_ADDR_LINKLOCAL
    IPV6_ADDR_SITELOCAL
    IPV6_ADDR_COMPATv4
    IPV6_ADDR_SCOPE_MASK
    IPV6_ADDR_MAPPED
    IPV6_ADDR_RESERVED
    IPV6_ADDR_ULUA
    IPV6_ADDR_6TO4
    IPV6_ADDR_6BONE
    IPV6_ADDR_AGU
    IPV6_ADDR_UNSPECIFIED
    IPV6_ADDR_SOLICITED_NODE
    IPV6_ADDR_ISATAP
    IPV6_ADDR_PRODUCTIVE
    IPV6_ADDR_6TO4_MICROSOFT
    IPV6_ADDR_TEREDO
    IPV6_ADDR_ORCHID
    IPV6_ADDR_NON_ROUTE_DOC
);

my @scope = qw(
    RFC2373_GLOBAL
    RFC2373_ORGLOCAL
    RFC2373_SITELOCAL
    RFC2373_LINKLOCAL
    RFC2373_NODELOCAL
    LINUX_COMPATv4
);

@EXPORT_OK = (@afs,@pfs,@ifs,@iftype,@scope);
%EXPORT_TAGS = (
	all	=> [@afs,@pfs,@ifs,@iftype,@scope],
	afs	=> [@afs],
	pfs	=> [@pfs],
	ifs	=> [@ifs],
	iffs	=> [@iffs],
	iffIN6	=> [@iffIN6],
	iftype	=> [@iftype],
	scope	=> [@scope],
);

sub NI_ENDVAL {return |. $endv .q|};
sub NI_UNIQUE {return \%unique};
sub DESTROY {};

1;
__END__

=head1 NAME

Net::Interface::NetSymbols - AF_ PF_ IFxxx type symbols

=head1 SYNOPSIS

This module is built for this specific architecture during the F<make> 
process using F<inst/netsymbols.pl>. Do not edit this module, edit
F<inst/netsymbols.pl> instead.

This module contains symbols arrays only for use by Net::Interface, in all other
respects it is NOT functional. It contains documentation and data arrays 
for this specific architecture.

B<NOTE:>	WARNING !!

     usage is Net::Interface

B<NOT>  Net::Interface::NetSymbols

use Net::Interface qw(

	Net::Interface::NetSymbols::NI_ENDVAL();
	Net::Interface::NetSymbols::NI_UNIQUE();
|;

  print NFe qq|@afs

@pfs

@ifs

@iffs
|;

  if (@iffIN6) {
    print NFe qq|
@iffIN6	populated for BSD flavored systems

:all :afs :pfs :ifs :iffs :iffIN6 :iftype :scope

);
|;
  } else {
    print NFe qq|
:all :afs :pfs :ifs :iffs :iftype :scope

);
|;
  }
  print NFe q|
=head1 DESCRIPTION

All of the AF_XXX and PF_XXX symbols available in local C<sys/socket.h> plus
usual aliases for AF_LOCAL i.e. (AF_FILE AF_UNIX PF_LOCAL PF_FILE PF_UNIX)

All of the IFxxxx and IN6_IF symbols in C<net/if.h, netinet/in.h, netinet/in_var.h> and
their includes.

Symbols may be accessed for their numeric value or their string name.

  i.e.	if ($family == AF_INET)
	    do something...

    or	print AF_INET
    will product the string "inet"

The same holds true for:

	printf("family is %s",AF_INET);
    or	sprint("family is %s",AF_INET);

To print the numeric value of the SYMBOL do:

	print (0 + SYMBOL), "\n";

|;

  if (exists $fam{AF_INET6}) {
    print NFe q|On systems supporting IPV6, these additional symbols are available which
may be applied to the address I<type> to determine the address attributes.

    IPV6_ADDR_ANY		unknown
    IPV6_ADDR_UNICAST		unicast
    IPV6_ADDR_MULTICAST		multicast
    IPV6_ADDR_ANYCAST		anycast
    IPV6_ADDR_LOOPBACK		loopback
    IPV6_ADDR_LINKLOCAL		link-local
    IPV6_ADDR_SITELOCAL		site-local
    IPV6_ADDR_COMPATv4		compat-v4
    IPV6_ADDR_SCOPE_MASK	scope-mask
    IPV6_ADDR_MAPPED		mapped
    IPV6_ADDR_RESERVED		reserved
    IPV6_ADDR_ULUA		uniq-lcl-unicast
    IPV6_ADDR_6TO4		6to4
    IPV6_ADDR_6BONE		6bone
    IPV6_ADDR_AGU		global-unicast
    IPV6_ADDR_UNSPECIFIED	unspecified
    IPV6_ADDR_SOLICITED_NODE	solicited-node
    IPV6_ADDR_ISATAP		ISATAP
    IPV6_ADDR_PRODUCTIVE	productive
    IPV6_ADDR_6TO4_MICROSOFT	6to4-ms
    IPV6_ADDR_TEREDO		teredo
    IPV6_ADDR_ORCHID		orchid
    IPV6_ADDR_NON_ROUTE_DOC	non-routeable-doc

    if ($type & IPV6_ADDR_xxxx) {
	print IPV6_ADDR_xxxx,"\n";
    }

These symbols may be equated to the I<scope> of the address.

    RFC2373_GLOBAL		global-scope
    RFC2373_ORGLOCAL		org-local
    RFC2373_SITELOCAL		site-local
    RFC2373_LINKLOCAL		link-local
    RFC2373_NODELOCAL		loopback
    LINUX_COMPATv4		lx-compat-v4

    if ($scope eq RFC2373_xxxx) {
	print RFC2373_xxxx,"\n";
    }

|;
  }

  print NFe q|
=over 4

=item * :all	Import all symbols

=item * :afs	Import all AF_XXX symbols

=item * :pfs	Import all PF_XXX symbols

=item * :ifs	Import all IFxxxx symbols

=item * :iffs	Import all IFF symbols
|;

  if (@iffIN6) {
    print NFe q|
=item * :iffIN6	Import all IN6_IFF symbols (BSD flavors only)
|;
  }

  if (exists $fam{AF_INET6}) {
    print NFe q|
=item * :iftype	Import all IPV6 type symbols

=item * :scope	Import all IPV6 scope symbols
|;
  }

  print NFe q|
=back

=head1 non EXPORT functions

=over 4

=item * Net::Interface::NetSymbols::NI_ENDVAL();

Reports the highest symbol value +1 of :all symbols above. Used for testing.

=item * Net::Interface::NetSymbols::NI_UNIQUE();

Returns a hash pointer to the AF_ or PF_ symbol values mapped to their
character strings as defined for this architecture.

  i.e.
|, $utxt, q|
=head1 AUTHOR	Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT	|. ((localtime())[5] +1900) .q|

Michael Robinton, all rights reserved.

This library is free software. You can distribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
|;

# add test element and complete
  print NFx qq|    PREINIT:
	SV * rv;
	int n, i;
    PPCODE:
	if (ix >= $endv) {
	    croak("%s is not implemented on this architecture", GvNAME(CvGV(cv)));
	}
	rv = sv_2mortal(newSVnv(bigsymvals[ix]));
	n = sizeof(ni_sym_iff_tab) / sizeof(ni_iff_t);
	for (i=0; i<n; i++) {
	    if (ni_sym_iff_tab[i].iff_val == bigsymvals[ix]) {
		sv_setpv(rv,ni_sym_iff_tab[i].iff_nam);
		break;
	    }
	}
	SvNOK_on(rv);
	XPUSHs(rv);
	XSRETURN(1);

|;

# usually _LOCAL is defined on modern systems
#

  close NFe;
  close NFx;
  close NFc;
  close NFt;
#  exit;
}
gensyms();
1;
