package Net::AS2::HTTPS;

use strict;
use warnings;
our $VERSION = '1.0110'; # VERSION

use parent 'Net::AS2::HTTP';

=head1 NAME

Net::AS2::HTTPS - UserAgent used for sending AS2 requests over HTTPS.

=head1 SYNOPSIS

    my $as2 = Net::AS2->new(
        ...,
        UserAgentClass => 'Net::AS2::HTTPS',
        SSLOptions     => {
            ...
        }
    );

=head1 DESCRIPTION

This is a class for sending AS2 (RFC-4130) communication over HTTPS.

It is a subclass of L<Net::AS2::HTTP>.

It requires the AS2 option C<SSLOptions> to be defined.  This will be
passed to the C<ssl_opts()> method of the superclass,
L<LWP::UserAgent>.

=cut

use Carp;

=head1 METHODS

=over 4

=item options ( opts )

A subclassed method that uses the C<SSLOptions> AS2 configuration
option to configure the User Agent to use HTTPS.

=cut

sub options {
    my ($class, $opts) = @_;

    my $ssl_opts = $opts->{SSLOptions} or croak "SSLOptions is required";

    my @options = $class->SUPER::options($opts);

    push @options, ssl_opts => $ssl_opts;

    return @options;
}

=back

=head1 PREREQUISITES

Note that the L<LWP::Protocol::https> will be required for
L<LWP::UserAgent> to use HTTPS.

=cut

1;
