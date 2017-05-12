#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.05';
our $AUTHORITY = 'cpan:FAYLAND';

use MySQL::SlowLog::Filter qw/run/;
use Getopt::Long;
use Pod::Usage;

my %params;

GetOptions(
	\%params,
	"help|?",
	"date=s",
	"T|min_query_time=i",
	"R|min_rows_examined=i",
	"ih|include-host=s",
	"eh|exclude-host=s",
	"iu|include-user=s",
	"eu|exclude-user=s",
	
) or pod2usage(2);

pod2usage(1) if $params{help};

my $file = pop @ARGV;
defined $file or pod2usage(1);
-e $file or die "$file is not found\n";

run($file, \%params);

__END__

=head1 NAME

mysql_showlog_filter - filter your mysql slow.log

=head1 SYNOPSIS

    mysql_showlog_filter [options] FILE

=head1 OPTIONS

=over 4

=item B<-?>, B<--help>

=item B<--date=I<DATE_RANGE>>

    >13-11-2006
    <13/11/2006
    -13.11.2006
    13.11.2006-1.12.2008
    13.11.2006-01.12.2008
    13/11/2006-01-12-2008

No time limited by default

=item B<-T>, B<--min_query_time>

-1 by default. compared with "Query_time"

  # Query_time: 221  Lock_time: 0  Rows_sent: 241  Rows_examined: 4385615

=item B<-R>, B<--min_rows_examined>

-1 by default. compared with "Rows_examined"

=item B<-ih>, B<--include-host=I<HOSTS>>

=item B<-eh>, B<--exclude-host=I<HOSTS>>

=item B<-iu>, B<--include-user=I<USERS>>

=item B<-eu>, B<--exclude-user=I<USERS>>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
