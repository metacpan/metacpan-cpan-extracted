package Sphinx::Control;

use Moose;
use Path::Class;
use Errno qw/ECHILD/;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:FAYLAND';

with 'MooseX::Control';

has '+control_name' => ( default => 'searchd' );
has 'indexer_args' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub pre_startup   { inner() }
sub post_startup  { inner() }

sub pre_shutdown  { inner() }
sub post_shutdown { inner() }

sub get_server_pid {
    my $self = shift;
    
    my $pid  = $self->pid_file->slurp(chomp => 1);
    ($pid)
        || confess "No PID found in pid_file (" . $self->pid_file . ")";
    $pid;
}

sub construct_command_line {
    my $self = shift;
    my @opts = @_;
    my $conf = $self->config_file;
    
    (-f $conf)
        || confess "Could not locate configuration file ($conf)";
    
    ($self->binary_path, @opts, '--config', $conf->stringify);
}

sub find_pid_file {
    my $self = shift;
    
    my $config_file = $self->config_file;
    
    (-f $config_file)
        || confess "Could not find pid_file because could not find config file ($config_file)";

    my @approaches = (
        sub { $config_file->slurp(chomp => 1) },
    );
    
    foreach my $approach (@approaches) {    
        my @config = $approach->();
        foreach my $line (@config) {
            if ($line =~ /pid_file\s*\=\s*(.*)\s*/) {
                return Path::Class::File->new($1);
            }
        }
    }
    
    confess "Could not locate the pid-file information, please supply it manually";
};

sub restart {
    my $self = shift;
    
    $self->debug("Restarting searchd ...");
    $self->stop;
    
    $self->start;
    $self->debug("searchd restarted.");
}

sub reload {
    my $self = shift;
    
    $self->debug("reloading searchd ...");
    
    if ( $self->is_server_running ) {
    	# send HUP
    	kill 1, $self->server_pid;
    }
    else {
	    $self->start;
    }
    $self->debug("searchd reloaded.");
}

sub run_indexer {
    my $self = shift;
    my @extra_args = @_;

    my $searchd = $self->binary_path;
    my $indexer = $searchd;
    $indexer =~ s/searchd$/indexer/is;

    confess "Cannot execute Sphinx indexer binary $indexer" unless -x $indexer;

    $self->debug("starting indexer ...");

    my $config = $self->config_file->stringify;
    my $cmd = "$indexer --config $config";
    $cmd .= ' ' . join(" ", @{$self->indexer_args}) if $self->indexer_args;
    $cmd .= ' ' . join(" ", @extra_args) if @extra_args;

    $self->debug("run $cmd...");
    if (my $status = _system_with_status($cmd)) {
	    confess $status;
    }

    $self->debug("indexer done...");
}

sub _system_with_status {
    my ($command) = @_;

    local $SIG{CHLD} = 'IGNORE';
    my $status = system($command);
    unless ($status == 0) {
        if ($? == -1) {
	        return '' if $! == ECHILD;
            return "$command failed to execute: $!";
        }
        if ($? & 127) {
            return sprintf("$command died with signal %d, %s coredump\n",
                           ($? & 127),  ($? & 128) ? 'with' : 'without');
        }
        return sprintf("$command exited with value %d\n", $? >> 8);
    }
    return '';
}

no Moose; 1;

1;
__END__

=head1 NAME

Sphinx::Control - Simple class to manage a Sphinx searchd

=head1 SYNOPSIS

    use Sphinx::Control;
    
    my ($command) = @ARGV;
    
    my $ctl = Sphinx::Control->new(
        config_file => [qw[ conf sphinx.conf ]],
        # PID file can also be discovered automatically 
        # from the conf, or if you prefer you can specify
        pid_file    => 'searchd.pid',    
    );
  
    $ctl->start if lc($command) eq 'start';
    $ctl->stop  if lc($command) eq 'stop';

=head1 DESCRIPTION

This is a fork of L<Lighttpd::Control> to work with Sphinx searchd, it maintains 100%
API compatibility. In fact most of this documentation was stolen too. This is
an early release with only the bare bones functionality needed, future
releases will surely include more functionality. Suggestions and crazy ideas
welcomed, especially in the form of patches with tests.

=head1 ATTRIBUTES

=over 4

=item I<config_file>

This is a L<Path::Class::File> instance for the configuration file.

=item I<binary_path>

This is a L<Path::Class::File> instance pointing to the searchd 
binary. This can be autodiscovered or you can specify it via the 
constructor.

=item I<pid_file>

This is a L<Path::Class::File> instance pointing to the searchd 
pid file. This can be autodiscovered from the config file or you 
can specify it via the constructor.

=back

=head1 METHODS 

=over 4

=item B<start>

Starts the Sphinx searchd deamon that is currently being controlled by this 
instance. It will also run the pre_startup and post_startup hooks.

=item B<stop>

Stops the Sphinx searchd deamon that is currently being controlled by this 
instance. It will also run the pre_shutdown and post_shutdown hooks.

=item B<restart>

Stops and thens starts the searchd daemon.

=item B<reload>

Sends a HUP signal to the searchd daemon if it is running, to tell it to reload
its databases; otherwise starts searchd.

=item B<get_server_pid>

This is the PID of the live server.

=item B<is_server_running>

Checks to see if the Sphinx searchd deamon that is currently being controlled 
by this instance is running or not (based on the state of the PID file).

=item B<indexer_args>

    $ctl->indexer_args(\@args)
    $args = $ctl->indexer_args;

Set/get the extra command line arguments to pass to the indexer program when
started using run_indexer.  These should be in the form of an array, each entry
comprising one option or option argument.  Arguments should exclude '--config
CONFIG_FILE', which is included on the command line by default.

=item B<run_indexer(@args)>

Runs the indexer program; dies on error.  Arguments passed to the indexer are
"--config CONFIG_FILE" followed by args set through indexer_args, followed by
any additional args given as parameters to run_indexer.

Copied from L<Sphinx::Manager>

=item B<debug>

depends on $ctl->verbose.

=back

=head1 SEE ALSO

L<MooseX::Control>, L<Sphinx::Manager>, L<Lighttpd::Control>, L<Nginx::Control>, L<Perlbal::Control>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam

except for those parts that are 

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
