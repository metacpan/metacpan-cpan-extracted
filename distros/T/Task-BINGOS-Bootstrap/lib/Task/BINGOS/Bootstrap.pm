package Task::BINGOS::Bootstrap;
$Task::BINGOS::Bootstrap::VERSION = '0.04';
#ABSTRACT: Bootstrap CPANPLUS with cpanm like BINGOS does

use strict;
use warnings;

qq[smoky smoke box foo]

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::BINGOS::Bootstrap - Bootstrap CPANPLUS with cpanm like BINGOS does

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  cpanm Task::BINGOS::Bootstrap

=head1 DESCRIPTION

Task::BINGOS::Bootstrap is a L<Task> that installs all the modules that I need to start using L<CPANPLUS>.
I use L<App::cpanminus> to do the bootstrapping then switch to L<CPANPLUS>.

The following things will be installed:

  CPANPLUS

  CPANPLUS::Internals::Source::CPANIDX

  Test::Reporter::Transport::Socket

  CPANPLUS::YACSmoke

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
