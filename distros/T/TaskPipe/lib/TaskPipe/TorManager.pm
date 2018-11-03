package TaskPipe::TorManager;

use Moose;
with 'MooseX::ConfigCascade';

use IO::Socket::INET;
use Digest::MD5 'md5_hex';
use Net::EmptyPort;
use Path::Tiny;
use Proc::Background;
use Data::Dumper;
use Log::Log4perl;
use DateTime;
use Module::Runtime 'require_module';
use TryCatch;
use Carp;
use TaskPipe::PortManager;


has settings => (is => 'ro', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new
});

has password => (is => 'rw', isa => 'Str');
has port => (is => 'rw', isa => 'Int');
has control_port => (is => 'rw', isa => 'Int');
has proc => (is => 'rw', isa => 'Proc::Background');
has proc_pid => (is => 'rw', isa => 'Str');
has data_dir => (is => 'rw', isa => 'Path::Tiny');

has tor_socket => (is => 'rw', isa => 'IO::Socket::INET');
has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');
has port_manager => (is => 'ro', isa => 'TaskPipe::PortManager', lazy => 1, default => sub{
    my ($self) = @_;

    TaskPipe::PortManager->new(
        process_name => $self->settings->process_name,
        base_port => $self->settings->base_port,
        gm => $self->gm
    );
});


sub connect_socket{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $thread_row = $self->gm->table('spawned')->find({
        process_name => $self->settings->process_name, 
        job_id => $self->run_info->job_id,
        thread_id => $self->run_info->thread_id 
    });

    my $socket;
    if ( $thread_row ){

        $self->port( $thread_row->port );
        $self->control_port( $thread_row->control_port );
        $self->password( $thread_row->password );
        $socket = $self->get_socket;

    } else {

        $self->port( $self->port_manager->get_new_port_number );
        $self->control_port( $self->port_manager->get_new_port_number );

    }

    if ( ! $socket ){

        $self->new_password;
        $self->start_tor;
        $socket = $self->get_socket;


        my $duplicate;
        my $counter = 0;

        do {
            $duplicate = '';
            try {           
                $self->gm->table('spawned')->create({
                    process_name => $self->settings->process_name,
                    thread_id => $self->run_info->thread_id,
                    job_id => $self->run_info->job_id,
                    used_by_pid => $$,
                    pid => $self->proc_pid,
                    port => $self->port,
                    control_port => $self->control_port,
                    password => $self->password,
                    status => 'connecting',
                    temp_dir => $self->data_dir
                });

            } catch ( DBIx::Error::IntegrityConstraintViolation $err ){

                $duplicate = $err;
            
            } catch ( DBIx::Error $err ){

                confess "Error creating record on spawned table. SQLSTATE = ".$err->state.":\n$err";

            };

            $counter++;

        } while ( $duplicate && $counter < 4 );

        confess "Duplicate error condition persisted while trying to create record, despite retry attempts: ".$duplicate if $duplicate;
    }

    if ( ! $socket ){
        my $msg = "Failed to connect to socket";
        $self->set_status($msg);   
        confess $msg;
    }

    $self->set_status("Connected");
    $logger->info("TOR Connection established");
    $self->tor_socket( $socket );
}

        


sub get_socket{
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->settings->ip,
        PeerPort => $self->control_port,
        Proto => 'tcp'
    );
  
    return $socket;
}



sub start_tor{
    my $self = shift;
    my $logger = Log::Log4perl->get_logger;

    my $opts = $self->settings->exec_opts;

    my $hashed_password_cmd = "tor ${\$opts->{'hash-password'}} ${\$self->password}";
    my $hashed_password = `$hashed_password_cmd`;

    ($hashed_password) = $hashed_password =~ /(16:\w*)$/s;

    confess "Command '$hashed_password_cmd' did not seem to produce a tor password" unless $hashed_password;

    my $data_dir = Path::Tiny->tempdir( CLEANUP => 0 );
    #my $data_dir = Path::Tiny->tempdir;
    $self->data_dir( $data_dir );

    my $cmd = join(' ',$self->settings->exec_name,
        $opts->{'ControlPort'} => $self->control_port,
        $opts->{'SocksPort'} => $self->port,
        $opts->{'DataDirectory'} => $self->data_dir,
        $opts->{'HashedControlPassword'} => $hashed_password,
        $opts->{'f'} => $self->settings->config_path
    );
    $self->proc( Proc::Background->new($cmd) );
    $logger->info("TOR instance launched successfully");
    $self->proc_pid( $self->proc->pid );

    sleep 1;
    if ( ! $self->proc->alive ){
    
        my $cmd_resp = `$cmd`;
        
        confess "Attempt to start tor on port ".$self->port." failed. The command was repeated synchronously to determine the error message. The command was: [$cmd] with response [$cmd_resp]";
    }
}


sub stop_tor{
    my ($self) = @_;

    return unless $self->tor_socket;
    $self->tor_socket->send("SIGNAL SHUTDOWN\n");
}



sub set_status{
    my ($self,$new_status) = @_;

    my $dt = DateTime->now;
    my $datetime = $dt->ymd.' '.$dt->hms;
    $self->gm->table('spawned')->find({ 
        process_name => $self->settings->process_name,
        thread_id => $self->run_info->thread_id,
        job_id => $self->run_info->job_id
    })->update({ 
        status => $new_status, 
        used_by_pid => $$,
        last_checked => $datetime 
    });

}



sub url{
    my $self = shift;
    return $self->settings->scheme."://".$self->settings->ip.':'.$self->port;
}


sub change_ip{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $counter = 0;
    my $err;

    do {
        $err = '';

        try {
            my $answer = "";

            $self->tor_socket->send('AUTHENTICATE "'.$self->password.qq|"\n|);
            $self->tor_socket->recv($answer, 1024);
            die "Could not change ip: failed to authenticate: $answer" unless $answer =~ /^250 OK/;

            $self->tor_socket->send("SIGNAL NEWNYM\n");
            $self->tor_socket->recv($answer, 1024);
            die "Could not change ip: SIGNAL NEWNYM failed: $answer" unless $answer =~ /^250 OK/;

            $self->set_status("changed ip");
            $logger->debug("Changed IP");

        } catch {

            $err = $_;
#            confess "Change IP failed: ".$_;

        };

        $counter++;
    } while ( $err && $counter < 4 );

    confess $err if $err;

}



sub new_password{
    my $self = shift;
    my $logger = Log::Log4perl->get_logger;

    $self->password( md5_hex( (time) * (rand) ) );
}


=head1 NAME

TaskPipe::TorManager - manage TOR processes for TaskPipe

=head1 DESCRIPTION

It is not recommended you use this package directly. See the general manpages for TaskPipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;


1;
