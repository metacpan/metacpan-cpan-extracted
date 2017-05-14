package RMI::Client::ForkedPipes;

use strict;
use warnings;
use version;
our $VERSION = qv('0.1');

use base 'RMI::Client';

use RMI::Server::ForkedPipes;
use IO::Handle;     # "thousands of lines just for autoflush" :(

RMI::Node::_mk_ro_accessors(__PACKAGE__,'peer_pid');

sub new {
    my $class = shift;
    
    my $parent_reader;
    my $parent_writer;
    my $child_reader;
    my $child_writer;
    pipe($parent_reader, $child_writer);  
    pipe($child_reader,  $parent_writer); 
    $child_writer->autoflush(1);
    $parent_writer->autoflush(1);
    
    my $parent_pid = $$;
    my $child_pid = fork();
    die "cannot fork: $!" unless defined $child_pid;
    unless ($child_pid) {
        # child process acts as a server for this test and then exits...
        close $child_reader; close $child_writer;
        
        # if a command was passed to the constructor, we exec() it.
        # this allows us to use a custom server, possibly one
        # in a different language..
        if (@_) {
            exec(@_);   
        }
        
        # otherwise, we do the servicing in Perl
        $RMI::DEBUG_MSG_PREFIX = '  ';
        my $server = RMI::Server::ForkedPipes->new(
            peer_pid => $parent_pid,
            writer => $parent_writer,
            reader => $parent_reader,
        );
        $server->run; 
        close $parent_reader; close $parent_writer;
        exit;
    }

    # parent/original process is the client which does tests
    close $parent_reader; close $parent_writer;

    my $self = $class->SUPER::new(
        peer_pid => $child_pid,
        writer => $child_writer,
        reader => $child_reader,
    );

    return $self;    
}

1;


=pod

=head1 NAME

RMI::Client::ForkedPipes - an RMI::Client implementation with a private out-of-process server

=head1 SYNOPSIS

    $c1 = RMI::Client::ForkedPipes->new();
    $remote_hash1 = $c1->call_eval('{}');
    $remote_hash1{key1} = 123;

    $c2 = RMI::Client::ForkedPipes->new('some_server',$arg1,$arg2);    

=head1 DESCRIPTION

This subclass of RMI::Client forks a child process, and starts an
RMI::Server::ForkedPipes in that process.  It is useful for testing
more complex RMI, and also to do things like use two versions of
a module at once in the same program.

=head1 METHODS

=head2 peer_pid
 
 Both the RMI::Client::ForkedPipes and RMI::Server::ForkedPipes have a method to 
 return the process ID of their remote partner.

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations of proxied objects.

=head1 SEE ALSO

B<RMI>, B<RMI::Server::ForkedPipes>, B<RMI::Client>, B<RMI::Server>, B<RMI::Node>, B<RMI::ProxyObject>

=head1 AUTHORS

Scott Smith <sakoht@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008 - 2009 Scott Smith <sakoht@cpan.org>  All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

