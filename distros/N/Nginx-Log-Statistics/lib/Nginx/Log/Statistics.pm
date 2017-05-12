package Nginx::Log::Statistics;
use Nginx::Log::Entry;
use Time::Piece;
use strict;
use warnings;

=head1 NAME

Nginx::Log::Statistics - This module parses the Nginx combined access log and provides summary statistics about the log data.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

There are only two methods to understand in order to use this module: new and get_stat. These methods are documented below.
    
    use Nginx::Log::Statistics;
    use Data::Dumper;

    my $stats = Nginx::Log::Statistics->new({filepath => '/etc/nginx/logs/access.log'});
    my $browser_stats = $stats->get_stat('browser_count');
    print Dumper $browser_stats;
    

=head1 SUBROUTINES/METHODS

=head2 new

Returns a new Nginx::Log::Statistics object. Requires a hashref with the following arguments (most are optional):

=over 3

=item * filepath      => path to the access.log file, e.g. '/etc/nginx/logs/access.log' (required).

=item * start_date    => a L<Time::Piece> object, entries in the log with a date earlier than this date will be ignored (optional).

=item * end_date      => a L<Time::Piece> object, entries in the log with a date later than this date will be ignored (optional).

=item * ignore_robots => either 1 or 0. If set to 1, all robot (e.g. Googlebot) entries in the log will be ignored, default is on (optional).

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        ignore_robots => $_[0]->{ignore_robots} || 1,
        despatch_table  => {
            entry_count             => \&_get_entries_count,
            unique_ip_count         => \&_get_unique_ip_count,
            unique_ip_browser_count => \&_get_unique_ip_browser_count,
            browser_count           => \&_get_browser_count,
            url_count               => \&_get_url_count,
            os_count                => \&_get_os_count,
            referer_count           => \&_get_referer_count,
            unique_ip_os_count      => \&_get_unique_ip_os_count,
        },
    };
    my $obj = bless $self, $class;
    my $log_arrayref = $obj->_build_log_array($_[0]->{filepath});
    $obj->{log} = $obj->_build_structure($log_arrayref, $_[0]->{start_date}, $_[0]->{end_date});
    return $obj;
}

=head2 get_stat

This method requires a string or scalar argument for one of the statistics options below. It returns a hashref of the statistics requested, or zero if the argument was not recognised. All successful return values include the statistics calculated per year, by day, week and month. Valid options are:

=over 3

=item * 'entry_count' - the number of log entries

=item * 'unique_ip_count - the number of unique ip addresses 

=item * 'browser_count' -  a hashref with internet browser software as keys and counts as values.

=item * 'unique_ip_browser_count' - same as browser_count except that the counts are unique combinations of ip and browser. This is reduces skew when comparing popularity of internet browsers as one user may make more page request than another, hence by controlling for ip address this issue is somewhat mitigated.

=item * 'url_count' - a hashref with urls as keys and counts as values.

=item * 'os_count' - a hashref with operating systems as keys and counts as values.

=item * 'unique_ip_os_count' - same as os_count except that the counts are unique combinations of ip and operating system. This is reduces skew when comparing popularity of operating systems as one user may make more page request than another, hence by controlling for ip address this issue is somewhat mitigated.

=item * 'referer_count' - a hashref with referer urls as keys and counts as values.

=back

=cut

sub get_stat {
    my ($self, $stat_key) = @_;
    return 0 unless exists $self->{despatch_table}->{$stat_key};
    my $stat_structure = {};
    my $stat_sub = $self->{despatch_table}->{$stat_key};
    foreach my $year (keys %{$self->{log}}){
        foreach my $month (keys %{$self->{log}->{$year}->{months}}){
            $stat_structure->{$year}->{months}->{$month} = $stat_sub->($self->{log}->{$year}->{months}->{$month});
        }
        foreach my $week (keys %{$self->{log}->{$year}->{weeks}}){
            $stat_structure->{$year}->{weeks}->{$week} = $stat_sub->($self->{log}->{$year}->{weeks}->{$week});
        }
        foreach my $day (keys %{$self->{log}->{$year}->{days}}){
            $stat_structure->{$year}->{days}->{$day} = $stat_sub->($self->{log}->{$year}->{days}->{$day});
        }
    }
    return $stat_structure;
}

