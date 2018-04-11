package PGObject::Util::AsyncPool;

use 5.010;
use strict;
use warnings;
use Carp;

use DBD::Pg ':async';

=head1 NAME

PGObject::Util::AsyncPool - An Async Connection Pooler for PGObject

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module provides a basic, simple async connection pool PostgreSQL applications.

It can be used with or without the rest of the PGObject framework.

    my $pool = PGObject::Util::AsyncPool->new($connstring, 
                                              $username, 
                                              $password, 
                                              {RaiseError => 0},
                                              {pollfreq => 5, maxconns => 5},
                                             );
    my $callback = sub { my $sth = shift; say STDERR $sth->rows; };

    for my $query (@queries){
        $pool->run($query, $callback);
    }
    $pool->poll;
    ...
    $pool->poll_loop; # blocks until all queries done

=head1 CONSTRUCTOR SYNTAX

=head2 PGObject::Util::AsyncPool->new($connstr, $user, $pass, $dbiopts, $poolopts)

The first three arguments are passed to the DBI->connect clause directly.

The dbiopts has Autocommit overridden to avoid unpredictable behavior with statement
dependencies.  Explicit transactions are not supported in this module.

The poolopts argument configures the connection pool.  Currently there are two supported
arguments:

=over

=item maxconns

Sets the maximum number of connections used.  Connections are created lazily until this limit
is reached.  The default is 1.

=item pollfreq

Sets the amount of time to sleep (in seconds) in the poll_loop function between pollings.

The default is 1.

=back

=cut

sub new {
     my ($class, $connstr, $user, $pass, $dbiopts, $poolopts) = @_;
     $poolopts //= {};
     $dbiopts //= {};
     croak 'If supplied, dbi options must be a hashref' unless ref $dbiopts eq 'HASH';
     croak 'If supplied, db pool options must be a hashref' unless ref $poolopts eq 'HASH';
     $dbiopts = {%$dbiopts, AutoCommit => 1};
     my $self = {  
          # defaults
          maxconns => 1,
          pollfreq => 1,

          # overrides
          %$poolopts,

          # internal state
          conns => [],
          queue => [],
          _new_con => sub { DBI->connect($connstr, $user, $pass, $dbiopts) },
          
     };
     return bless $self, $class;
}

=head1 METHODS

=head2 run($query, $callback, [$args])

Queues the query for running as soon as possible.  Queries are started on a FIFO basis
but no guarantees are made as to what other queries have finished.

Queuing queries begins with a polling call so connections may be reused if a lot of fast
are run.  This is necessary to avoid conditions where we might queue up lots of queries
without checking to see what has finished running first.

=cut

sub run {
    my ($self, $query, $callback, $args) = @_;
    croak "Query must be supplied" unless $query;
    $callback //= sub { return };
    croak "Callback must be undef or a coderef" unless (ref $callback // '') eq 'CODE';
    $args //= [];
    croak "Args must be omitted or an arrayref" unless (ref $args // '') eq 'ARRAY';

    if ($self->poll < $self->{maxconns}){
        my $conn = $self->_get_or_create;
        _run($conn, { query => $query, callback => $callback, args => $args});
    } else {
        $self->_queue({query => $query, callback => $callback, args => $args});
    }
    return;
}

sub _queue {
    my ($self, $obj) = @_;
    push @{$self->{queue}}, $obj;
}

sub _dequeue {
    my ($self) = @_;
    return shift @{$self->{queue}};
}

sub _get_or_create {
    my ($self) = @_;
    my $conn;
    for (@{$self->{conns}}){
        return $_ if !$_->{active};
    }
    my $cnx = $self->{_new_con}->();
    my $cnx_hash = {
       conn => $cnx,
       current_query => undef,
       active => 0,
       sth => undef,
       callback => undef
   };
   push @{$self->{conns}}, $cnx_hash;
   return $cnx_hash;
}

sub _run {
    my ($cnx, $obj) = @_;
    $cnx->{current_query} = $obj->{query};
    $cnx->{active} = 1;
    $cnx->{sth} = $cnx->{conn}->prepare($obj->{query}, {pg_async => PG_ASYNC});
    $cnx->{callback} = $obj->{callback};
    $cnx->{sth}->execute(@{$obj->{args}});
}
    
sub _finish {
    my ($cnx) = @_;
    local $@;
    eval { $cnx->{conn}->pg_result };
    $cnx->{active} = 0;
    $cnx->{callback}->($cnx->{sth});
}


=head2 int $pool->poll

=cut

sub poll {
    my ($self) = @_;
    for (@{$self->{conns}}){
        next unless defined $_->{sth};
        next unless (!$_->{active} || $_->{sth}->pg_ready());
        _finish($_) if $_->{active};
        if (@{$self->{queue}}){
           _run($_, $self->_dequeue);
        }
    }
    my $count = grep { $_->{active} } @{$self->{conns}};
    return $count // 0;
}

=head2 poll_loop

While there are still running queries, runs through a periodic polling.

This blocks until all queued queries have completed.

=cut

sub poll_loop {
    my ($self) = @_;
    while ($self->poll > 0){
         sleep $self->{pollfreq} || 1;
    }
}

=head1 CALLBACKS

=head1 AUTHOR

Chris Travers, C<< <chris.travers at adjust.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-asyncpool at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-AsyncPool>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::AsyncPool


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-AsyncPool>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-AsyncPool>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-AsyncPool>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-AsyncPool/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Chris Travers.

This program is distributed under the (Simplified) BSD License:
L<http://www.opensource.org/licenses/BSD-2-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::AsyncPool
