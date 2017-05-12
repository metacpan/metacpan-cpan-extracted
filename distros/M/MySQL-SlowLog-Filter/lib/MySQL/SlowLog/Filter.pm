package MySQL::SlowLog::Filter;

use warnings;
use strict;

our $VERSION = '0.05';
our $AUTHORITY = 'cpan:FAYLAND';

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/ run parse_date_range parse_time /;

use Carp qw/croak/;
use Time::Local;
#use DBI;
use File::Slurp;
#use Data::Dumper;

our @default_sorting = (
	4,  'sum-query-time',
	2,  'avg-query-time',
	3,  'max-query-time',
	7,  'sum-lock-time',
	5,  'avg-lock-time',
	6,  'max-lock-time',
    13, 'sum-rows-examined',
    11, 'avg-rows-examined',
    12, 'max-rows-examined',
    1,  'execution-count',
    10, 'sum-rows-sent',
    8,  'avg-rows-sent',
    9,  'max-rows-sent'
 );

sub run {
	my $file = shift;
    my ( $params ) = ( scalar @_ == 1 ) ? shift : { @_ };
    
    # check date range
    my $date = $params->{date};
    my ( $date_first, $date_last ) = parse_date_range( $date );
    
    # check settings
    my $include_hosts = $params->{'include-host'} || $params->{ih} || [];
    my $exclude_hosts = $params->{'exclude-host'} || $params->{eh} || [];
    my $include_users = $params->{'include-user'} || $params->{iu} || [];
    my $exclude_users = $params->{'exclude-user'} || $params->{eu} || [];
    
    my $no_duplicates = $params->{no_duplicates} || 0;
    my $no_output     = $params->{no_output} || 0;
    my $incremental   = $params->{incremental} || 0;
    
    my $min_query_time    = $params->{min_query_time} || $params->{T} || -1;
    my $min_rows_examined = $params->{min_rows_examined} || $params->{R} || -1;
    
    my @lines = read_file( $file );
    
    if ( $incremental ) {
    	# TODO
    }
    
    my ( $query, $timestamp, $user, $host, $in_query );
    my @query_time;
    my %queries;
    foreach my $line ( @lines ) {
    	next unless $line;

    	if ( $line =~ /^\# / ) {
    		if ( $query ) {
				if ( $in_query ) {
					process_query( \%queries, $query, $no_duplicates, $user, $host,
								   $timestamp, \@query_time);
				}
				$query = '';
				$in_query = 0;
			}
    		
			if ( $line =~ /^\# T/ ) {  # # Time: 070119 12:29:58
				( $timestamp ) = ( $line =~ /(\d+(.*?))$/ );
				my $t = get_log_timestamp($timestamp);
				if ( $t < $date_first or $t > $date_last ) {
					$timestamp = 0;
				}
			} elsif ( $timestamp and $line =~ /^\# U/ ) {  # # User@Host: root[root] @ localhost []
				chomp($line);
				my $text = substr( $line, 13, length($line) - 13 );
				( $user, $host ) = split(' @ ', $text, 2);
				
				if (not scalar @$include_hosts) {
					$in_query = 1;
					foreach my $eh ( @$exclude_hosts ) {
						if ( $host =~ /$eh/ ) {
							$in_query = 0;
							last;
						}
					}
				} else {
					$in_query = 0;
					foreach my $ih ( @$include_hosts ) {
						if ( $host =~ /$ih/ ) {
							$in_query = 1;
							last;
						}
					}
				}
                next if ( not $in_query );
                
                if (not scalar @$include_users) {
                	$in_query = 1;
                	foreach my $eu ( @$exclude_users ) {
                		if ( $user =~ /$eu/ ) {
							$in_query = 0;
							last;
						}
					}
				} else {
					$in_query = 0;
					foreach my $iu ( @$include_users ) {
						if ( $user =~ /$iu/ ) {
							$in_query = 1;
							last;
						}
					}
				}
			} 
			# # Query_time: 0  Lock_time: 0  Rows_sent: 0  Rows_examined: 156
			elsif ( $in_query and $line =~ /^\# Q/ ) {
				my $text = substr( $line, 13, length($line) - 13 );
				my @numbers = split(':', $text);
				@query_time = ();
				foreach (@numbers) {
					push @query_time, $1 if (/(\d+)/);
				}
				$in_query = ( $query_time[0] >= $min_query_time or ($min_rows_examined and $query_time[3] >= $min_rows_examined) ) ? 1 : 0;
			} 
		} elsif ( $in_query ) {
			$query .= $line;
		}
    }
    
    if ( $query ) {
		process_query(\%queries, $query, $no_duplicates, $user, $host,
                      $timestamp, \@query_time);
    }

}

sub process_query {
	my ( $queries, $query, $no_duplicates, $user, $host, $timestamp, $query_time ) = @_;
	
	my $user_host = $user . ' @ ' . $host;
	if ( $no_duplicates ) {
        # TODO
    } else {
    	my $ls = ( $^O eq 'MSWin32' ) ? "\r\n" : 
				 ( $^O eq 'darwin'  ) ? "\r" : "\n";
        print sprintf("# Time: %s%s# User\@Host: %s%s# Query_time: %d  Lock_time: %d  Rows_sent: %d  Rows_examined: %d%s%s", $timestamp, $ls, $user_host, $ls, $query_time->[0], $query_time->[1], $query_time->[2], $query_time->[3], $ls, $query);
	}
}

