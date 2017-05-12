package No::Sort;

require 5.002;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $DEBUG);
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(no_sort);
@EXPORT_OK=qw(no_xfrm no_aa_xfrm
	      latin1_uc latin1_lc latin1_ucfirst latin1_lcfirst);

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


=head1 NAME

No::Sort - Norwegian sorting

=head1 SYNOPSIS

  use No::Sort;
  @sortert = no_sort @norske_ord;

=head1 DESCRIPTION

This module provde the function no_sort() which sort a ISO-8859/1
encoded string according to Norwegian practice.  The routine works
like the normal perl sort routine, but the optional first argument is
special.  It can either be a reference to the strxfrm() function to
use while sorting or a reference to a hash used to transform the words
while sorting.

You can also import the no_xfrm() function which is used for standard
sorting.  It can be useful to base your custom transformation function
on it.  If we for instance would like to sort "Aa" as "Å" we could
implement it like this:

  use No::Sort qw(no_sort no_xfrm);
  sub my_xfrm {
      my $word = shift;
      $word =~ s/A[aA]/Å/g;
      $word =~ s/aa/å/g;
      no_xfrm($word);
  }
  @sorted = no_sort \&my_xfrm, @names;

By the way, the my_xfrm shown in this example can be imported from
this module under the name 'no_aa_xfrm':

  use No::Sort qw(no_sort no_aa_xfrm);
  @sorted = no_sort \&no_aa_xfrm, @names;

If you set the $No::Sort::DEBUG variable to a TRUE value, then we will
make some extra noise on STDOUT while sorting.

The module can also export functions for up/down casing ISO-8859/1
strings.  These functions are called latin1_uc(), latin1_lc(),
latin1_ucfirst(), latin1_lcfirst().

=head1 SEE ALSO

L<perllocale>

=head1 AUTHORS

Hallvard B Furuseth <h.b.furuseth@usit.uio.no>, Gisle Aas <gisle@aas.no>

=cut

sub no_sort {
    my $xfrm;  # ref to sort hash
    if (ref $_[0]) {
	if (ref($_[0]) eq "CODE") {
	    my $code = shift;
	    @{$xfrm}{@_} = map &$code($_), @_;
	} elsif (ref($_[0]) eq "HASH") {
	    $xfrm = shift;
	}
    }
    @{$xfrm}{@_} = map no_xfrm($_), @_ unless $xfrm;

    if ($DEBUG) {
	my @s = sort { $xfrm->{$a} cmp $xfrm->{$b} || $a cmp $b } @_;
	printf STDERR "%-20s %s\n", "ORD", "SORTERES SOM";
	print STDERR "-" x 20, " ", "-" x 40, "\n";
	for (@s) {
	    printf STDERR "%-20s %s\n", $_, $xfrm->{$_};
	}
	return @s;
    }

    sort { $xfrm->{$a} cmp $xfrm->{$b} || $a cmp $b } @_;
}

sub no_xfrm {
    my $p1 = shift;

    # Ikke-alfanumeriske tegn regnes som en enkelt blank
    # (eller sikkert litt mer komplisert, f.eks whitespace -> blank,
    # punktum o.l -> et annet "lite" tegn, med blanke fjernet på begge
    # sider, osv...
    $p1 =~ tr/\0-\040\177\200-\240/ /s;
    $p1 =~ tr/ 0-9_A-Za-zÀ-ÖØ-ßà-öø-ÿ/,/cs
	and $p1 =~ s/,[ ,]+/,/g;

    # Plasser æøå i riktig rekkefølge.  Tar med svensk äø også.
    # (Egentlig burde *alle* tegn transformeres slik at ting kommer i
    # riktig rekkefølge her, men da blir resten av programmet så uleselig...)
    $p1 =~ tr[æäøöåÆÄØÖÅ]
	     [ååææøÅÅÆÆØ];

    # Aksenter telles bare hvis uaksentede tegn er like
    my $p2 = $p1;
    $p2 =~ tr[ÀÁÂÃÄÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖÙÚÛÜİŞßàáâãäçèéêëìíîïğñòóôõöùúûüışÿ]
             [AAAAÆCEEEEIIIIDNOOOOØUUUUYTSaaaaæceeeeiiiidnooooøuuuuyty];

    # Store & små bokstaver er bare forskjellig hvis alt annet er likt
    my $p3 = $p2;
    $p3 =~ tr[A-ZÆØÅ]
             [a-zæøå];

    join("\1", $p3, $p2, $p1);
}

sub no_aa_xfrm {
      my $word = shift;
      $word =~ s/A[aA]/Å/g;
      $word =~ s/aa/å/g;
      no_xfrm($word);
}

# Some additional case convertion routines that does not really have
# much to do with sorting.

sub latin1_lc
{
    my $str = shift;
    $str =~ tr[A-ZÀ-ÖØ-Ş]
	      [a-zà-öø-ş];
    $str;
}

sub latin1_uc
{
    my $str = shift;
    $str =~ tr[a-zà-öø-ş]
	      [A-ZÀ-ÖØ-Ş];
    $str;
}

sub latin1_ucfirst
{
    my $str = shift;
    $str =~ s/(.)/latin1_uc($1)/es;
    $str;
}

sub latin1_lcfirst
{
    my $str = shift;
    $str =~ s/(.)/latin1_lc($1)/es;
    $str;
}

1;
