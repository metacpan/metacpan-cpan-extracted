package Mojo::Log::Clearable;

use Mojo::Base 'Mojo::Log';
use Role::Tiny::With;

our $VERSION = '1.000';

with 'Mojo::Log::Role::Clearable';

1;

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

L<Mojo::Log::Clearable> is a subclass of L<Mojo::Log> that applies the
L<Mojo::Log::Role::Clearable> role. See that role's documentation for details.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it undef
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Log>, L<Mojo::Log::Role::Clearable>
