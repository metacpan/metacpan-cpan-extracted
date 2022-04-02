package Perl::Server;

use strict;
use warnings;
use Cwd;
use Plack::Runner;
use Term::ANSIColor;

our $VERSION = '0.05';

sub new {
    my $class = shift;
    my $path  = shift;
    
    return bless {
        path => $path ? $path : getcwd,
        type => ''
    }, $class;
}

sub run {
    my $self = shift;
    my @argv = @_;

    my $type = $self->_type;   

    if (exists $type->{module}) {
        push(@argv, '-M');
        push(@argv, $type->{module});
        
        push(@argv, '-e');
        push(@argv, $type->{eval});          
    } else {
        push(@argv, '-a');
        push(@argv, $type->{app});        
    }
    
    unless (grep(/^(-p|--port)$/, @argv)) {
        push(@argv, '-p');
        push(@argv, 3000);      
    }
    
    $ENV{PLACK_ENV} = 'perl-server';       
    
    my $runner = Plack::Runner->new;    
    $runner->parse_options(@argv);   
    $self->_message($runner);
    $runner->run;
}

sub _type {
    my $self = shift;
    
    my $path = $self->{path};
    
    my $type = {};
        
    if (-d $path) {
        $self->{type} = 'Folder';
        $type->{module} = 'Plack::App::WWW';
        $type->{eval}   = "Plack::App::WWW->new(root => '$path')->to_app";        
    } elsif (-e $path && $path =~ /\.(pl|cgi)$/i) {
        $self->{type} = 'File';
        $type->{module} = 'Plack::App::WrapCGI';
        $type->{eval}   = "Plack::App::WrapCGI->new(script => '$path')->to_app";         
    } else {
        $self->{type} = 'PSGI';
        $type->{app} = $path;
    }
    
    return $type;
}

sub _message {
    my ($self, $runner) = @_;
    
    push @{$runner->{options}}, server_ready => sub {
        my $args = shift;
        my $server = $args->{server_software} || ref($args);
        my $host   = $args->{host}  || 0;
        my $proto  = $args->{proto} || 'http';
        my $port   = $args->{port};
        
        $self->_name;
        $self->_print('Version', $VERSION);
        $self->_print('Server', $server);
        $self->_print('Type', $self->{type});
        $self->_print('Path', $self->{path});
        $self->_print('Available on', "$proto://$host:$port");
        $self->_stop;
    };     
}

sub _name {
    print STDERR color('bold blue');
    print STDERR "Perl::Server\n\n";    
}

sub _stop {
    print STDERR color('reset');
    print STDERR color('white');    
    print STDERR "\nHit CTRL-C to stop the perl-server\n";
}

sub _print {
    my ($self, $name, $value) = @_;
    
    print STDERR color('reset');
    print STDERR color('yellow');
    print STDERR "$name: ";
    print STDERR color('reset');
    print STDERR color('green');
    print STDERR "$value\n";      
}

1;

__END__

=encoding utf8
 
=head1 NAME
 
Perl::Server - A simple Perl server launcher.

=head1 SYNOPSIS

    # run path current
    $ perl-server 
    
    # run path 
    $ perl-server /home/foo/www
    
    # run file Perl
    $ perl-server foo.pl
    
    # run file psgi
    $ perl-server app.psgi    

=head1 DESCRIPTION

Perl::Server is a simple, zero-configuration command-line Perl server. 
It is to be used for testing, local development, and learning.

Using Perl::Server:

    $ perl-server [path] [options]
    
    # or
    
    $ perl-server [options]
    
These options are the same as L<Plackup Options|plackup#OPTIONS>.

=head1 SEE ALSO
 
L<Plack>, L<Plack::App::WWW>, L<Plack::App::WrapCGI>, L<Plack::App::CGIBin>, L<plackup>.
 
=head1 AUTHOR
 
Lucas Tiago de Moraes, C<lucastiagodemoraes@gmail.com>.
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut
