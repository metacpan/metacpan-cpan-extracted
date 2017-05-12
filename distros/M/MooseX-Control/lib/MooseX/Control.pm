package MooseX::Control;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use Path::Class;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:FAYLAND';

has 'control_name' => (
    is   => 'rw',
    isa  => 'Str',
    default => 'unkown',
);

has 'config_file' => (
    is       => 'rw',
    isa      => 'Path::Class::File',
    coerce   => 1,
);

has 'binary_path' => (
    is      => 'rw',
    isa     => 'Path::Class::File',
    coerce  => 1,
    lazy    => 1,
    builder => '_find_binary_path'
);

sub _find_binary_path {
    my $self = shift;

    my $control_name = $self->control_name;
    my $control_exe = do {
        my $bin = `which $control_name`;
        chomp($bin);
        Path::Class::File->new($bin)
    };

    return $control_exe if -x $control_exe;

    for my $prefix (qw(/usr /usr/local /opt/local /sw)) {
        for my $bindir (qw(bin sbin)) {
            my $control_exe = Path::Class::File->new($prefix, $bindir, $control_name);
            return $control_exe if -x $control_exe;
        }
    }

    confess "can't find $control_name anywhere tried => (" . ($control_exe || 'nothing') . ")";
}

has 'pid_file' => (
    is      => 'rw',
    isa     => 'Path::Class::File',
    coerce  => 1,
    lazy    => 1,
    builder => 'find_pid_file',
);
requires 'find_pid_file';

my $sub_verbose = sub {
    my $msg = shift;
    $msg =~ s/\s+$//;
    print STDERR "$msg\n";
};
subtype 'Verbose'
    => as 'CodeRef'
    => where { 1; };
coerce 'Verbose'
    => from 'Int'
    => via {
        if ($_) {
            return $sub_verbose;
        } else {
            return sub { 0 };
        }
    };

has 'verbose' => ( is => 'rw', isa => 'Verbose', coerce => 1, default => 0 );

sub debug {
    my $self = shift;
    
    return unless $self->verbose;
    $self->verbose->(@_);
}

requires 'pre_startup';
requires 'pre_shutdown';
requires 'post_startup';
requires 'post_shutdown';

requires 'get_server_pid';
requires 'construct_command_line';

sub is_server_running {
    my $self = shift;
    
    my $pid_file = $self->pid_file;
    
    # no pid file, no server running ...
    if ($pid_file and $pid_file ne Path::Class::File->new('/tmp/unknown.pid')) {
        return 0 if (not -s $self->pid_file);
    }

    my $server_pid = $self->get_server_pid;
    return 0 if ( $server_pid == 0 );

    # check it ...
    kill(0, $server_pid) ? 1 : 0;
}

sub start {
    my $self = shift;
    
    my $control_name = $self->control_name;

    $self->debug("Starting $control_name ...");
    $self->pre_startup;

    # NOTE:
    # do this after startup so that it
    # would be possible to write the 
    # config file in the pre_startup
    # hook if we wanted to.
    # - SL
    my @cli = $self->construct_command_line;

    unless (system(@cli) == 0) {
        $self->debug("Could not start $control_name (@cli) exited with status $?");
        return;
    }

    $self->post_startup;

    $self->debug("$control_name started.");    
}

sub stop {
    my $self    = shift;
    
    my $control_name = $self->control_name;
    
    if ( $self->is_server_running ) {

        $self->debug("Stoping $control_name ...");
        $self->pre_shutdown;
        
        kill 2, $self->get_server_pid;
        
        $self->post_shutdown;
        $self->debug("$control_name stopped.");    
        
        return;
    }

    $self->debug("server is not running.");
}

no Moose;
no Moose::Util::TypeConstraints;

1;
__END__

=head1 NAME

MooseX::Control - Simple class to manage a execute deamon

=head1 SYNOPSIS

    package XXXX::Control;
    
    use Moose;
    with 'MooseX::Control';
    
    has '+control_name' => ( default => 'xxxx' );
    
    sub pre_startup   { inner() }
    sub post_startup  { inner() }
    sub pre_shutdown  { inner() }
    sub post_shutdown { inner() }
    
    sub get_server_pid { }
    sub construct_command_line { }
    sub find_pid_file { }

=head1 DESCRIPTION

It is a Moose Role to ease writing XXX::Control like L<Sphinx::Control>, L<Perlbal::Control>

Please view source code for more details.

L<http://search.cpan.org/dist/Sphinx-Control/lib/Sphinx/Control.pm>

L<http://search.cpan.org/dist/Perlbal-Control/lib/Perlbal/Control.pm>

=head1 REQUIRED ATTRIBUTES AND METHODS

=head2 ATTRIUTES

=head3 B<control_name>

    has '+control_name' => ( default => 'perlbal' );
    # or
    has '+control_name' => ( default => 'searchd' );

=head2 METHODS

=head3 find_pid_file

To find a pid file for B<control_name>

if the pid file is optional for B<control_name> like perlbal, we return

    Path::Class::File->new('/tmp/unknown.pid')

=head3 construct_command_line

system command for B<start>.

    sub construct_command_line {
        my $self = shift;
        
        my $conf = $self->config_file;
        (-f $conf)
            || confess "Could not locate configuration file ($conf)";
        
        ($self->binary_path, '--daemon', '--config', $conf->stringify);
    }

=head3 get_server_pid

a pid number for B<contorl_name>

if $self->pid_file is there, we general write like:

    sub get_server_pid {
        my $self = shift;
        
        my $pid  = $self->pid_file->slurp(chomp => 1);
        ($pid)
            || confess "No PID found in pid_file (" . $self->pid_file . ")";
        $pid;
    }

if no $pid_file, we may use L<Proc::ProcessTable>.

   sub get_server_pid {
        my $self = shift;
    
        my $pid_file     = $self->pid_file;
    
        if ( $pid_file ) {
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

=head1 PROVIDED ATTRIBUTES AND METHODS

=head2 ATTRIBUTES

=head3 binary_path

return a L<Path::Class::File> of execute file like /usr/bin/search or /usr/bin/perlbal

=head3 verbose

controls $self->debug

=head2 METHODS

=head3 is_server_running

Checks to see if the B<control_name> deamon that is currently being controlled 
by this instance is running or not (based on the state of the PID).

=head3 start

Starts the B<control_name> deamon that is currently being controlled by this 
instance. It will also run the pre_startup and post_startup hooks.

=head3 stop

Stops the B<control_name> deamon that is currently being controlled by this 
instance. It will also run the pre_shutdown and post_shutdown hooks.

=head1 SEE ALSO

L<Moose>, L<MooseX::Types::Path::Class>, L<Sphinx::Control>, L<Perlbal::Control>

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
