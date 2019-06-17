package Net::AS2::HTTP;

use strict;
use warnings;
our $VERSION = '1.0110'; # VERSION

=head1 NAME

Net::AS2::HTTP - UserAgent used for sending AS2 requests over HTTP.

=head1 SYNOPSIS

    my $as2 = Net::AS2->new(
        ...,
        UserAgentClass => 'Net::AS2::HTTP',
    );

=head1 DESCRIPTION

This is a class for sending AS2 (RFC-4130) communication over HTTP.

It is a subclass of L<LWP::UserAgent>.

=head1 METHODS

=cut

use parent 'LWP::UserAgent';

use Carp;

use constant TIMEOUT => 30;

=over 4

=item new ( opts )

Create a User Agent configured with the given C<opts> hash ref.
The C<opts> hash ref is passed to the C<options()> method which returns
the list of options to create the User Agent for this class.

=cut

sub new {
    my ($class, $opts) = @_;

    my @options = $class->options($opts);

    return $class->SUPER::new(@options);
}

=item options ( opts )

The given C<opts> hash ref is validated by this method.

The method then returns a list of options that the C<new()> method
uses to instantiate the object.

=cut

sub options {
    my ($class, $opts) = @_;

    my $timeout = $opts->{Timeout} // TIMEOUT;

    croak "Timeout is invalid: $timeout" if $timeout !~ /^[0-9]+$/;

    my $agent = $opts->{UserAgent} // "Perl AS2/$Net::AS2::VERSION";

    return (
        agent   => $agent,
        timeout => $timeout,
    );
}

=back

=cut

1;
