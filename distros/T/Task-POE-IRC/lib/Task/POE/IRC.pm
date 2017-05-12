package Task::POE::IRC;
$Task::POE::IRC::VERSION = '1.14';
#ABSTRACT: Task to install all POE related IRC modules.

use strict;
use warnings;

qq[Tasky McTaskIRC];

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::POE::IRC - Task to install all POE related IRC modules.

=head1 VERSION

version 1.14

=head1 SYNOPSIS

    perl -MCPANPLUS -e 'install Task::POE::IRC'

=head1 DESCRIPTION

Task::POE::IRC - L<Task> to install all L<POE> related IRC modules and optional dependencies.

  POE 1.003

  POE::Component::Client::DNS 1.00

  POE::Component::IRC 5.88

  POE::Component::Server::IRC 1.32

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
