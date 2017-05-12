package Perlbal::Control;

use Moose;
use Proc::ProcessTable;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:FAYLAND';

with 'MooseX::Control';

has '+control_name' => ( default => 'perlbal' );

sub pre_startup   { inner() }
sub post_startup  { inner() }

sub pre_shutdown  { inner() }
sub post_shutdown { inner() }

sub get_server_pid {
    my $self = shift;

    my $pid_file     = $self->pid_file;

    if ($pid_file and $pid_file ne Path::Class::File->new('/tmp/unknown.pid')) {
        my $pid  = $pid_file->slurp(chomp => 1);
        ($pid)
            || confess "No PID found in pid_file (" . $pid_file . ")";
        
        return $pid;
    } else {
        my $config_file  = $self->config_file->stringify;
        my $control_name = $self->control_name;
        my $p = new Proc::ProcessTable( 'cache_ttys' => 1 );
        my $all = $p->table;
        foreach my $one (@$all) {
            if ($one->cmndline =~ /$control_name/ and $one->cmndline =~ /$config_file/) {
                return $one->pid;
            }
        }
    }
    return 0;
}

sub construct_command_line {
    my $self = shift;
    my @opts = @_;
    my $conf = $self->config_file;
    
    (-f $conf)
        || confess "Could not locate configuration file ($conf)";
    
    ($self->binary_path, '--daemon', '--config', $conf->stringify);
}

sub find_pid_file {
    my $self = shift;
    
    my $config_file = $self->config_file;
    
    (-f $config_file)
        || confess "Could not find pid_file because could not find config file ($config_file)";

    my @approaches = (
        sub { $config_file->slurp(chomp => 1) },
    );
    
    # it's optional
    foreach my $approach (@approaches) {    
        my @config = $approach->();
        foreach my $line (@config) {
            if ($line =~ /pid_file\s*\=\s*(.*)\s*/) {
                return Path::Class::File->new($1);
            }
        }
    }
    
    # if not find, just return nothing
    return Path::Class::File->new('/tmp/unknown.pid');
};

no Moose;

1;
__END__

=head1 NAME

Perlbal::Control - Simple class to manage perlbal

=head1 SYNOPSIS

    use Perlbal::Control;

    my ($command) = @ARGV;
    
    my $ctl = Perlbal::Control->new(
        config_file => [qw[ conf perlbal.conf ]],
        # PID file can also be discovered automatically 
        # from the conf, or if you prefer you can specify
        pid_file    => 'perlbal.pid',    
    );
  
    $ctl->start if lc($command) eq 'start';
    $ctl->stop  if lc($command) eq 'stop';

=head1 DESCRIPTION

This is a fork of L<Lighttpd::Control> to work with Perlbal, it maintains 100%
API compatibility. In fact most of this documentation was stolen too. This is
an early release with only the bare bones functionality needed, future
releases will surely include more functionality. Suggestions and crazy ideas
welcomed, especially in the form of patches with tests.

=head1 ATTRIBUTES

=over 4

=item I<config_file>

This is a L<Path::Class::File> instance for the configuration file.

=item I<binary_path>

This is a L<Path::Class::File> instance pointing to the perlbal 
binary. This can be autodiscovered or you can specify it via the 
constructor.

=item I<pid_file>

This is a L<Path::Class::File> instance pointing to the perlbal 
pid file. This can be autodiscovered from the config file or you 
can specify it via the constructor. it is optional.

=back

=head1 METHODS 

=over 4

=item B<start>

Starts the perlbal deamon that is currently being controlled by this 
instance. It will also run the pre_startup and post_startup hooks.

=item B<stop>

Stops the perlbal deamon that is currently being controlled by this 
instance. It will also run the pre_shutdown and post_shutdown hooks.

=item B<get_server_pid>

This is the PID of the live server.

=item B<is_server_running>

Checks to see if the perlbal deamon that is currently being controlled 
by this instance is running or not (based on the state of the PID file).

=item B<debug>

depends on $ctl->verbose.

=back

=head1 SEE ALSO

L<MooseX::Control>, L<Lighttpd::Control>, L<Nginx::Control>, L<Sphinx::Control>

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
