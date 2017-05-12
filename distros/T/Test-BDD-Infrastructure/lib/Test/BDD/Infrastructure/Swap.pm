package Test::BDD::Infrastructure::Swap;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for checking swap usage
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval);


use File::Slurp;

sub check_swap_ok {
	my $path = '/proc/swaps';
	if( ! -f $path ) {
		fail("$path does not exist. (not on linux?)");
		return;
	}
	my @lines = read_file( $path );
	shift @lines; # remove header
	my @swaps;

	foreach my $line (@lines) {
		my $stats = {};
		@$stats{'device', 'type', 'size', 'used space', 'priority'}
			= split(/\s+/, $line);
		$stats->{'size'} *= 1024;
		$stats->{'used space'} *= 1024;
		$stats->{'free space'} = $stats->{'size'} - $stats->{'used space'};
		$stats->{'usage'} = $stats->{'used space'} / $stats->{'size'};
		push( @swaps, $stats );
	}

	return( \@swaps );
}

Given qr/^swap is configured$/, sub {
	S->{'swap'} = check_swap_ok;
};

Then qr/there must be $CMP_OPERATOR_RE (\d+) swaps? (?:spaces? )?configured/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	cmp_ok( scalar @{S->{'swap'}}, $op, $count, "there must be $op $count swaps configure");
};

sub calc_total_swap_stats {
	my $swaps = shift;
	my $total = {};
	@$total{'size', 'used space', 'free space'} = (0,0,0,0);
	foreach my $swap ( @$swaps ) {
		foreach my $field ('size', 'used space', 'free space') {
			$total->{$field} += $swap->{$field};
		}
	}
	$total->{'usage'} = $total->{'used space'} / $total->{'size'};
	return $total;
}

Then qr/the swaps? (size|used space|free space|usage) must be $CMP_OPERATOR_RE (\d+) (\S+)?/, sub {
	my $key = $1;
	my $op = convert_cmp_operator( $2 );
	my $count = $3;
	if( defined $4 ) {
	  $count = convert_unit( $3, $4 );
  	}
	my $total = calc_total_swap_stats( S->{'swap'} );
	cmp_ok( $total->{$key}, $op, $count, "the filesystems $key $op $count");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Swap - cucumber step definitions for checking swap usage

=head1 VERSION

version 1.005

=head1 Description

This step definitions check linux swap usage.

=head1 Synopsis

  Scenario: Swap space must be present
    Given swap is configured
    Then there must be at least 1 swap space configured
    And the swap size must be at least 1 gigabyte
    And the swap usage must be less than 50 percent

=head1 Step definitions

Start with:

  Given swap is configured

Followed by conditions:

  Then there must be <compare> <count> swap(s) (spaces) configured
  Then the swap(s) (size|used space|free space|usage) must be <compare> <count> <unit>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
