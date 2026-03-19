package NBI::Opts;
#ABSTRACT: A class for representing a the SLURM options for NBI::Slurm
#
# NBI::Opts - Stores and validates SLURM resource options for a job.
#
# DESCRIPTION:
#   Holds every resource knob that ends up as a #SBATCH directive in the
#   job script.  Key responsibilities:
#     - new()           : accepts -queue, -threads, -memory, -time, -tmpdir,
#                         -email_address, -email_type, -opts (extra directives),
#                         -files (enables array-job mode), -placeholder
#     - header()        : generates the full #!/bin/bash + #SBATCH header block
#                         consumed by NBI::Job->script()
#     - timestring()    : converts internal hours to SLURM "D-HH:MM:SS" format
#     - is_array()      : returns true when a -files list is present
#     - add_option()    : appends a raw #SBATCH option string
#     - view()          : returns a human-readable summary string
#   Internal helpers:
#     - _mem_parse_mb()    : normalises memory values (KB/MB/GB/TB) to MB
#     - _time_to_hour()    : normalises time strings (e.g. "2h30m", "1d") to hours
#     - _parse_start_time(): validates/normalises HH:MM[:SS] → "HH:MM:SS"
#     - _parse_start_date(): validates/normalises DD/MM[/YYYY] → "YYYY-MM-DD",
#                            inferring year when omitted
#     - _compute_begin()   : combines start_time + start_date with date-inference
#                            logic and returns the SLURM "--begin" value string
#
# RELATIONSHIPS:
#   - Composed into NBI::Job via the -opts constructor argument or set_opts().
#   - NBI::Job calls $self->opts->header() and reads tmpdir, placeholder,
#     files, and is_array() to build the sbatch script.
#   - $NBI::Opts::VERSION is set from $NBI::Slurm::VERSION (loaded by caller).
#

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use POSIX qw(mktime strftime);

$NBI::Opts::VERSION           = $NBI::Slurm::VERSION;

my $SYSTEM_TEMPDIR = $ENV{'TMPDIR'} || $ENV{'TEMP'} || "/tmp";
require Exporter;
our @ISA = qw(Exporter);

sub _yell {
    use Term::ANSIColor;
    my $msg = shift @_;
    my $col = shift @_ || "bold green";
    say STDERR color($col), "[NBI::Opts]", color("reset"), " $msg";
}
sub new {
    my $class = shift @_;
    my ($queue, $memory, $threads, $opts_array, $tmpdir, $hours, $email_address, $email_when, $files, $placeholder, $start_time, $start_date) = (undef) x 12;
    
    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        
        my %data = @_;

        # Try parsing
        for my $i (keys %data) {
            
            # QUEUE
            if ($i =~ /^-queue/) {
                next unless (defined $data{$i});
                $queue = $data{$i};
                

            # THREADS
            } elsif ($i =~ /^-threads/) {
                next unless (defined $data{$i});
                # Check it's an integer 
                if ($data{$i} =~ /^\d+$/) {
                    $threads = $data{$i};
                } else {
                    confess "ERROR NBI::Seq: -threads expects an integer\n";
                }
                
                
            # MEMORY
            } elsif ($i =~ /^-memory/) {
                next unless (defined $data{$i});
                $memory = _mem_parse_mb($data{$i});
               

            # TMPDIR
            } elsif ($i =~ /^-tmpdir/) {
                next unless (defined $data{$i});
                $tmpdir = $data{$i};
               
            # MAIL ADDRESS
            } elsif ($i =~ /^-(mail|email_address)/) {
                next unless (defined $data{$i});
                $email_address = $data{$i};
                
            # WHEN MAIL
            } elsif ($i =~ /^-(when|email_type)/) {
                next unless (defined $data{$i});
                $email_when = $data{$i};
                

            # OPTS ARRAY
            } elsif ($i =~ /^-opts/) {
                next unless (defined $data{$i});
                # in this case we expect an array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -opts expects an array\n";
                }
                $opts_array = $data{$i};
                

            # TIME
            } elsif ($i =~ /^-time/) {
                $hours = _time_to_hour($data{$i});
                
            # PLACEHOLDER
            } elsif ($i =~ /^-placeholder/) {
                # check if placeholder contains special regex characters
                if (not defined $data{$i}) {
                    confess "ERROR NBI::Seq: Placeholder cannot be empty\n";
                }
                if ($data{$i} =~ /[\*\+\?]/) {
                    confess "ERROR NBI::Seq: Placeholder cannot contain special regex characters\n";
                }
                $placeholder = $data{$i};
                
            # ARRAY
            } elsif ($i =~ /^-files/) {
                # expects ref to array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -files expects an array\n";
                } else {
                    $files = $data{$i};
                }
                
            # START TIME
            } elsif ($i =~ /^-start_time/) {
                next unless defined $data{$i};
                $start_time = _parse_start_time($data{$i});

            # START DATE
            } elsif ($i =~ /^-start_date/) {
                next unless defined $data{$i};
                $start_date = _parse_start_date($data{$i});

            } else {
                confess "ERROR NBI::Seq: Unknown parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    
    # Set attributes
    $self->queue = defined $queue ? $queue : "nbi-short";
    $self->threads = defined $threads ? $threads : 1;
    $self->memory = defined $memory ? $memory : 100;
    $self->hours = defined $hours ? $hours : 1;
    $self->tmpdir = defined $tmpdir ? $tmpdir : $SYSTEM_TEMPDIR;
    $self->email_address = defined $email_address ? $email_address : undef;
    $self->email_type = defined $email_when ? $email_when : "none";
    $self->files = defined $files ? $files : [];
    $self->placeholder = defined $placeholder ?  $placeholder : "#FILE#";
    # Set options
    $self->opts = defined $$opts_array[0] ? $opts_array : [];
    # Begin time (optional)
    $self->{start_time} = $start_time;
    $self->{start_date} = $start_date;
    
    
    
    

    return $self;
 
}


