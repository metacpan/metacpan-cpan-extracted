###########################################
package SVN::Utils::ClientIP;
###########################################
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ssh_client_ip);
our $VERSION = "0.02";

use Proc::ProcessTable;
use Proc::Info::Environment;

###########################################
sub ssh_client_ip {
###########################################

    my $finder = __PACKAGE__->new();

    my($ip, $pid, $port) = $finder->ssh_client_ip_find();
    
    if( !defined $ip ) {
        warn $finder->error();
    }

      # only IP
    return $ip;
}

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $proc_info  = Proc::Info::Environment->new();
    my $proc_table = Proc::ProcessTable->new();

    my %ppid_of = ();
    foreach my $proc ( @{$proc_table->table} ) {
      $ppid_of{ $proc->pid() } = $proc->ppid();
    }

    my $self = {
        proc_info           => $proc_info,
        ppid_of             => \%ppid_of,
        pid                 => $$,
        ssh_client_var_name => "SSH_CLIENT",
        error               => undef,
        %options
    };

    bless $self, $class;
}

###########################################
sub ssh_client_ip_find {
###########################################
    my($self) = @_;

    my $pid = $self->{pid};

    while( exists $self->{ppid_of}->{ $pid } ) {

        $pid = $self->{ppid_of}->{ $pid };

        last if $pid == 0;

        my $env = $self->{proc_info}->env( $pid );

        if(! defined $env) {
            $self->error( $self->{proc_info}->error() );
            return undef;
        }

        if( exists $env->{ $self->{ssh_client_var_name} } ) {
            my($ip, $pid, $port) = split /\s+/, 
                               $env->{ $self->{ssh_client_var_name} };

            if( wantarray ) {
                return ($ip, $pid, $port);
            }

            return $ip;
        }
    }

    $self->error( "Can't find $self->{ssh_client_var_name} anywhere" );
    return undef;
}

###########################################
sub error {
###########################################
    my($self, $error) = @_;

    if(defined $error) {
        $self->{error} = $error;
    }

    return $self->{error};
}

1;

__END__

=head1 NAME

SVN::Utils::ClientIP - Get the client's IP address in a Subversion Hook

=head1 SYNOPSIS

    use SVN::Utils::ClientIP qw(ssh_client_ip);

    print "The client's IP address is ", ssh_client_ip();

=head1 DESCRIPTION

SVN::Utils::ClientIP solves the age-old problem of obtaining the SSH 
client's IP address in a commit hook of a Subversion repository. 

Knowing the client's IP address can be quite useful in heavily used 
Subversion installations, as it allows for maintaining a log on who 
accessed a repository when and from where.

However, the Subversion developers are not very accomodating when it 
comes to this, claiming "security purposes":

   http://svn.haxx.se/users/archive-2009-02/0804.shtml

But, if you think about how a client connects to the repository using
SSH, which then spawns the svn process, it becomes quite clear how you
can get the IP address, even if the Subversion folks are hiding it from
you: Starting from the currently running hook, walk up the process 
hierarchy, until you reach the parent that's the SSH instance serving the 
client (only tested with openssh). In its environment, you'll find a 
variable named SSH_CLIENT, which contains the IP address of the connecting
client.

This is exactly what this module does, and you can simply obtain the
SSH client's IP address by running

    use SVN::Utils::ClientIP qw(ssh_client_ip);

    my $ip = ssh_client_ip();

Under the hood, the module uses the CPAN modules Proc::ProcessTable
for obtaining the ppid() to walk up the process hierarchy and
Proc::Info::Environment for reading out the SSH_CLIENT environment
variable. By the time of this writing, the latter only worked for
Linux, but in the meantime other OSes might be supported.

It's not terribly expensive, but it adds up and if you're using the 
function many times, you might want to memoize() it.

=head1 OBJECT NOTATION

The ssh_client_ip() convenience function illustrated above will suffice
for most hooks, if you want more control or diagnosing functions, use
the full object notation:

    use SVN::Utils::ClientIP;

    my $finder = SVN::Utils::ClientIP->new();

    if( my $ip = $finder->ssh_client_ip_find() ) {
        print "Found IP address: $ip\n";
    } else {
        print "IP address not found: ", $finder->error(), "\n";
    }

The SSH_CLIENT variable of the ssh process contains not only the 
client's IP address, but also the pid of the process and the port
the client docked on to (typically 22). It looks something like this:

    "123.123.123.123 57890 22"

The convenience function ssh_client_ip returns only the first part. If
you call the object method in scalar context, it also returns only 
the IP address and skips the two following fields. If you want all
fields, use ssh_client_ip_find() in list context:

    my($ip, $pid, $port) = $finder->ssh_client_ip_find();

and $pid and $port will be populated with the values found after
separating blanks in SSH_CLIENT.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