sub parse_date_range {
    my $date = shift;
    
    my ( $start, $end ) = ( 0, 9999999999 );
    return ( $start, $end ) unless ( $date );
    
    my @parts = ( $date =~ /
    (                  # first date (don't match beginning of string)
    (?:\d{4}|\d{1,2})  # first part can be 1-2 or 4 digits long (DD, MM, YYYY)
    (?:[\.\-\/]?\d{1,2}[\.\-\/]?)? # middle part (1-2 digits), optionally separated
    (?:\d{4}|\d{1,2})? # end part (1-2, 4 digits), optionally separated
    )                  # end of first date
    (?:-(              # optional second date, separated by "-"
    (?:\d{4}|\d{1,2})  # first part can be 1-2 or 4 digits long (DD, MM, YYYY)
    (?:[\.\-\/]?\d{1,2})? # middle part (1-2 digits), optionally separated
    (?:[\.\-\/]?(?:\d{4}|\d{1,2}))? # end part (1-2, 4 digits), optionally separated
    ))?                # end of optional second date
    /x );

	@parts = grep { defined $_ } @parts;
    return ( $start, $end ) unless ( scalar @parts );
    
    # for >13.11.2006 <13.11.2006 -13.11.2006
    if ( $date =~ /^([\>\<\-])/ ) {
        if ( $1 eq '<' or $1 eq '-' ) {
            $end = parse_time( $parts[0] );
        } else {
            $start = parse_time( $parts[0] );
        }
    } elsif ( scalar @parts > 1 ) {
        $start = parse_time( $parts[0] );
        # for '13/11/2006-'
        $end   = parse_time( $parts[1] ) if ( $parts[1] ne '-' );
    } else {
    	$start = parse_time( $parts[0] );
    }
    
    return ( $start, $end );
}

sub parse_time {
    # Return a unix timestamp from the given date.
    my $date = shift;

    # for those '13.11.2006' '11/13/2006' '15-11-2006'
    my @parts = ( $date =~ /(\d+)/g );
    $parts[2] -= 1900;
    $parts[1] -= 1;

    my $r;
    eval {
        $r = timelocal(0, 0, 0, @parts);
    };
    croak "$date is not accepted\n" if ($@);
    return $r;
}

sub get_log_timestamp {
	my $date = shift;
	
	# 070119 12:29:58
	my ( $year, $month, $day, $hour, $min, $secs ) = (
		$date =~ /(\d\d)(\d\d)(\d\d)\s+(\d{1,2})\:(\d{1,2})\:(\d{1,2})/ );

	$year  += 100;
	$month -= 1;
	return timelocal($secs, $min, $hour, $day, $month, $year);
}

1;
__END__

=head1 NAME

MySQL::SlowLog::Filter - MySQL Slow Query Log Filter

=head1 SYNOPSIS

    use MySQL::SlowLog::Filter qw/run parse_date_range parse_time/;
	
    run('slow.log', {
    	date => '13.11.2006-01.12.2008', # see parse_date_range below
    	'include-host' => \@include_hosts,
    	'exclude-host' => \@exclude_hosts,
    	'include-user' => \@include_users,
    	'exclude-user' => \@exclude_users,
    	min_query_time => 30,
    } );

=head1 DESCRIPTION

The code is heavily borrowed from L<http://code.google.com/p/mysql-log-filter/>

It is B<not> complete, use it at your own risk.

=head1 METHODS

=head2 run( $file_name, $params )

run $params on $file_name

=head3 PARAMS

=over 4

=item date

	date => '13.11.2006-01.12.2008'
	date => '>13.11.2006'

check parse_date_range below

=item include-host

=item exclude-host

=item include-user

=item exclude-user

=item min_query_time

	# Query_time: 221  Lock_time: 0  Rows_sent: 241  Rows_examined: 4385615

compare with "Query_time". default is -1. means all.

=item min_rows_examined

compare with "Rows_examined". default is -1. means all.

=back

=head2 parse_date_range

    # time epoch
    my ( $start, $end ) = parse_date_range($Input);

    Input                   Return
    ''                    ( 0, 9999999999 )
    >13-11-2006           ( 1163347200, 9999999999 )
    <13/11/2006           ( 0, 1163347200 )
    -13.11.2006           ( 0, 1163347200 )
    13.11.2006-1.12.2008  ( 1163347200, 1228060800 )
    13.11.2006-01.12.2008 ( 1163347200, 1228060800 )
    13/11/2006-01-12-2008 ( 1163347200, 1228060800 )

=head2 parse_time

Return a unix timestamp from the given date.

=head2 get_log_timestamp

Return a unix timestamp from the given date. (070119 12:29:58)

=head1 TODO

=over 4

=item * incremental

=item * no-duplicates

=item * sorting

=back

=head1 SEE ALSO

L<http://mysql-log-filter.googlecode.com/svn/trunk/mysql_filter_slow_log.py>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
