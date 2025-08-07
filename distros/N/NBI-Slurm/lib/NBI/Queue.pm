#ABSTRACT: NBI::Queue, to filter jobs in the queue
use strict;
use warnings;
package NBI::Queue;
use Carp qw(croak confess);
use NBI::Slurm;
use NBI::QueuedJob;
use Data::Dumper qw(Dumper);
$NBI::Queue::VERSION = $NBI::Slurm::VERSION;



# Export QueuedJob
use base qw(Exporter);
our @EXPORT = qw(NBI::QueuedJob new);
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    

    # -username
    # -jobid
    my $username;
    my $jobid;
    my $queue;
    my $state_short;
    my $partitions_csv;
    my $jobname;
    if (defined $_[0] and substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        for my $i (keys %data) {
            if ($i =~ /^-user/)  {
                next unless defined $data{$i};
                $username = $data{$i};
            } elsif ($i =~ /^-jobid/)  {
                next unless defined $data{$i};
                if ($data{$i} =~ /^\d+$/) {
                    $jobid = $data{$i};
                } else {
                    confess "ERROR NBI::Queue: -jobid expects an integer\n";
                }
            } elsif ($i =~ /^-queue/) {
                next unless defined $data{$i};
                $queue = $data{$i};
            } elsif ($i =~ /^-state/) {
                next unless defined $data{$i};
                my @valid_states =  qw(PD R CG CF CA CD F TO NF SE ST RV S SO PR NF RV S SO PR);
                if (grep {$_ eq uc($data{$i})} @valid_states) {
                    $state_short = uc($data{$i});
                } else {
                    confess "ERROR NBI::Queue: -state expects one of the following values: @valid_states\n";
                }
            } elsif ($i =~ /^-name/) {
                $jobname = $data{$i} if defined $data{$i};
            } else {
                confess "ERROR NBI::Queue: Unknown option/parameter $i\n";
            }
        }
    }
    my $jobs = _squeue($username, $jobid, $state_short, $partitions_csv, $jobname);
    $self->{username} = $username // undef;
    $self->{jobid} = $jobid // undef;
    $self->{queue} = $queue // undef;
    $self->{state_short} = $state_short // undef;
    $self->{jobs} = $jobs;
    $self->{jobname} = $jobname // undef;
    return $self;
}

sub remove {
    my $self = shift;
    my $jobid = shift;
    my @jobs = grep {$_->jobid != $jobid} @{$self->{jobs}};
    $self->{jobs} = \@jobs;
}
sub _squeue {
    my ($username, $jobid, $state_short, $partitions_csv, $jobname) = @_;
    my $field_sep = ':/:';
    my @field_names = qw(jobid user jobname cpus memory queue status start_time end_time total_time time_left command workdir account reason);
    my $format = join $field_sep, @field_names;
    $format = _make_format_string($format);

    # Prepare command
    my $cmd = "squeue --format '$format' --noheader ";
    $cmd .= " -u $username " if defined $username;
    $cmd .= " -j $jobid " if defined $jobid;
    $cmd .= " -t $state_short " if defined $state_short;
    $cmd .= " -p $partitions_csv " if defined $partitions_csv;

    # Prepend '-' to @field_names
    @field_names = map { "-$_" } @field_names;

    my @output = `$cmd 2>/dev/null`;
    if ($? != 0) {
        Carp::croak "ERROR NBI::Queue: squeue failed. Are you in a SLURM cluster?\n";
    }
    my @header;
    my $c = 0;
    my @jobs;
    for my $line (@output) {
        $c++;
        chomp $line;
        
        my @fields = split /$field_sep/, $line;

        # Make a hash of @fields_names and @fields
        my %job;
        @job{@field_names} = @fields;
        
        ## FILTER FURTHER
        if (defined $jobname) {
            next unless $job{-"jobname"} =~ /$jobname/;
        }

        my $submitted_job = NBI::QueuedJob->new(%job);

        

        push @jobs, $submitted_job;
    }
    return \@jobs;
}

sub len {
    my $self = shift;
    return scalar @{$self->{jobs}};
}

sub ids {
    my $self = shift;
    my @ids = map {$_->jobid} @{$self->{jobs}};
    # If scalar
    if (wantarray) {
        return @ids;
    } else {
        return \@ids;
    }
}
sub _make_format_string {
    my $string = shift;
    
    for my $key (keys %NBI::Slurm::FORMAT_STRINGS) {
        my $val = $NBI::Slurm::FORMAT_STRINGS{$key};
        $string =~ s/$key/$val/;
    }

    return $string;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Queue - NBI::Queue, to filter jobs in the queue

=head1 VERSION

version 0.14.0

=head1 SYNOPSIS

  use NBI::Queue;  

  # Create a new Queue object  
  my $queue = NBI::Queue->new(  
      -username => 'username',  
      -jobid    => 12345,  
      -queue    => 'queue_name',  
      -state    => 'PD',  
      -name     => 'job_name',  
  );  

  # Access and modify object attributes  
  $queue->username = 'new_username';  
  $queue->state    = 'R';  

  # Get the length of the queue  
  my $length = $queue->len;  

  # Get the job IDs in the queue  
  my @job_ids = $queue->ids;

=head1 DESCRIPTION

The C<NBI::Queue> module provides a mechanism to filter and manage jobs in the SLURM queue. 
It allows you to create a queue object and retrieve information about the jobs based on various 
criteria such as username, job ID, queue name, job state, and job name.
Each job is represented by a L<NBI::QueuedJob> object, which provides access to the job attributes.

=head1 METHODS

=head2 new

  my $queue = NBI::Queue->new(%options);

Creates a new C<NBI::Queue> object with the specified options. 
The options should be provided as a hash, using the following keys:

=over 4

=item C<-username>

Filter jobs by username.

=item C<-jobid>

Filter jobs by job ID.

=item C<-queue>

Filter jobs by queue name.

=item C<-state>

Filter jobs by job state (e.g., PD, R, CG, CF).

=item C<-name>

Filter jobs by job name.

=back

=head2 len

  my $length = $queue->len;

Returns the length (number of jobs) in the queue.

=head2 ids

  my @job_ids = $queue->ids;

Returns an array or array reference (depending on the context) containing the job IDs in the queue.

=head2 remove

  $queue->remove($jobid);

Removes the job with the specified job ID from the queue.

=cut

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
