
package Test::Depends;

use strict 'vars', 'subs';
use 5.006;
use warnings;

our $VERSION = 0.06;

=head1 NAME

Test::Depends - Gracefully skip tests if missing modules

=head1 SYNOPSIS

 use Test::Depends qw(Some::Module), [ SomeOtherModule => 1.1 ];

=head1 DESCRIPTION

This module requires the modules that you asked for, and if some of
them are not there, it will bail out and exit saying which ones and
why.

=cut

use Data::Dumper;

sub import {
    my $package = shift;
    my $caller = caller();

    my @missing;

    while ( my $package = shift ) {
	my $eval = ("# line 0 \"Test::Depends generated\"\n"
		    ."package $caller;\n");
	my $import = "";
	my $wanted_version;
	if ( ref $package and ref $package eq "ARRAY" ) {
	    ($package, my @args) = (@$package);
	    no warnings 'numeric';
	    if ( @args == 1 and
		 not ref $args[0] and
		 ( $args[0]+0 != 0 or $args[0]+0 eq $args[0] )
	       ) {
		$wanted_version = $args[0];
		($import = $wanted_version) =~ s{'}{\'}g;
		$import = " '$import'";
	    } else {
		local($Data::Dumper::Purity) = 1;
		local($Data::Dumper::Varname) = "bob";
		my $dumped = Data::Dumper->Dump([\@args]);
		$dumped =~ s{\A\$bob1 = }{};
		$import = ' @{'.$dumped.'}';
	    }
	}
	$eval .= "use $package$import;";
	eval $eval;
	$eval =~ s{^}{#    }mg;
	#print STDERR "# RAN:\n$eval\n" if ( -t STDOUT );
	if ( $@ ) {
	    (my $pm = $package) =~ s{::}{/}g;
	    $pm .= ".pm";
	    if ( $wanted_version and ${"${package}::VERSION"} ) {
		push @missing, "$package (${$package.'::VERSION'} < $wanted_version)", $@;
	    } elsif ( exists $INC{$pm} ) {
		push @missing, "$package (import failure)", $@;
	    } else {
		push @missing, "$package", $@;
	    }
	}
    }

    if ( @missing ) {
	print("1..0 # Skip missing/broken dependancies");
	if ( -t STDOUT ) {
	    print "\n";
	    while ( my ($pkg, $err) = splice @missing, 0, 2 ) {
		$err =~ s{^}{\t}gm;
		print STDERR ("ERROR - pre-requisite $pkg "
			      ."failed to load:\n$err\n");
	    }
	} else {
	    my $i;
	    print "; ".join(", ", grep { !($i++ % 2) } @missing)."\n";
	}
	exit(0);
    }

}

1;

__END__

=head1 SEE ALSO

L<Test::More>

=head1 AUTHOR

Sam Vilain, <samv@cpan.org>.

=head1 LICENSE

Copyright (c) 2005, 2006, Catalyst IT (NZ) Ltd.  This program is free
software; you may use it and/or redistribute it under the same terms
as Perl itself.

=head1 CHANGELOG

For the complete history,

  git clone git://utsl.gen.nz/Test-Depends

=over

=item 0.06, 13 Nov 2007

fix Win32 compatibility [Matthew Musgrove].  Releases 0.04 and 0.05
were missing Makefile.PL's and were retracted.

=item 0.03, 25 May 2006

Uncomment debugging line C<:-}>

=item 0.02, 25 May 2006

If you specified import arguments to a dependency, they ended up
applying to unadorned arguments further in the dependency list.
Whoops!  C<no strict>

=back

=cut

