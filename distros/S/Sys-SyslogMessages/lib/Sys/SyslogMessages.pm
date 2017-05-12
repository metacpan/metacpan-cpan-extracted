package Sys::SyslogMessages;

use DateTime;

our $VERSION = '0.02';
our $DEBUG=0;

my %logger_types = ( 'syslog'   => '/var/run/syslogd.pid',
                     'syslogng' => '/var/run/syslog-ng.pid'
                   ); 

sub new{
    my $package = shift;
    my $options = shift;
    my $self = {};
    bless $self, $package;
    foreach my $option (keys %{$options}){
        $self->{$option} = $options->{$option};
    }
    $self->_check_logger();
    $self->{'number_lines'} = 50;
    $self->{'number_days'} = 0;
    $self->{'number_hours'} = 0;
    $self->{'number_minutes'} = 0;
    $self->{'time_zone'} = 'America/Los_Angeles';
    return $self;
}


sub tail {
    my $self = shift;
    my $options = shift;
    foreach my $option (keys %{$options}){
	$self->{$option} = $options->{$option};
    }
    $self->_parse_config();
    return 1 if ( $self->tail_by_time_diff() ); 
    if ( $self->{'output_file'} && $self->{'number_lines'} ){
        system("tail -n$self->{'number_lines'} $self->{'syslog_file'} > $self->{'output_file'}");
    } else {
        system("tail -n$self->{'number_lines'} $self->{'syslog_file'}");
    }
    if ( $? == 0 ){
        return 1;
    }
}

sub tail_by_time_diff{
    my $self = shift;
    my $time_diff = DateTime::Duration->new( days    => $self->{'number_days'}, 
                                             hours   => $self->{'number_hours'}, 
                                             minutes => $self->{'number_minutes'},
					     );
    return 0 if $time_diff->is_zero();
    return 0 if $time_diff->is_negative();
    my $start_time = DateTime->now(time_zone =>  $self->{'time_zone'});
    $start_time -= $time_diff;
    if ($self->{'output_file'}){
        open OF, ">$self->{'output_file'}";
    }
    open SLF, "<$self->{'syslog_file'}";
    my $mon = $start_time->month_abbr();
    while (<SLF>){
        #^Feb 20 13:00:01,  no year so harder to compare
	#Also a problem if log over 1 year old
        next unless  $_ =~ m/^$mon.*/;
        my ( $day, $hours, $min ) = $_ =~ m/^\w{3}\s{1,2}(\d{1,2}) (\d{2}):(\d{2})/;
	if ($DEBUG){
	    print $start_time->day();
	    print $start_time->hour();
	    print $start_time->minute();
	    print "\n";
	}
        next unless $day >= eval{$start_time->day()}; 
	if ( $day == $start_time->day() ){
            next unless $hours >= eval{$start_time->hour()}; 
	    if ( $hours == eval{$start_time->hour()}){
                next unless ( $min >= $start_time->minute() );
	    }
	}
	if ($self->{'output_file'}){
            print OF $_;
        } else {
            print $_;
	}
        last;
    }    
    if ($self->{'output_file'}){
        while (<SLF>){ print OF $_; }
    } else {
        while (<SLF>){ print $_; }
    } 
    close SLF;
    if ($self->{'output_file'}){ close OF; }
    return 1;
}


sub copy {
    my $self = shift;
    my $options = shift;
    $self->_parse_config();
    foreach my $option (keys %{$options}){
	$self->{$option} = $options->{$option};
    }
    unless ($self->{'output_file'}) {$self->{'output_file'} = 'syslog.txt';}
    system("cp $self->{'syslog_file'} $self->{'output_file'}");
    if ( $? == 0 ){
        return 1;
    }
}

sub _check_logger{
    my $self = shift;
    foreach $key (keys %logger_types){
        if ( -e $logger_types{$key}){
            my $pkg = 'Sys::SyslogMessages::' . $key;
            bless $self, $pkg; 
            $self->{ 'logger' } = $key;
            return;
        }
    }
    die "Cannot determine which syslogger is running.\n";
}


package Sys::SyslogMessages::syslog;
use base Sys::SyslogMessages;

sub _parse_config{
     my $self = shift;
     $self->{'syslog_config'} = '/etc/syslog.conf';
     open FH, $self->{'syslog_config'};
     while (<FH>){
         next if $_ =~ m/^#/;
         next if $_ =~ m/^\n$/;
         chomp $_;
         if ($_ =~ m/\*\.(\*|info)/){
	     ($self->{'syslog_file'}) = $_ =~ m/\*\.(?:\*|info).*\s+\-?(\/.*)/;
	     close FH;
             return;
         }

     }
     close FH;
}




package Sys::SyslogMessages::syslogng;
use base Sys::SyslogMessages;

sub _parse_config{
     my $self = shift;
     $self->{'syslog_config'} = '/etc/syslog-ng/syslog-ng.conf';
     open FH, $self->{'syslog_config'};
     while (<FH>){
         next if $_ =~ m/^#/;
         next if $_ =~ m/^\n$/;
         chomp $_;
         if ($_ =~ m/destination\s+messages.*file/){
             ($self->{'syslog_file'}) = $_ =~ m/destination\s+messages.*file\(\s*(?:\'|\")(.*)(?:\'|\")/;
         }
     }
     close FH;
}

1;

__END__


=head1 NAME

Sys::SyslogMessages - Figure out where syslog is and copy or tail it.(on Linux)

=head1 SYNOPSIS

    use Sys::SyslogMessages;

    $linux = new Sys::SyslogMessages({'output_file' => 'syslog.tail'});
    $linux->tail({'number_lines' => '500'});
    $linux->tail({'number_days' => '1', 'output_file' => 'syslog.hr.tail'});
    $linux->copy({'output_file' => 'syslog.log'});

=head1 DESCRIPTION
	
This is a simple module that finds the system logfile on Linux is and can copy 
it or tail it to a file.  It works for syslogd or syslog-ng. The syslog 
configuration must be in the standard locations.

The method 'tail' now has more options: number_lines, number_minutes, number_hours, 
number_days.  (and of course 'output_file')  The time designations are specified 
if the user wishes to tail a specific time interval backwards from 'now'.  One 
issue with this feature is that it will collect too much information if the log 
contains more than one year of data, as there are no years specified in the log.

=head1 DEPENDENCIES

This module depends on module DateTime.

=head1 TODO

Be able to save various categories of logs, i.e. kern.* mail.*.
Add copy dmsg support.
Tail syslog from a particular time or since last reboot.
Check for any other sys-logger options besides syslogd or syslog-ng.

=head1 AUTHORS

Judith Lebzelter, E<lt>judith@osdl.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