sub queue : lvalue {
    # Update queue
    my ($self, $new_val) = @_;
    $self->{queue} = $new_val if (defined $new_val);
    return $self->{queue};
}

sub threads : lvalue {
    # Update threads
    my ($self, $new_val) = @_;
    $self->{threads} = $new_val if (defined $new_val);
    return $self->{threads};
}

sub memory : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{memory} = _mem_parse_mb($new_val) if (defined $new_val);
    return $self->{memory};
}

sub email_address : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_address} = $new_val if (defined $new_val);
    return $self->{email_address};
}

sub email_type : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_type} = $new_val if (defined $new_val);
    return $self->{email_type};
}

# property files (list of files)
sub files : lvalue {
    # Update files
    my ($self, $new_val) = @_;
    $self->{files} = $new_val if (defined $new_val);
    return $self->{files};
}

sub placeholder : lvalue {
    # Update placeholder
    my ($self, $new_val) = @_;
    $self->{placeholder} = $new_val if (defined $new_val);
    return $self->{placeholder};
}
sub start_time : lvalue {
    my ($self, $new_val) = @_;
    $self->{start_time} = _parse_start_time($new_val) if defined $new_val;
    return $self->{start_time};
}

sub start_date : lvalue {
    my ($self, $new_val) = @_;
    $self->{start_date} = _parse_start_date($new_val) if defined $new_val;
    return $self->{start_date};
}

sub is_array {
    # Check if the job is an array
    my $self = shift @_;
    return scalar @{$self->{files}} > 0;
}
sub hours : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{hours} = _time_to_hour($new_val) if (defined $new_val);
    return $self->{hours};
}

sub tmpdir : lvalue {
    # Update tmpdir
    my ($self, $new_val) = @_;
    $self->{tmpdir} = $new_val if (defined $new_val);
    return $self->{tmpdir};
}

sub opts : lvalue {
    # Update opts
    my ($self, $new_val) = @_;
    if (not defined $self->{opts}) {
        $self->{opts} = [];
        return $self->{opts};
    }
    # check newval is an array
    confess "ERROR NBI::Opts: opts must be an array, got $new_val\n" if (ref($new_val) ne "ARRAY");
    $self->{opts} = $new_val if (defined $new_val);
    return $self->{opts};
}
sub add_option {
    # Add an option
    my ($self, $new_val) = @_;
    push @{$self->{opts}}, $new_val;
    return $self->{opts};
}

sub opts_count {
    # Return the number of options
    my $self = shift @_;
    return defined $self->{opts} ? scalar @{$self->{opts}} : 0;
}

