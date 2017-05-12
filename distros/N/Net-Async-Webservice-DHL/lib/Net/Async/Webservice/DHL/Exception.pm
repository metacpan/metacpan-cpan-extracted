package Net::Async::Webservice::DHL::Exception;
use strict;
use warnings;
our $VERSION = '1.2.2'; # VERSION

# ABSTRACT: exception classes for DHL


{package Net::Async::Webservice::DHL::Exception::ConfigError; ## no critic(ProhibitMultiplePackages)
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';


 has file => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return 'Bad config file: %s, at %s',
         $self->file,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::DHL::Exception::DHLError; ## no critic(ProhibitMultiplePackages)
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';


 has error => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     my $c = $self->error->{Condition}[0];

     return sprintf 'DHL returned an error: %s, code %s, at %s',
         $c->{ConditionData}//'<undef>',
         $c->{ConditionCode}//'<undef>',
         $self->stack_trace->as_string;
 }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Exception - exception classes for DHL

=head1 VERSION

version 1.2.2

=head1 DESCRIPTION

These classes are based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.  Their base class is
L<Net::Async::Webservice::Common::Exception>.

=head1 Classes

=head2 C<Net::Async::Webservice::DHL::Exception::ConfigError>

exception thrown when the configuration file can't be parsed

=head3 Attributes

=head4 C<file>

The name of the configuration file.

=head3 Methods

=head4 C<as_string>

Mentions the file name, and gives the stack trace.

=head2 C<Net::Async::Webservice::DHL::Exception::DHLError>

exception thrown when DHL signals an error

=head3 Attributes

=head4 C<error>

The error data structure extracted from the DHL response.

=head3 Methods

=head4 C<as_string>

Mentions the description and code of the error, plus the stack trace.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
