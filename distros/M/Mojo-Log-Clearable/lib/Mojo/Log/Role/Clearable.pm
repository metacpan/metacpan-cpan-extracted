package Mojo::Log::Role::Clearable;

use Role::Tiny;

our $VERSION = '1.000';

requires 'handle', 'path';
sub clear_handle { delete shift->{handle} }
before 'path' => sub { $_[0]->clear_handle if @_ > 1 };

1;

=head1 NAME

Mojo::Log::Role::Clearable - Role for Mojo::Log with clearable log handle

=head1 SYNOPSIS

 use Mojo::Log;
 my $log = Mojo::Log->with_roles('+Clearable')->new(path => $path1);
 $log->info($message); # Logged to $path1
 $log->path($path2);
 $log->debug($message); # Logged to $path2
 $log->path(undef);
 $log->warn($message); # Logged to STDERR
 
 # Reopen filehandle after logrotate (if logrotate sends SIGUSR1)
 $SIG{USR1} = sub { $log->clear_handle };
 
 # Apply to an existing Mojo::Log object
 $app->log->with_roles('+Clearable');

=head1 DESCRIPTION

L<Mojo::Log> is a simple logger class. It holds a filehandle once it writes to
a log, and changing L<Mojo::Log/"path"> does not open a new filehandle for
logging. L<Mojo::Log::Role::Clearable> is a role that provides a
L</"clear_handle"> method and automatically calls it when L<Mojo::Log/"path">
is modified, so the logging handle is reopened at the new path. The
L</"clear_handle"> method can also be used to reopen the logging handle after
logrotate.

=head1 ATTRIBUTES

L<Mojo::Log::Role::Clearable> augments the following attributes.

=head2 path

 $log = $log->path('/var/log/mojo.log'); # "handle" is now cleared

Log file path as in L<Mojo::Log/"path">. Augmented to call
L</"clear_handle"> when modified.

=head1 METHODS

L<Mojo::Log::Role::Clearable> composes the following methods.

=head2 clear_handle

 $log->clear_handle;

Clears L<Mojo::Log/"handle"> attribute, it will be reopened from the
L<Mojo::Log/"path"> attribute when next accessed.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it undef
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Log>, L<Mojo::Log::Clearable>