sub view {
    # Return a string representation of the object
    my $self = shift @_;
    my $str = " --- NBI::Opts object ---\n";
    $str .= " queue:\t" . $self->{queue} . "\n";
    $str .= " threads:\t" . $self->{threads} . "\n";
    $str .= " memory MB:\t" . $self->{memory} . "\n";
    $str .= " time (h):\t" . $self->{hours} . "\n";
    $str .= " tmpdir:\t" . $self->{tmpdir} . "\n";
    my $begin = $self->_compute_begin();
    $str .= " begin:\t" . $begin . "\n" if defined $begin;
    $str .= " ---------------------------\n";
    for my $o (@{$self->{opts}}) {
        $str .= "#SBATCH $o\n" if defined $o;
    }
    return $str;
}

sub header {
    # Return a header for the script based on the options
    my $self = shift @_;
    my $str = "#!/bin/bash\n";
    # Queue
    $str .= "#SBATCH -p " . $self->{queue} . "\n";
    # Nodes: 1
    $str .= "#SBATCH -N 1\n";
    # Time
    $str .= "#SBATCH -t " . $self->timestring() . "\n";
    # Memory
    $str .= "#SBATCH --mem=" . $self->{memory} . "\n";
    # Threads
    $str .= "#SBATCH -c " . $self->{threads} . "\n";
    # Mail
    if (defined $self->{email_address}) {
        $str .= "#SBATCH --mail-user=" . $self->{email_address} . "\n";
        $str .= "#SBATCH --mail-type=" . $self->{email_type} . "\n";
    }

    # Custom options
    for my $o (@{$self->{opts}}) {
        next if not defined $o;
        $str .= "#SBATCH $o\n";
    }

    # Job array
    if ($self->is_array()) {
        my $len = scalar @{$self->{files}} - 1;
        $str .= "#SBATCH --array=0-$len\n";
    }
    # Begin time
    my $begin = $self->_compute_begin();
    $str .= "#SBATCH --begin=$begin\n" if defined $begin;
    return $str;
}

sub timestring {
    my $self = shift @_;
    my $hours = $self->{hours};
    my $days = 0+ int($hours / 24);
    $hours = $hours % 24;
    # Format hours to be 2 digits
    $hours = sprintf("%02d", $hours);
    return "${days}-${hours}:00:00";
}

sub _mem_parse_mb {
    my $mem = shift @_;
    if ($mem=~/^(\d+)$/) {
        # bare number: interpret as MB
        return $mem;
    } elsif ($mem=~/^(\d+)\.?(MB?|GB?|TB?|KB?)$/i) {
        if (substr(uc($2), 0, 1) eq "G") {
            $mem = $1 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "T") {
            $mem = $1 * 1024 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "M") {
            $mem = $1;
        } elsif (substr(uc($2), 0, 1) eq "K") {
            $mem = int($1/1024);
        } else {
            # Consider MB
            $mem = $1;
        }
    } else {
        confess "ERROR NBI::Opts: Cannot parse memory value $mem\n";
    }
    return $mem;
}

sub _time_to_hour {
    # Get an integer (hours) or a string in the format \d+D \d+H \d+M \d+S
    my $time = shift @_;
    $time = uc($time);
    
    if ($time =~ /^(\d+)$/) {
        # Got an integer
        return $1;
    } else {
        my $hours = 0;
        while ($time =~ /(\d+)([DHMS])/g) {
            my $val = $1;
            my $unit = $2;
            if ($unit eq "D") {
                $hours += $val * 24;
            } elsif ($unit eq "H") {
                $hours += $val;
            } elsif ($unit eq "M") {
                $hours += $val / 60;
            } elsif ($unit eq "S") {
                $hours += $val / 3600;
            } else {
                die "ERROR NBI::Opts: Cannot parse time value $time\n";
            }
        }
        return $hours;
    }
}


