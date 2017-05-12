package Mojo::Log::Clearable;

use Mojo::Base 'Mojo::Log';
use Class::Method::Modifiers ();

our $VERSION = '0.003';

sub clear_handle { delete shift->{handle} };
Class::Method::Modifiers::before 'path' => sub { $_[0]->clear_handle if @_ > 1 };

=head1 NAME

Mojo::Log::Clearable - Mojo::Log with clearable log handle

=head1 SYNOPSIS

 use Mojo::Log::Clearable;
 my $log = Mojo::Log::Clearable->new(path => $path1);
 $log->info($message); # Logged to $path1
 $log->path($path2);
 $log->debug($message); # Logged to $path2
 $log->path(undef);
 $log->warn($message); # Logged to STDERR
 
 # Reopen filehandle after logrotate (if logrotate sends SIGUSR1)
 $SIG{USR1} = sub { $log->clear_handle };

=head1 DESCRIPTION

L<Mojo::Log> is a simple logger class. It holds a filehandle once it writes to
a log, and changing L</"path"> does not open a new filehandle for logging.
L<Mojo::Log::Clearable> subclasses L<Mojo::Log> to provide a L</"clear_handle">
method and to automatically call it when setting L</"path"> so the logging
handle is reopened at the new path. The L</"clear_handle"> method can also be
used to reopen the logging handle after logrotate.

=head1 EVENTS

L<Mojo::Log::Clearable> inherits all events from L<Mojo::Log>.

=head1 ATTRIBUTES

L<Mojo::Log::Clearable> inherits all attributes from L<Mojo::Log> and
implements the following new ones.

=head2 path

 my $path = $log->path;
 $log     = $log->path('/var/log/mojo.log');

Log file path used by L<Mojo::Log/"handle">. Reopens the handle when set.

=head1 METHODS

L<Mojo::Log::Clearable> inherits all methods from L<Mojo::Log> and implements
the following new ones.

=head2 clear_handle

 $log->clear_handle;

Clears L<Mojo::Log/"handle"> attribute, it will be reopened from the L</"path">
attribute when next accessed.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it undef
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Log>

=cut

1;
