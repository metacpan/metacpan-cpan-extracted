package Proc::Forkmap;
use POSIX qw(:sys_wait_h);
use Proc::Fork;
use Carp;
use IO::Pipe;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.024';


sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->_init;
    return $self;
}


sub _init {
    my $self = shift;
    ($self->{max_kids} //= 2) =~ /^[1-9]+$/
        or croak "max_kids value error";
    $self->{ipc} //= 0; #ipc off by default        
}                          


sub max_kids {
    my ($self,$n) = @_;
    $n // return $self->{max_kids};
    ($n =~ /^[1-9]+$/)
        or croak "max_kids value error";
    $self->{max_kids} = $n;
}


sub ipc {
    my ($self,$n) = @_;
    $n // return $self->{ipc};
    $self->{ipc} = $n;
}


sub fmap {
    my ($self,$code) = (shift,shift);
    my %pids = ();
    my @rs = (); #result set of child return values
    my $max = $self->max_kids;
    my $ipc = $self->ipc;
    for my $proc (@_) {
        my $pipe = $ipc ? IO::Pipe->new : {}; #put this in your pipe, and smoke it
        #max kids?
        while ($max == keys %pids) {
            #free a spot in queue when a process completes
            for my $pid (keys %pids) {
                if (my $kid = waitpid($pid, WNOHANG)) {
                    delete $pids{$kid};
                    last;
                }
            }
        }
        
        run_fork { #processes fork here
            parent {
                $| = 1;
                my $kid = shift;
                $pids{$kid}++;
                if ($ipc) {
                    $pipe->reader();
                    while(<$pipe>) {
                        push @rs,$_;
                    }
                }
            }
            child {
                $| = 1;
                my $rs = $code->($proc);
                if ($ipc) {
                    $pipe->writer();
                    print $pipe $rs if defined $rs;
                }
                exit;
            }
            error {
                die "error: couldn't fork";
            }
        };
    }
    
    1 while (wait() != -1); #wait for the stragglers to finish
    return @rs;
}




1;

__END__
=head1 NAME

Proc::Forkmap - map with forking and IPC

=head1 SYNOPSIS

EXAMPLES:
    
    sub foo {
        my ($x,$n) = (shift,1);
        $n *= $_ for (@$x);
        say $n;
    }
    
    @x = ([1..99],[100..199],[200..299]);
    my $p = Proc::Forkmap->new;
    $p->fmap(\&foo,@x);
    
    or,
    
    package Foo;
    
    sub new { return bless {}, shift};
    sub bar { #do heavy calc stuff and max a CPU };
    
    package main;
    
    my $foo = Foo->new;
    my @rs = Proc::Forkmap->new(max_kids => 4, ipc=> 1)->fmap(
        sub { $foo->bar(@_) }, @x,
    );
    
    or,
    
    my @rs = $p->fmap(sub { $_[0] ** $_[0] }, @x);
    
    or,
    
    #get stuff from the intertubes
    
    sub bar {
       my $t = shift;
       my $s = Stock::Price->new;
       ... get historical stock prices ...
       ... do some analysis ...
       baz($t,$sell_price);
    }
    
    #then save stuff to a data store
    
    sub baz {
       my ($t,$price) = @_;
       my $conn = MongoDB::Connection->new;
       my $bayes = $conn->stock->bayes;
       $bayes->insert({symbol => $t, price => $price});
       $conn->disconnect;
    }
    
    my $p = Proc::Forkmap->new(max_kids => 4);
    $p->fmap(\&bar,qw/rht goog ^ixic ^dji yhoo aapl/);

=head1 DESCRIPTION

This module supplies an easy to use map method that provides built-in forking and IPC.

=head1 METHODS

=head2 new

    my $p = Proc::Forkmap->new(max_kids => 4, ipc => 1);

=over 4

=item B<max_kids>

Maximum number of kids allowed in the pool. The default is 2.

=item B<ipc>

Set IPC on (blocking)/off state. IPC is off by default.

=back

=head2 icp

    $p->ipc(1)

Turn on/off inter-process communication.

=head2 max_kids

    $p->max_kids(4);

max_kids setter/getter.

=head2 fmap

    my @rs = $p->fmap(\&foo,@x);

This method takes a coderef and an array. If IPC is turned on, it will return,
via IO::Pipe, a result set. Otherwise, it will continue on its merry way until
either an error occurs that prevents a fork or all the subprocesses complete
their tasks.

=head1 SEE ALSO

L<Proc::Fork>, L<IO::Pipe>

=head1 AUTHOR

Andrew Shapiro, C<< <trski@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-forkmap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-Forkmap>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Andrew Shapiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
