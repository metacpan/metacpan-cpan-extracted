package Plack::Handler::Stomp::Exceptions;
$Plack::Handler::Stomp::Exceptions::VERSION = '1.13';
{
  $Plack::Handler::Stomp::Exceptions::DIST = 'Plack-Handler-Stomp';
}
use Net::Stomp::MooseHelpers::Exceptions;

# ABSTRACT: exception classes for Plack::Handler::Stomp


{
package Plack::Handler::Stomp::Exceptions::UnknownFrame;
$Plack::Handler::Stomp::Exceptions::UnknownFrame::VERSION = '1.13';
{
  $Plack::Handler::Stomp::Exceptions::UnknownFrame::DIST = 'Plack-Handler-Stomp';
}
use Moose;with 'Throwable','Net::Stomp::MooseHelpers::Exceptions::Stringy';
use namespace::autoclean;
has frame => ( is => 'ro', required => 1 );

sub as_string {
    sprintf q{Received a STOMP frame we don't know how to handle (%s)},
        shift->frame->command;
}
__PACKAGE__->meta->make_immutable;
}

{
package Plack::Handler::Stomp::Exceptions::AppError;
$Plack::Handler::Stomp::Exceptions::AppError::VERSION = '1.13';
{
  $Plack::Handler::Stomp::Exceptions::AppError::DIST = 'Plack-Handler-Stomp';
}
use Moose;with 'Throwable','Net::Stomp::MooseHelpers::Exceptions::Stringy';
use namespace::autoclean;
has '+previous_exception' => (
    init_arg => 'app_error',
);
sub as_string {
    return 'The application died:'.$_[0]->previous_exception;
}
__PACKAGE__->meta->make_immutable;
}

{
package Plack::Handler::Stomp::Exceptions::OneShot;
$Plack::Handler::Stomp::Exceptions::OneShot::VERSION = '1.13';
{
  $Plack::Handler::Stomp::Exceptions::OneShot::DIST = 'Plack-Handler-Stomp';
}
use namespace::autoclean;
use Moose;with 'Throwable';
__PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Handler::Stomp::Exceptions - exception classes for Plack::Handler::Stomp

=head1 VERSION

version 1.13

=head1 DESCRIPTION

This file defines the following exception classes:

=over 4

=item C<Plack::Handler::Stomp::Exceptions::UnknownFrame>

Thrown whenever we receive a frame we don't know how to handle; has a
C<frame> attribute containing the frame in question.

=item C<Plack::Handler::Stomp::Exceptions::AppError>

Thrown whenever the PSGI application dies; has a C<previous_exception>
attribute containing the exception that the application threw.

=item C<Plack::Handler::Stomp::Exceptions::OneShot>

Thrown to stop the C<run> loop after receiving a message, if
C<one_shot> is true (see L<Plack::Handler::Stomp/run>).

=back

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
