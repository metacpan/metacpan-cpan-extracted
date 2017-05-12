package Proc::Launcher::Roles::Launchable;
use strict;
use warnings;

our $VERSION = '0.0.37'; # VERSION

use Moo::Role;

requires 'start';
requires 'stop';
#requires 'restart';
requires 'force_stop';

requires 'is_running';



1;

__END__

=head1 NAME

Proc::Launcher::Roles::Launchable - defines an interface for launchers


=head1 VERSION

version 0.0.37

=head1 SYNOPSIS

    use Moo;
    with 'Proc::Launcher::Roles::Launchable';

=head1 DESCRIPTION

This role enforces a consistent API for the various 'Launcher'
modules.  In the current project, that includes:

- L<Proc::Launcher> - manage a single local process

- L<Proc::Launcher::Manager> - manage multiple local processes

Also under development are:

- L<GRID::Launcher> - manage a single process on a remote node

- L<GRID::Launcher::Manager> - manage one or more processes on one or more remote nodes


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, VVu@geekfarm.org
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
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
