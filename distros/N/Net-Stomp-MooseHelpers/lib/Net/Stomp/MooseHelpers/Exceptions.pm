package Net::Stomp::MooseHelpers::Exceptions;
$Net::Stomp::MooseHelpers::Exceptions::VERSION = '2.9';
{
  $Net::Stomp::MooseHelpers::Exceptions::DIST = 'Net-Stomp-MooseHelpers';
}
# ABSTRACT: exception classes for Net::Stomp::MooseHelpers


{
package Net::Stomp::MooseHelpers::Exceptions::Stringy;
$Net::Stomp::MooseHelpers::Exceptions::Stringy::VERSION = '2.9';
{
  $Net::Stomp::MooseHelpers::Exceptions::Stringy::DIST = 'Net-Stomp-MooseHelpers';
}
use Moose::Role;
use MooseX::Role::WithOverloading;
use overload
    q{""}    => 'as_string',
        fallback => 1;
requires 'as_string';
}
{
package Net::Stomp::MooseHelpers::Exceptions::Stomp;
$Net::Stomp::MooseHelpers::Exceptions::Stomp::VERSION = '2.9';
{
  $Net::Stomp::MooseHelpers::Exceptions::Stomp::DIST = 'Net-Stomp-MooseHelpers';
}
use Moose;with 'Throwable','Net::Stomp::MooseHelpers::Exceptions::Stringy';
use namespace::autoclean;
has '+previous_exception' => (
    init_arg => 'stomp_error',
);
sub as_string {
    return 'STOMP protocol/network error:'.$_[0]->previous_exception;
}
__PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::MooseHelpers::Exceptions - exception classes for Net::Stomp::MooseHelpers

=head1 VERSION

version 2.9

=head1 DESCRIPTION

This file defines the following exception classes:

=over 4

=item C<Net::Stomp::MooseHelpers::Exceptions::Stringy>

Exception I<role> to overload stringification delegating it to a
C<as_string> method.

=item C<Net::Stomp::MooseHelpers::Exceptions::Stomp>

Thrown whenever the STOMP library (usually L<Net::Stomp>) dies; has a
C<previous_exception> attribute containing the exception that the
library threw.

=back

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
