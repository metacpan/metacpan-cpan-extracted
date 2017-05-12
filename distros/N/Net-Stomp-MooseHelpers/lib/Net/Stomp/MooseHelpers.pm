package Net::Stomp::MooseHelpers;
$Net::Stomp::MooseHelpers::VERSION = '2.9';
{
  $Net::Stomp::MooseHelpers::DIST = 'Net-Stomp-MooseHelpers';
}

# ABSTRACT: set of helper roles and types to deal with Net::Stomp


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::MooseHelpers - set of helper roles and types to deal with Net::Stomp

=head1 VERSION

version 2.9

=head1 DESCRIPTION

This distribution provides two roles,
L<Net::Stomp::MooseHelpers::CanConnect> and
L<Net::Stomp::MooseHelpers::CanSubscribe>, that you can consume in
your classes to simplify connecting and subscribing via Net::Stomp.

C<Net::Stomp::MooseHelpers::CanConnect> can be paired with
L<Net::Stomp::MooseHelpers::TraceStomp> to dump every frame to disk,
or with L<Net::Stomp::MooseHelpers::TraceOnly> to never touch the
network. L<Net::Stomp::MooseHelpers::ReadTrace> provides functions to
read back the dumped frames.

We also provide some types (L<Net::Stomp::MooseHelpers::Types>) and
exception classes (L<Net::Stomp::MooseHelpers::Exceptions>).

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