sub _parse_start_time {
    # Accept H:MM, HH:MM, H:MM:SS, HH:MM:SS (24h only). Returns "HH:MM:SS".
    my $time = shift;
    unless ($time =~ /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/) {
        confess "ERROR NBI::Opts: Cannot parse start time '$time'. Use HH:MM or HH:MM:SS (24h format)\n";
    }
    my ($h, $m, $s) = ($1, $2, $3 // 0);
    confess "ERROR NBI::Opts: Invalid hour $h in '$time' (must be 0-23)\n"   if $h > 23;
    confess "ERROR NBI::Opts: Invalid minute $m in '$time' (must be 0-59)\n" if $m > 59;
    confess "ERROR NBI::Opts: Invalid second $s in '$time' (must be 0-59)\n" if $s > 59;
    return sprintf("%02d:%02d:%02d", $h, $m, $s);
}

sub _parse_start_date {
    # Accept DD/MM or DD/MM/YYYY. Returns "YYYY-MM-DD".
    # When year is omitted, infers current year; if that date is already past, uses next year.
    # Also accepts the already-normalised YYYY-MM-DD form (idempotent).
    my $date = shift;

    # Already normalised by a previous call — pass through unchanged.
    return $date if $date =~ /^\d{4}-\d{2}-\d{2}$/;

    unless ($date =~ m{^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$}) {
        confess "ERROR NBI::Opts: Cannot parse start date '$date'. Use DD/MM or DD/MM/YYYY\n";
    }
    my ($day, $mon, $year) = ($1, $2, $3);
    confess "ERROR NBI::Opts: Invalid month $mon in '$date' (must be 1-12)\n" if $mon < 1 || $mon > 12;
    confess "ERROR NBI::Opts: Invalid day $day in '$date' (must be 1-31)\n"   if $day < 1 || $day > 31;

    if (!defined $year) {
        my @now       = localtime(time);
        my $curr_year = $now[5] + 1900;
        # midnight today for comparison
        my $today_midnight = mktime(0, 0, 0, $now[3], $now[4], $now[5]);
        my $candidate      = mktime(0, 0, 0, $day, $mon - 1, $curr_year - 1900);
        $year = ($candidate >= $today_midnight) ? $curr_year : $curr_year + 1;
    }

    # Validate via mktime round-trip (catches e.g. 31/02)
    my $epoch = mktime(0, 0, 12, $day, $mon - 1, $year - 1900);
    my @check = localtime($epoch);
    if ($check[3] != $day || $check[4] + 1 != $mon || $check[5] + 1900 != $year) {
        confess "ERROR NBI::Opts: Invalid date '$date' (day out of range for that month)\n";
    }

    return sprintf("%04d-%02d-%02d", $year, $mon, $day);
}

sub _compute_begin {
    # Combine start_date and start_time into a SLURM --begin string.
    # Returns undef when neither is set.
    # Always normalises through the parsers so lvalue assignment of raw strings works.
    my $self = shift;
    return undef unless defined $self->{start_time} || defined $self->{start_date};

    my $time_str = defined $self->{start_time}
        ? _parse_start_time($self->{start_time})
        : "00:00:00";
    my ($h, $m, $s) = split /:/, $time_str;

    my $date_str;
    if (defined $self->{start_date}) {
        $date_str = _parse_start_date($self->{start_date});
    } else {
        # Only time given: use today if that time is still in the future, else tomorrow.
        my @now        = localtime(time);
        my $today_begin = mktime($s, $m, $h, $now[3], $now[4], $now[5]);
        if ($today_begin > time()) {
            $date_str = strftime("%Y-%m-%d", @now);
        } else {
            # mktime normalises day overflow correctly (e.g. 31 -> 1st of next month)
            my @tomorrow = localtime(mktime(0, 0, 0, $now[3] + 1, $now[4], $now[5]));
            $date_str = strftime("%Y-%m-%d", @tomorrow);
        }
    }

    return "${date_str}T${time_str}";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Opts - A class for representing a the SLURM options for NBI::Slurm

=head1 VERSION

version 0.17.0

=head1 SYNOPSIS

SLURM Options for L<NBI::Slurm>, to be passed to a L<NBI::Job> object.

  use NBI::Opts;
  my $opts = NBI::Opts->new(
   -queue => "short",
   -threads => 4,
   -memory => "8GB",
   -time => "2h",
   -opts => [],
  );

=head1 DESCRIPTION

The C<NBI::Opts> module provides a class for representing the SLURM options used by L<NBI::Slurm> for job submission. 
It allows you to set various options such as the queue, number of threads, allocated memory, execution time, input files, and more.

=head1 METHODS

=head2 new()

Create a new instance of C<NBI::Opts>. In this case this will imply using a job array over a list of files

  my $opts = NBI::Opts->new(
    -queue => "short",
    -threads => 4,
    -memory => "8GB",
    -time => "2h",
    -opts => ["--option=Value"],
    -tmpdir => "/path/to/tmp",
    -email_address => "user@example.com",
    -email_type => "ALL",
    -files => ["file1.txt", "file2.txt"],
    -placeholder => "#FILE#"
  );

This method creates a new C<NBI::Opts> object with the specified options. The following parameters are supported:

=over 4

=item * B<-queue> (string, optional)

The SLURM queue to submit the job to. Default is "nbi-short".

=item * B<-threads> (integer, optional)

The number of threads to allocate for the job. Default is 1.

=item * B<-memory> (string or integer, optional)

The allocated memory for the job. It can be specified as a bare number representing megabytes (e.g., 1024), or with a unit suffix (e.g., "8GB"). Default is 100 megabytes.

=item * B<-time> (string or integer, optional)

The time limit for the job. It can be specified as hours (e.g., 2) or as a string with time units (e.g., "2h", "1d 12h"). Default is 1 hour.

=item * B<-opts> (arrayref, optional)

An array reference containing additional SLURM options to be passed to the job script.

=item * B<-tmpdir> (string, optional)

The temporary directory to use for job execution. Default is the system's temporary directory.

=item * B<-email_address> (string, optional)

The email address for job notifications.

=item * B<-email_type> (string, optional)

The type of email notifications to receive (e.g., "NONE", "BEGIN", "END", "FAIL", "ALL"). Default is "NONE".

=item * B<-files> (arrayref, optional)

An array reference containing input files or file patterns for the job.

=item * B<-placeholder> (string, optional)

A placeholder string to be used in the command for input files. Default is "#FILE#".

=back

=head2 queue

Accessor method for the SLURM queue.

  $opts->queue = "long";
  my $queue = $opts->queue;

=head2 threads

Accessor method for the number of threads.

  $opts->threads = 8;
  my $threads = $opts->threads;

=head2 memory

Accessor method for the allocated memory.

  $opts->memory = "16GB";
  my $memory = $opts->memory;

=head2 email_address

Accessor method for the email address.

  $opts->email_address = "user@example.com";
  my $email_address = $opts->email_address;

=head2 email_type

Accessor method for the email notification type.

  $opts->email_type = "ALL";
  my $email_type = $opts->email_type;

=head2 hours

Accessor method for the execution time in hours.

  $opts->hours = 24;
  my $hours = $opts->hours;

=head2 tmpdir

Accessor method for the temporary directory.

  $opts->tmpdir = "/path/to/tmpdir";
  my $tmpdir = $opts->tmpdir;

=head2 opts

Accessor method for the additional SLURM options.

  $opts->opts = ["--output=TestJob.out", "--mail-user user@example.com"];
  my $opts_array = $opts->opts;

=head2 files

Accessor method for the input files or file patterns.

  $opts->files = ["file1.txt", "*.fasta"];
  my $files = $opts->files;

=head2 placeholder

Accessor method for the input file placeholder.

  $opts->placeholder = "{INPUT}";
  my $placeholder = $opts->placeholder;

=head2 start_time

Accessor for the job start time (24h format). Triggers C<--begin> in the script header.

  $opts->start_time = "22:00";      # 10 pm
  $opts->start_time = "9:30";       # 9:30 am
  $opts->start_time = "13:45:00";   # with seconds

Accepted formats: C<H:MM>, C<HH:MM>, C<H:MM:SS>, C<HH:MM:SS>.
12-hour (am/pm) notation is not accepted.

=head2 start_date

Accessor for the job start date.

  $opts->start_date = "25/12";          # infers year
  $opts->start_date = "01/06/2026";     # explicit year

Accepted formats: C<DD/MM> or C<DD/MM/YYYY>.
When the year is omitted it is inferred: the current year is used unless that
date has already passed, in which case next year is used.

=head2 add_option

Add an additional SLURM option.

  $opts->add_option("--output=TestJob.out");

=head2 opts_count

Get the number of additional SLURM options.

  my $count = $opts->opts_count;

=head2 is_array

Check if the job is an array job (has multiple input files).

  my $is_array = $opts->is_array;

=head2 view

Get a string representation of the options.

  my $str = $opts->view;

=head2 header

Generate the SLURM header for the job script.

  my $header = $opts->header;

=head2 timestring

Get the execution time as a formatted string.

  my $timestring = $opts->timestring;

Returns the execution time in the format "DD-HH:MM:SS".

=head1 INTERNAL METHODS

=head2 _mem_parse_mb

Parse memory input and convert to megabytes.

=head2 _time_to_hour

Convert time input to hours.

=cut

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
