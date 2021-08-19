package Script::Singleton;

use strict;
use warnings;

use Carp qw(croak);
use IPC::Shareable;

our $VERSION = '0.02';

sub import {
    my ($class, $glue, $warn) = @_;

    if (! defined $glue) {
        croak "Usage: use Script::Singleton GLUE;";
    }

    IPC::Shareable->singleton($glue, $warn);
}

sub __placeholder {}

1;
__END__

=head1 NAME

Script::Singleton - Ensure only a single instance of a script can run

=for html
<a href="https://github.com/stevieb9/script-singleton/actions"><img src="https://github.com/stevieb9/script-singleton/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/script-singleton?branch=master'><img src='https://coveralls.io/repos/stevieb9/script-singleton/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

    use Script::Singleton 'LOCK';

=head1 DESCRIPTION

Using shared memory, this distribution ensures only a single instance of any
script can be running at any one time.

    use Script::Singleton 'UNIQUE LOCK STRING', 1;

There are no functions or methods. All the work is performed in the B<use>
line. C<UNIQUE LOCK STRING> is the glue that identifies the shared memory segment.
If a second parameter with a true value is sent in, we'll output a warning if
the same script is run at the same time and it exits:

This software uses L<IPC::Shareable> for the shared memory management,
specifically its B<singleton()> method.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
