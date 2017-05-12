package NKTI::general;

use strict;
use warnings;
use Data::Dumper;
use DateTime;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export.
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NKTI::general ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( cetak cetak_r cetak_pre ) ]);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(cetak cetak_r cetak_pre);

# Define Version :
# ---------------------------------------------------------------- 
our $VERSION = '0.13';

# Create Subroutine for Get OS Server Information :
# ------------------------------------------------------------------------
sub os_server_info {
    # ----------------------------------------------------------------
    # Prepare to get Operating System Information :
    # ----------------------------------------------------------------
    my $server_signature = lc $ENV{'SERVER_SIGNATURE'};
    # ----------------------------------------------------------------
    # Scalar for placing result :
    # ----------------------------------------------------------------
    my $data = undef;
    # ----------------------------------------------------------------
    # Check IF $server_signature match "Win32" :
    # ----------------------------------------------------------------
    if ($server_signature =~ m/win32/) {
        $data = 'mswin';
    }
    
    # Check IF $server_signature match "unix" :
    # ----------------------------------------------------------------
    elsif ($server_signature =~ m/unix|debian|ubuntu|centos/) {
        $data = 'unix';
    }
    
    # Check IF $server_signature match unknown :
    # ----------------------------------------------------------------
    else {
        $data = 'other';
    }
    
    # Return Result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Create Subroutine for Get OS Server Information
# ===========================================================================================================

# Create Subroutine for get OS Client Information :
# ------------------------------------------------------------------------
sub os_info {
    
    # Define self :
    # ----------------------------------------------------------------
    my $self = shift; 
    
    # Using Modules :
    # ----------------------------------------------------------------
    my $check_modules = $self->try_module('HTTP::BrowserDetect');
    unless ($check_modules) {
        use HTTP::BrowserDetect;
    }
    
    # Prepare to get OS Client Information :
    # ----------------------------------------------------------------
    my $user_agent = $ENV{'HTTP_USER_AGENT'};
    my $ua = HTTP::BrowserDetect->new($user_agent);
    
    # Scalar for placing result :
    # ----------------------------------------------------------------
    my $data = '';
    
    # Check IF $ua->os_string is true :
    # ----------------------------------------------------------------
    if ($ua->os_string) {
        $data .= lc $ua->os_string;
    }
    # End of check IF $ua->os_string is true.
    # =================================================================
    
    # Check IF $ua->os_string is false :
    # ----------------------------------------------------------------
    else {
        $data .= 'unknown';
    }
    # End of check IF $ua->os_string is false.
    # =================================================================
    
    # Return Result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Create Subroutine for get OS Client Information
# ===========================================================================================================

# Create Subroutine for Get Browser Information :
# ------------------------------------------------------------------------
sub browser_info {
    
    # Prepare to get Browser Information :
    # ----------------------------------------------------------------
    my $browser = $ENV{'HTTP_USER_AGENT'};
    my $ua = HTTP::BrowserDetect->new($browser);
    
    # Scalar for placing result :
    # ----------------------------------------------------------------
    my $data = '';
    
    # Check IF $ua->browser_string is true :
    # ----------------------------------------------------------------
    if ($ua->browser_string) {
        $data .= lc $ua->browser_string;
    }
    # End of check IF $ua->browser_string is true.
    # =================================================================
    
    # Check IF $ua->browser_string is false :
    # ----------------------------------------------------------------
    else {
        $data .= 'unknown';
    }
    # End of check IF $ua->browser_string is false.
    # =================================================================
    
    # Return Data :
    # ----------------------------------------------------------------
    return $data;
}
# End of Create Subroutine for Get Browser Information
# ===========================================================================================================

# Create Subroutine for Delimiter Directory :
# ------------------------------------------------------------------------
sub delimiter_dir {
    
    # Run Subroutine "os_server_info()" :
    # ----------------------------------------------------------------
    my $self = shift;
    my $os_information = $self->os_server_info();
    
    # Scalar for placing result :
    # ----------------------------------------------------------------
    my $data = '';
    
    # Switch for conditions $os_information :
    # ----------------------------------------------------------------
    if ($os_information == 'mswin') {
        $data = '\\';
    } elsif ($os_information == 'unix') {
        $data = '/';
    } elsif ($os_information == 'other') {
        $data = '/';
    } else {
        $data = '/';
    }
    # End of switch for conditions $os_information.
    # ================================================================
    
    # Return Result :
    # ----------------------------------------------------------------
    return $data; 
}
# End of Create Subroutine for Delimiter Directory
# ===========================================================================================================

# Create Subroutine for get database config :
# ------------------------------------------------------------------------
sub get_dbconfig_php {
    
    # Define arguments subroutine :
    # ----------------------------------------------------------------
    my ($self, $dirloc, $file_loc) = @_;
    
    # Using Modules :
    # ----------------------------------------------------------------
    my $check_modules = $self->try_module('NKTI::general::file::read');
    unless ($check_modules) {
        use NKTI::general::file::read;
    }
    
    # Define scalar for location file Database Config :
    # ----------------------------------------------------------------
    my $file_dbconfig = $dirloc . $file_loc;
    
    # Run subroutine for get database config :
    # ----------------------------------------------------------------
    my $get_dbconfig = NKTI::general::file::read->new($file_dbconfig, 'dbconf');
    
    # Return Result :
    # ----------------------------------------------------------------
    return $get_dbconfig; 
}
# End of Create Subroutine for get database config
# ===========================================================================================================

# Subroutine for get protocols :
# ------------------------------------------------------------------------
sub get_protocol {
    
    # Prepare to get Protocol used :
    # ----------------------------------------------------------------
    #my $get_protocol = (defined $ENV{'HTTPS'} || $ENV{'SERVER_PORT'} == '443') ? "https:" : "http:";
    my $get_protocol = undef;
    if (defined  $ENV{'HTTPS'} || $ENV{'SERVER_PORT'} == '443') {
        $get_protocol = 'https:';
    } else {
        $get_protocol = 'http:';
    }
    
    # Return Result :
    # ----------------------------------------------------------------
    return $get_protocol; 
}
# End of Subroutine for get protocols.
# ===========================================================================================================

# Subroutine for check IF module is exists :
# ------------------------------------------------------------------------
sub try_module {
    
    # Define parameter module :
    # ----------------------------------------------------------------
    my ($self, $module_name) = @_;
    
    eval("use $module_name");
    
    # Check IF eval is true :
    # Jika module belum diload.
    # ----------------------------------------------------------------
    if ($@) {
        #print "\$@ = $@\n";
        return(0);
    }
    
    # Check IF eval is false :
    # Jika module Telah diload.
    # ----------------------------------------------------------------
    else {
        return(1);
    }
}
# End of Subroutine for check IF module is exists
# ===========================================================================================================

# Subroutine for define time for Event MySQL :
# ------------------------------------------------------------------------
sub time_event_mysql {
    # ----------------------------------------------------------------
    # Define parameter Subroutine :
    # ----------------------------------------------------------------
    my ($self, $time_event) = @_;
    # ----------------------------------------------------------------
    # Define scalar for place result :
    # ----------------------------------------------------------------
    my %data = ();
    my $get_num = undef;
    
    # For $time_event =~ /Y/ :
    # --------------------------------------------------------------------
    if ($time_event =~ m/Y/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' YEAR)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'YEAR';
    }
    # End of For $time_event =~ /Y/.
    # ====================================================================
    
    # For $time_event =~ /M/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/M/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' MONTH)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'MONTH';
    }
    # End of for $time_event =~ /M/.
    # ====================================================================
    
    # For $time_event =~ /W/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/W/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' WEEK)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'WEEK';
    }
    # End of for $time_event =~ /W/.
    # ====================================================================
    
    # For $time_event =~ /D/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/D/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' DAY)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'DAY';
    }
    # End of For $time_event =~ /D/.
    # ====================================================================
    
    # For $time_event =~ /H/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/H/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' HOUR)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'HOUR';
    }
    # End of For $time_event =~ /H/.
    # ====================================================================
    
    # For $time_event =~ /m/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/m/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' MINUTES)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'MINUTES';
    }
    # End of For $time_event =~ /m/.
    # ====================================================================
    
    # For $time_event =~ /d/ :
    # --------------------------------------------------------------------
    elsif ($time_event =~ m/d/) {
        $get_num = $time_event =~ s/\D//g;
        $data{'event'} = '(CURRENT_TIMESTAMP + INTERVAL '.$get_num.' SECOND)';
        $data{'time'} = $time_event;
        $data{'unit'} = 'SECOND';
    }
    # End of For $time_event =~ /d/.
    # ====================================================================
    
    # Default Case :
    # --------------------------------------------------------------------
    else {
        $data{'event'} = 'CURRENT_TIMESTAMP';
        $data{'time'} = '';
        $data{'unit'} = '';
    }
    # End of case $time_event == /d/.
    # ====================================================================
    
    # Return Result :
    # ----------------------------------------------------------------
    return \%data; 
}
# End of Subroutine for define time for Event MySQL
# ===========================================================================================================