sub _get_entries_count {
    my $arrayref = shift;
    return @{$arrayref};
}

sub _get_unique_ip_count {
    my $arrayref = shift;
    my %entry_ips;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $entry_ips{$entry->get_ip} = 1;
        }
    }
    return scalar keys %entry_ips; 
}

sub _get_unique_ip_browser_count {
    my $arrayref = shift;
    my %browsers_ips;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $browsers_ips{$entry->get_browser}->{$entry->get_ip} = 1;
        }
    }
    my %unique_browser_counts;
    foreach my $browser (keys %browsers_ips) {
        $unique_browser_counts{$browser} = scalar keys %{$browsers_ips{$browser}};
    }
    return \%unique_browser_counts; 
}

sub _get_browser_count {
    my $arrayref = shift;
    my %browsers;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $browsers{$entry->get_browser}++;
        }
    }
    return \%browsers; 
}

sub _get_os_count {
    my $arrayref = shift;
    my %os;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $os{$entry->get_os}++;
        }
    }
    return \%os; 
}

sub _get_url_count {
    my $arrayref = shift;
    my %urls;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $urls{$entry->get_request_url}++;
        }
    }
    return \%urls; 
}

sub _get_referer_count {
    my $arrayref = shift;
    my %referers;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $referers{$entry->get_referer}++;
        }
    }
    return \%referers; 
}

sub _get_unique_ip_os_count {
    my $arrayref = shift;
    my %os_ips;
    foreach my $entry (@{$arrayref}) {
        if ($entry->get_request_url){
            $os_ips{$entry->get_os}->{$entry->get_ip} = 1;
        }
    }
    my %unique_os_counts;
    foreach my $os (keys %os_ips) {
        $unique_os_counts{$os} = scalar keys %{$os_ips{$os}};
    }
    return \%unique_os_counts; 
}

=head1 INTERNAL METHODS

=head2 _build_log_array

This internal method returns an array of L<Nging::Log::Entry> objects. It requires the filepath to the log as an argument.  

=cut

sub _build_log_array {
    my ($self, $filepath) = @_;
    open (my $fh, '<', $filepath) or die $!;
    my @log = ();
    while (<$fh>) {
        push @log, Nginx::Log::Entry->new($_);
    }
    return \@log;
}

=head2 _build_structure

This method builds the core hashref structure that is the input to the statistical calculations.

=cut

sub _build_structure {
    my ($self, $log, $start_date, $end_date) = @_;
    my $structure = {};
    foreach my $entry (@{$log}){
        if ($entry->was_robot and $self->{ignore_robots}) {
            next;
        }
        elsif ($start_date and $end_date) {     
            next if ($entry->get_datetime_obj < $start_date
            or $entry->get_datetime_obj > $end_date);
        }
        my $year = $entry->get_datetime_obj->yy;
        my $month= $entry->get_datetime_obj->mon;
        my $week = $entry->get_datetime_obj->week;
        my $day  = $entry->get_datetime_obj->day_of_year;
        push @{$structure->{$year}->{months}->{$month}}, $entry;
        push @{$structure->{$year}->{weeks}->{$week}}, $entry;
        push @{$structure->{$year}->{days}->{$day}}, $entry;
    }
    return $structure;
}

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>, L<perltricks.com|http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nginx-log-statistics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nginx-Log-Statistics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nginx::Log::Statistics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nginx-Log-Statistics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nginx-Log-Statistics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nginx-Log-Statistics>

=item * Search CPAN

L<http://search.cpan.org/dist/Nginx-Log-Statistics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Nginx::Log::Statistics
