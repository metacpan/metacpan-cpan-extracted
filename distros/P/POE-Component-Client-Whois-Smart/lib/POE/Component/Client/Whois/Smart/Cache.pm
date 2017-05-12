#
#===============================================================================
#
#         FILE:  Cache.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  14.07.2009 03:52:32 MSD
#     REVISION:  ---
#===============================================================================

package POE::Component::Client::Whois::Smart::Cache;

use strict;
use warnings;

use Data::Dumper;
use Net::Whois::Raw::Common;

sub initialize {
#    die "fuck";
    1;
}

sub query_order {
    0;
}

sub query {
    my $class = shift;
    my $query_list = shift;
    my $heap = shift;
    my $args_ref = shift;

    my @my_queries;

    @$query_list = grep 
	{ ! _check_from_cache( $_, $heap, $args_ref ) } @$query_list;

}

sub _check_from_cache {
    my ($q, $heap, $args_ref) = @_;

    my $result = Net::Whois::Raw::Common::get_from_cache(
	$q,
	$heap->{params}->{ cache_dir  },
	$heap->{params}->{ cache_time },
    );

    return unless $result;

    #warn Dumper $result;

    my $request = { %$args_ref };

    my @res;
    foreach (@$result) {
	$_->{server} = delete $_->{srv };
	$_->{whois } = delete $_->{text};

	my (undef, $error) = 
	    Net::Whois::Raw::Common::process_whois(
		$q,
		$_->{server},
		$_->{whois},
		1
	    );

	$_->{error} = $error if $error;

	push @res, $_;
    }

    $request->{cache     } = \@res;
    $request->{from_cache} = 1;

    $heap->{result}->{ $q } = \@res;

    return 1;
}


sub _on_done_order {
    10;
}

sub _on_done {
    my $class	= shift;
    my $heap	= shift;

    foreach my $query (keys %{$heap->{result}}) {            

	my $num = $heap->{params}->{referral} == 0 ? 0 : -1;

	my $result = $heap->{result}{ $query }->[ $num ];

	#warn $query;

	if (    $heap->{params}->{cache_dir}
	    &&  !$result->{from_cache}
	    &&   ($result->{server} || '') ne 'directi') {
	    Net::Whois::Raw::Common::write_to_cache(
		$query,
		$heap->{result}->{$query},
		$heap->{params}->{cache_dir}
	    );
	}
    }
}

1;