# Subroutine for Define format DATETIME MySQL :
# ------------------------------------------------------------------------
sub datetime_mysql {
    # ----------------------------------------------------------------
    # Define parameter subroutine :
    # ----------------------------------------------------------------
    my ($self, $timestamp, $timezone) = @_;
    # ----------------------------------------------------------------
    # Define scalar for place result :
    # ----------------------------------------------------------------
    my $data = undef;
    # ----------------------------------------------------------------
    # Set DateTime and TimeZone :
    # ----------------------------------------------------------------
    my $dt = DateTime->from_epoch(
        epoch     => $timestamp,
        time_zone => $timezone
    );
    # ----------------------------------------------------------------
    # Get DateTime Format :
    # ----------------------------------------------------------------
    my $date_define = $dt->ymd;
    my $time_define = $dt->hms;
    # ----------------------------------------------------------------
    # Place date reuslt :
    # ----------------------------------------------------------------
    $data = $date_define.' '.$time_define;
    # ----------------------------------------------------------------
    # Return result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Subroutine for Define format DATETIME MySQL
# ===========================================================================================================

# Subroutine for Print data with newline :
# ------------------------------------------------------------------------
sub cetak {
	# ----------------------------------------------------------------
	# Define parameter subroutine :
	# ----------------------------------------------------------------
	my ($data) = @_;
    # ----------------------------------------------------------------
    # Print Data :
    # ----------------------------------------------------------------
    print "$data \n";
}
# End of Subroutine for Print data with newline
# ===========================================================================================================

# Subroutine for Print ref :
# ------------------------------------------------------------------------
sub cetak_r {
    # ----------------------------------------------------------------
    # Check Parameter Subroutine :
    # ----------------------------------------------------------------
    if (keys(@_) eq 1) {
        # ----------------------------------------------------------------
        # Print Dumper :
        # ----------------------------------------------------------------
        print Dumper $_[0];
    }
    if (keys(@_) > 1) {
        # ----------------------------------------------------------------
        # Print Dumper :
        # ----------------------------------------------------------------
        print Dumper \@_;
    }
}
# End of Subroutine for Print ref.
# ===========================================================================================================

# Subroutine for print ref with pre tag HTML :
# ------------------------------------------------------------------------
sub cetak_pre {
    # ----------------------------------------------------------------
    # Check Parameter Subroutine :
    # ----------------------------------------------------------------
    if (keys(@_) eq 1) {
        # ----------------------------------------------------------------
        # Print Dumper :
        # ----------------------------------------------------------------
        print "<pre>";
        print Dumper $_[0];
        print "</pre>";
    }
    if (keys(@_) > 1) {
        # ----------------------------------------------------------------
        # Print Dumper :
        # ----------------------------------------------------------------
        print Dumper \@_;
    }
}
# End of Subroutine for print ref with pre tag HTML
# ===========================================================================================================
1;
__END__
#