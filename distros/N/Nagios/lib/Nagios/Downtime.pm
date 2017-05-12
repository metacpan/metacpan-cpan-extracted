package Nagios::Downtime;

use strict;
use warnings;
use Carp;

our $AUTOLOAD;
        
sub new {
        my $class = shift;
        my %hash = @_;
        my $self = {};
        bless $self, $class;

        map { $self->{$_} = $hash{$_};} keys %hash;
 
        return $self;
}
        
        
sub AUTOLOAD {
        my $self = shift;
        my $func_name = $AUTOLOAD;
        $func_name =~ s/.*://; #striping full name
        $self->{$func_name} = shift if @_;

        return $self->{$func_name};
}       
      
=head1 NAME

Nagios::Downtime - control downtime schedualing!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module lets you schedual and cancel downtime
for hosts and hostgroups.

usage:

	use Nagios::Downtime;

new object:

	my $dt = Nagios::Downtime->new(
		downtime_dat_file => '/usr/nagios_2.6/var/downtime.dat',
		nagios_cmd_file => '/usr/nagios_2.6/var/rw/nagios.cmd',
		nagios_hostgroups_file => '/etc/nagios/hostgroups.cfg'
	);

or:

	my $dt = new Nagios::Downtime;

	$dt->downtime_dat_file('/usr/nagios_2.6/var/downtime.dat');
	$dt->nagios_cmd_file('/usr/nagios_2.6/var/rw/nagios.cmd');
	$dt->nagios_hostgroups_file('/etc/nagios/hostgroups.cfg');


to schedual a single host 'web1' for 5 hours downtime with commnet 
'testing module' by author 'quatrix':

	$dt->start_host_downtime('web1',60 * 60 * 5,'quatrix','testing module');

same, but to schedual downtime for an entire host-group 'web-group':

	$dt->start_hostgroup_downtime('web-group',60 * 60 * 5, 'quatrix','testing module');

to cancel schedualed downtime for host 'web1':

	$dt->stop_host_downtime('web1');

to cancel schedualed downtime for entire host-group 'web-group':

	$dt->stop_hostgroup_downtime('web-group');


=head1 EXPORT

nothing is exported, you should use it OO style only.

=head1 FUNCTIONS

=head2 start_hostgroup_downtime(hostgroup_name,dt_long,author,comment)

takes 4 arguments: hostgroup_name, downtime time in seconds, author, comment

needs 'nagios_cmd_file' defined 

i.e:

	$dt->start_hostgroup_downtime('web-group',600,'quatrix','for kicks');

=cut

