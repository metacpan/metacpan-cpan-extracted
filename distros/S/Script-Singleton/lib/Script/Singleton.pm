package Script::Singleton;

use strict;
use warnings;

use Cwd qw(abs_path);
use IPC::Shareable;

our $VERSION = '0.03';

sub import {
    my ($class, %params) = @_;

    $params{glue} = abs_path((caller())[1]) if ! exists $params{glue};

    IPC::Shareable->singleton($params{glue}, $params{warn});
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

    use Script::Singleton; # Yep, that's it!

=head1 DESCRIPTION

Using shared memory, this distribution ensures only a single instance of any
script can be running at any one time.

There are no functions or methods. All the work is performed in the B<use>
line.

This software uses L<IPC::Shareable> for the shared memory management,
specifically its B<singleton()> method.

=head1 EXAMPLES

=head2 Basic

    use Script::Singleton;

Using it in the default, basic fashion, we'll create an IPC identifier (glue)
using the full path and name of the calling script. We also won't output any
warnings if a second instance of the script attempts to run before the initial
run has completed and released the lock.

=head2 Custom glue

    use Script::Singleton glue => 'UNIQUE GLUE STRING';

That will use B<UNIQUE GLUE STRING> as the IPC glue. The B<glue> parameter can
be used in conjunction with the B<warn> parameter.

=head2 Warnings

    use Script::Singleton warn => 1;

If the C<warn> parameter is sent in with a true value, we'll emit a warning
if a second instance of the script is run. The B<warn> parameter can be used
in conjunction with the B<glue> parameter.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
