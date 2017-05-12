package Net::P0f::Backend::CmdFE;
use strict;
use Carp;
use IO::File;
use IPC::Open3;

{ no strict;
  $VERSION = 0.02;
  @ISA = qw(Net::P0f);
}

=head1 NAME

Net::P0f::Backend::CmdFE - Back-end for C<Net::P0F> that pilots the B<p0f> utility

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Net::P0f;

    my $p0f = Net::P0f->new(backend => 'cmd', program_path => '/usr/local/bin/p0f');
    ...

=head1 DESCRIPTION

This module is a back-end helper for C<Net::P0f>. 
It provides an interface to pilot the B<p0f(1)> utility by parsing its output. 

See L<Net::P0f> for more general information and examples. 

=head1 METHODS

=over 4

=item init()

This method initializes the backend-specific part of the object. 
It is automatically called by C<Net::P0f> during the object creation. 

B<Options>

=over 4

=item *

C<program_path> - indicates the path of the p0f program. 
If not specified, uses C<PATH>. 

=back

=cut

sub init {
    my $self = shift;
    my %opts = @_;

    # declare my specific options
    $self->{options}{program_path} = 'p0f';
    
    # initialize my options
    for my $opt (keys %opts) {
        exists $self->{options}{$opt} ?
        ( $self->{options}{$opt} = $opts{$opt} and delete $opts{$opt} )
        : carp "warning: Unknown option '$opt'";
    }
}

=item run()

This method runs the backend engine. 
It is called by the C<loop()> method.

=cut

sub run {
    my $self = shift;

    # check that the program_path is defined
    croak "fatal: Please set the path to p0f with the 'program_path' option" 
      unless length $self->{options}{program_path};

    # construct program arguments
    my @program_args = qw(-q -l -t);
    my %opt2arg = (
        chroot_as           => '-u',  # arg: user
        fingerprints_file   => '-f',  # arg: fingerprints file
        fuzzy               => '-F', 
        promiscuous         => '-p', 
        masquerade_detection    => '-M', 
        masquerade_detection_threshold  => '-T',  # arg: threshold
        resolve_names       => '-r', 
    );

    # detection mode
    if($self->{options}{detection_mode} == 1) {
        push @program_args, '-A'
    } elsif($self->{options}{detection_mode} == 2) {
        push @program_args, '-R'
    }

    # set input source
    if($self->{options}{interface}) {
        push @program_args, '-i', $self->{options}{interface}
    } elsif($self->{options}{dump_file}) {
        push @program_args, '-s', $self->{options}{dump_file}
    }
    
    # set switch options
    for my $opt (qw(promiscuous fuzzy resolve_names masquerade_detection)) {
        push @program_args, $opt2arg{$opt} if $self->{options}{$opt}
    }

    # set options with argument
    for my $opt (qw(chroot_as fingerprints_file masquerade_detection_threshold)) {
        push @program_args, $opt2arg{$opt}, $self->{options}{$opt} if $self->{options}{$opt}
    }

    # BPF filter
    push @program_args, $self->{options}{filter} if $self->{options}{filter};

    # launch p0f
    my($stdin,$stdout,$stderr) = (new IO::File, new IO::File, new IO::File);
    my $pid = open3($stdin, $stdout, $stderr, 
        $self->{options}{program_path}, @program_args);

    croak "fatal: Can't exec '", $self->{options}{program_path}, "': $!" unless $pid;

    # initialize looping
    my $callback = $self->{loop}{callback};
    $self->{loop}{keep_on} = 1;
    my $loops = 0;
    
    while($self->{loop}{keep_on}) {
        my %header = (
            timestamp => '', 
            ip_src  => '', name_src  => '', port_src  => '', 
            ip_dest => '', name_dest => '', port_dest => '', 
        );
        my %os_info = ( genre => '', details => '', uptime => '' );
        my %link_info = ( distance => '', link_type => '' );
        
        # read next line
        my $line = <$stdout>;
        
	# masquerade detected
	if(index($line, '>> ') == 0) {
            # ...
            next
	}
	
	# parse the output line
        $line =~ s/^<([^>]+)> *//;  # timestamp
        $header{timestamp} = $1;
        
        my($src,$dest) = split(' -> ', $line);

        # source IP addr, name and port
        $src =~ s{^([\d.]+)(?:/([\w.]+))?:(\d+) +- +}{}
          and @header{qw(ip_src name_src port_src)} = ($1, $2, $3);

        # OS uptime
        $src =~ s{ \(up: (\d+) \w+\)}{}
          and $os_info{uptime} = $1;

        # OS genre and details
        $src =~ m/^(\w+) *(.*)$/
          and @os_info{qw(genre details)} = ($1, $2);

        # destination IP addr, name and port
        $dest =~ s{^([\d.]+)(?:/([\w.]+))?:(\d+) +}{}  
          and @header{qw(ip_dest name_dest port_dest)} = ($1, $2, $3);
        
        # distance information
        $dest =~ s/distance (\d+), // 
          and $link_info{distance} = $1;
        
        # link type
        $dest =~ s/\(link: (.+)\)//
          and $link_info{link_type} = $1;
        
        # replace undef values with empty strings to avoid warnings
        map { defined $header{$_}    or $header{$_}    = '' } keys %header;
        map { defined $os_info{$_}   or $os_info{$_}   = '' } keys %os_info;
        map { defined $link_info{$_} or $link_info{$_} = '' } keys %link_info;
        
        # invoque the callback
        eval {
            &$callback($self, \%header, \%os_info, \%link_info);
        };
        carp "error: The callback died with the following error: $@" and last if $@;
        
        $self->{loop}{keep_on} = 0 if ++$loops == $self->{loop}{count};
    }

    # close the filehandles, kill the child process and wait for the zombie
    close($stdin); close($stdout); close($stderr);
    kill 2, $pid;
    waitpid $pid, 0;
}

=back


=head1 DIAGNOSTICS

These messages are classified as follows (listed in increasing order of 
desperatin): 

=over 4

=item *

B<(W)> A warning, usually caused by bad user data. 

=item *

B<(E)> An error caused by external code. 

=item *

B<(F)> A fatal error caused by the code of this module. 

=back

=over 4 

=item Can't exec '%s': %s

B<(F)> This module was unable to execute the program. Detailed error follows. 

=item Please set the path to p0f with the 'program_path' option

B<(F)> You must set the C<program_path> option with the path to the p0f binary. 

=item The callback died with the following error: %s

B<(E)> As the message says, the callback function died. Its error was catched 
and follows. 

=item Unknown option '%s'

B<(W)> You called an accesor which does not correspond to a known option. 

=back


=head1 SEE ALSO

L<Net::P0f>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-net-p0f-cmdfe@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-P0f>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::P0f::Backend::CmdFE