sub start_hostgroup_downtime {
        my $self = shift;
        if (my @missing = _missing($self,['nagios_cmd_file'])) { croak "missing object parameters: @missing"; }

        my ($hostgroup_name,$dt_long,$author,$comment) = grep { $#_ == 3 && $_ or croak 'usage: start_hostgroup_downtime(hostname,seconds,author,comment)' } @_;

        my $dt_start = time;
        my $dt_end = $dt_start + $dt_long;

        open my $CMD_FH, '>>', $self->{'nagios_cmd_file'} or "can't open $self->{'nagios_cmd_file'} for writing: $!";
        print $CMD_FH qq{[$dt_start] SCHEDULE_HOSTGROUP_SVC_DOWNTIME;$hostgroup_name;$dt_start;$dt_end;1;0;$dt_long;$author;$comment\n};
        print $CMD_FH qq{[$dt_start] SCHEDULE_HOSTGROUP_HOST_DOWNTIME;$hostgroup_name;$dt_start;$dt_end;1;0;$dt_long;$author;$comment\n};
        close $CMD_FH;

        return 1;
}


=head2 start_host_downtime(host_name,dt_long,author,comment)

same as before, but instade hostgroup_name, it takes host_name

also, needs 'nagios_cmd_file' defined

i.e: 

	$dt->start_host_downtime('web1',600,'quatrix','no one needs to know');

=cut

sub start_host_downtime {
        my $self = shift;
        if (my @missing = _missing($self,['nagios_cmd_file'])) { croak "missing object parameters: @missing"; }

        my ($host_name,$dt_long,$author,$comment) = grep { $#_ == 3 && $_ or croak 'usage: start_host_downtime(hostname,seconds,author,comment)' } @_;

        my $dt_start = time;
        my $dt_end = $dt_start + $dt_long;

        open my $CMD_FH, '>>', $self->{'nagios_cmd_file'} or "can't open $self->{'nagios_cmd_file'} for writing: $!";
        print $CMD_FH qq{[$dt_start] SCHEDULE_HOST_SVC_DOWNTIME;$host_name;$dt_start;$dt_end;1;0;$dt_long;$author;$comment\n};
        print $CMD_FH qq{[$dt_start] SCHEDULE_HOST_DOWNTIME;$host_name;$dt_start;$dt_end;1;0;$dt_long;$author;$comment\n};
        close $CMD_FH;

        return 1;
}

=head2 stop_hostgroup_downtime(hostgroup_name)
this function cancels schedualed downtime for a hostgroup
it takes just one argument, hostgroup_name.

needs 'nagios_cmd_file' 'nagios_hostgroups_file' and 'downtime_dat_file' defined

i.e:

	$dt->stop_hostgroup_downtime('web-group');

=cut


sub stop_hostgroup_downtime {
        my $self = shift;
        if (my @missing = _missing($self,['nagios_cmd_file','nagios_hostgroups_file','downtime_dat_file'])) { croak "missing object parameters: @missing";}

        my $hostgroup_name = shift or croak 'usage: stop_hostgroup_downtime(hostgroup_name)';

        my $time_now = time;
        open my $CMD_FH, '>>', $self->{'nagios_cmd_file'} or croak "can't open $self->{'nagios_cmd_file'} for writing: $!";
        map { map { print $CMD_FH qq{[$time_now] DEL_HOST_DOWNTIME;$_\n[$time_now] DEL_SVC_DOWNTIME;$_\n}; } _get_dt_ids($_,$self->{'downtime_dat_file'}); } _get_hostgroup_hosts($hostgroup_name,$self->{'nagios_hostgroups_file'});
        close $CMD_FH;

        return 1;
}

=head2 stop_host_downtime(host_name)
again, like before, but instade of hostgroup_name, it takes hostname

needs 'nagios_cmd_file' and 'downtime_dat_file' defined.

i.e:

	$dt->stop_host_downtime('web1');

=head1 AUTHOR

quatrix, C<< <evil.legacy AT gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-nagios-downtime at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Downtime>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Downtime

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Downtime>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Downtime>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Downtime>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Downtime>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 quatrix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub stop_host_downtime {
        my $self = shift;
        if (my @missing = _missing($self,['nagios_cmd_file','downtime_dat_file'])) { croak "missing object parameters: @missing"; }

        my $host_name = shift or croak 'usage: stop_host_downtime(host_name)';

        my $time_now = time;
        open my $CMD_FH, '>>', $self->{'nagios_cmd_file'} or croak "can't open $self->{'nagios_cmd_file'} for writing: $!";
        map { print $CMD_FH qq{[$time_now] DEL_HOST_DOWNTIME;$_\n[$time_now] DEL_SVC_DOWNTIME;$_\n}; } _get_dt_ids($host_name,$self->{'downtime_dat_file'});
        close $CMD_FH;

        return 1;
}

sub _missing {
        my ($self,$expected) = @_;
        my @missing = ();
        map { if (!$self->{$_}) { push @missing, $_; } } @{$expected};
        return @missing;
}


sub _get_hostgroup_hosts {
        my ($hostgroup_name,$nagios_hostgroups_file) = grep { $#_ == 1 && $_ or croak 'usage: _get_hostgroup_hosts(hostgrouop_name,nagios_hostgroups_file)' } @_;

        my @data = ();
        my @hosts = ();
        _parse_file(\@data, $nagios_hostgroups_file);

        #this finds the currect hostgroup, puts it's members into @host and removes trailing and leading whitespace
        map { if ($_->{'hostgroup_name'} eq $hostgroup_name) { @hosts = split /,/, $_->{'members'}; };  map { s/^\s+|\s$//g } @hosts;} @data;

        return @hosts;
}

sub _get_dt_ids {
        my ($host_name,$downtime_dat_file) = grep { $#_ == 1 && $_ or croak 'usage: _get_dt_ids(host_name,nagios_dat_file)' } @_;

        my @data = ();
        my @return_ids = ();
        _parse_file(\@data,$downtime_dat_file);

        #this gets the downtime ids for a specific host_name
        map { if ($_->{'host_name'} eq $host_name) { push @return_ids,  $_->{'downtime_id'};} } @data;

        return @return_ids;
}

sub _parse_file {
        my ($data_ref,$file_to_read) = grep { $#_ == 1 && $_ or croak 'usage: _parse_file(array_ref,file_to_parse)' } @_;

        my $index = 0;

        open my $DT_DAT_FH, '<', $file_to_read or croak "can't open $file_to_read for reading: $!";
        while (<$DT_DAT_FH>) {
                next if /^#/; #skip comments
                next if /{$/; #skip start of definition
                next if /^\s*$/; #skip empty lines
                if (/}$/) { $index++; next; } #when definition ends, increment array index
                $data_ref->[$index]->{$1} = $3 if /^\s*(.+?)(=|\s+)(.+)\s*$/; #insert stuff as a hash ref into an array ref
        }
        close $DT_DAT_FH;

        return 1;

}


1; # End of Nagios::Downtime
