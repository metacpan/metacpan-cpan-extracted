package Task::POE::Simple::TCPIP::Services;
$Task::POE::Simple::TCPIP::Services::VERSION = '1.10';
#ABSTRACT: A Task to install all POE simple TCP/IP services modules.

use strict;
use warnings;

'Simples';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::POE::Simple::TCPIP::Services - A Task to install all POE simple TCP/IP services modules.

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    perl -MCPANPLUS -e 'install Task::POE::Simple::TCPIP::Services'

=head1 DESCRIPTION

Task::POE::Simple::TCPIP::Services will install all the L<POE> modules that provide what
Microsoft Windows terms "Simple TCP/IP Services", namely:

  Quote of the Day Protocol
  Daytime Protocol
  Character Generator Protocol
  Echo Protocol
  Discard Protocol

The following modules will be installed:

  POE 1.0001

  POE::Component::Server::Echo 1.60

  POE::Component::Server::Chargen 1.10

  POE::Component::Server::Discard 1.10

  POE::Component::Server::Daytime 1.10

  POE::Component::Server::Qotd 1.10

  POE::Component::Server::Time 1.10

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
