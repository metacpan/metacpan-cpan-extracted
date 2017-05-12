package Statistics::SocialNetworks;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Statistics::SocialNetworks ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	constraint
	c
	p
	CTdi
	flushCache
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

my %p = (); # cache for p() results

sub m {
	my $g = shift;
	my $i = shift;
	my $j = shift;
	my %g = %{$g};

	return $g{$i}{$j} if defined $g{$i}{$j};
	return 0;
}

sub flushCache {
	%p = ();
}

sub CTdi {
	#Coleman-Theil disorder index
	#a measure of diversity of contacts
	#0 = same for all contacts
	#1 = all constraint is measured in a single relationship

	my $g = shift;
	my $i = shift;
	my %g = %{$g};

	my @N = keys %{$g{$i}};

	my $N = $#N + 1;

	return 1 if ( $N == 1 );

	my $sum = 0;
	my $C = constraint($g,$i);
	if ( $C ) {
		foreach my $j ( @N ) {
			next if ($j eq $i);
			my $factor = c($g, $i, $j)/($C/$N);
			$sum += $factor * log($factor) if ( $factor );
		}
		$sum /= ($N * log($N));
	}
	return $sum;
}

sub p {
	my $g = shift; # graph
	my $i = shift;
	my $j = shift;
	my %g = %{$g};

	return $p{$i}{$j} if (defined $p{$i}{$j});

	my @v = keys %{$g{$i}};
	my $z = 0;
	
	my $total_w = 0;
	my $n;
	my $w = undef;
	foreach $n ( @v ) {
		$w = $g{$i}{$n} || 1;
		$total_w += $w;
		next unless ( $n eq $j );
		$z += $w;
	}

	return $p{$i}{$j} = 0 unless ($z > 0);

	$p{$i}{$j} = ($z/($total_w));
	return $p{$i}{$j};
	
}

sub c {
	my $g = shift; # graph
	my $i = shift;
	my $j = shift;
	my %g = %{$g};

	my $sum = p($g,$i,$j);

	my @v = keys %{$g{$i}};
	my $key;
	foreach $key ( @v ) {
		next if $key eq $i;
		next if $key eq $j;
		$sum += p($g, $i, $key) * p($g, $key, $j);
	}

	return $sum * $sum;
}

sub constraint {
	my $g = shift; # graph
	my $i = shift;
	my %g = %{$g};

	my $sum = 0;

	my @v = keys %{$g{$i}};
	return 1 if ($#v == 0);
	my $node;
	foreach $node ( @v ) {
		next if ( $node eq $i );
		$sum += c($g, $i, $node);
	}
	
	return $sum;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Statistics::SocialNetworks - Perl extension for calculating network constraint and other network statistics.

=head1 SYNOPSIS

  use Statistics::SocialNetworks ':all';
 
  # create hash representing graph
  my %g;
  foreach $f ( qw( a b c ) ) {
    foreach $t ( qw( a b c ) ) {
      next if $f eq $t;
      $g{$f}{$t} = rand();
    }
  }

  # every time the network changes and before calculations
  # not needed if you are only creating the graph once
  flushCache();

  # print out Burt network constraint value for each node
  foreach $f ( keys %g ) {
    print "$f,", constraint(\%g,$f), "\n";
  }

  # print out Coleman-Theil disorder index for each node
  foreach $f ( keys %g ) {
    print "$f,", CTdi(\%g,$f), "\n";
  }

=head1 DESCRIPTION

Calculates Burt's network constraint value on nodes within a hash based network representation.  An earlier version (not public) was based on Graph, but that was too slow for networks of size.

=head2 Methods

=over 4

=item * constraint(hashreference, nodeidentifier)

returns the network constraint

=item * c(hash reference, node identifier a, node identifier b)

the portion of the network constraint on a by b.

=item * p(hash reference, node identifier a, node identifier b)

the portion of the value ab of the total weights of edges from a.

=item * flushCache()

clears an internal cache used to speed everything up.

=item * CTdi(hash reference, node identifier)

Coleman-Theil disorder index.  A measure of diversity of neighbor nodes.

=head1 AUTHOR

Erich S. Morisse, E<lt>emorisse@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Erich Morisse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
