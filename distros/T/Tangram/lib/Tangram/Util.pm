
package Tangram::Util;

# this space is for useful functions for tangram internals

our @EXPORT_OK = qw(pretty d);
use base qw(Exporter);

sub pretty {
    my $thingy = shift;
    if (defined($thingy)) {
	return "`$thingy'";
    } else {
	return "undef";
    }
}

use Scalar::Util qw(blessed reftype refaddr);
use Set::Object qw(is_int is_string is_double);
use Data::Dumper qw(Dumper);

# a compact, non-intrusive, non-recursive dumper.  Similar to
# Class::Tangram::quickdump.
sub d {
    return join "\n", map { d($_) } @_ if @_ > 1;
    my @r;
    if ( my $tie = tied $_[0] ) {
	push @r, "(tied to ", $tie, ")";
    }
    elsif ( ref $_[0] ) {
	push @r, ref($_[0]), "@", sprintf("0x%.8x", refaddr($_[0])),
	    (blessed($_[0]) ? (" (", reftype($_[0]), ")") : ()),
		"\n";
	if ( reftype $_[0] eq "HASH" ) {
	    for my $k (sort keys %{ $_[0] }) {
		eval {
		    push @r, "   ",$k," => ",
			( tied $_[0]{$k}
			  || ( ref $_[0]{$k}
			       ? $_[0]{$k}
			       : ( defined ($_[0]{$k})
				   ? "'".$_[0]{$k}."'"
				   : "undef" )
			     )
			), "\n";
		};
		if ($@) {
		    push @r, "   ", $k, " => Error('", $@, "')\n";
		}
	    }
	}
    } else {
	push @r, "(scalar, ",
	    join (",",
		  ( is_int($_[0]) ? ("I=".(0+$_[0])) : () ),
		  ( is_double($_[0]) ? ("N=".(0+$_[0])) : () ),
		  ( is_string($_[0]) ? (do {
		      local($Data::Dumper::Terse)=1;
		      my $string = Dumper($_[0]);
		      chomp($string);
		      "P=$string";
		  }) : () ),
		 ), ")";
    }
    return join "", @r;
}

1;
