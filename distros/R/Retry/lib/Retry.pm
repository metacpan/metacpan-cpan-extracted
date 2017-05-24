package Retry;
use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw( Int CodeRef );

our $VERSION = '1.03';

=head1 NAME

Retry

=head1 SYNOPSIS

A one-feature module, this provides a method to wrap any function in automatic
retry logic, with exponential back-off delays, and a callback for each time an
attempt fails.

Example:

  use Retry;
  use Try::Tiny;
  use LWP::UserAgent;

  my $code_to_retry = sub {
    my $r = LWP::UserAgent->new->get("http://example.com");
    die $r->status_line unless $r->is_success;
    return $r;
  };

  my $agent = Retry->new(
    # This callback is optional:
    failure_callback => sub { warn "Transient error: " . $_[0]; },
  );

  try {
    $agent->retry($code_to_retry)
  }
  catch {
    warn "All attempts failed: $_";
  };

=head1 ATTRIBUTES

=cut

=head2 retry_delay

This is the initial delay used when the routine failed, before retrying again.

Every subsequent failure doubles the amount.

It defaults to 8 seconds.

=cut

has 'retry_delay' => (
    is => 'rw',
    isa => Int,
    default => 8
);

=head2 max_retry_attempts

The maximum number of retries we should attempt before giving up completely.

It defaults to 5.

=cut

has 'max_retry_attempts' => (
    is => 'rw',
    isa => Int,
    default => 5,
);

=head2 failure_callback

Optional. To be notified of *every* failure (even if we eventually succeed on a
later retry), install a subroutine callback here.

For example:

  Retry->new(
      failure_callback => sub { warn "failed $count++ times" }
  );

=cut

has 'failure_callback' => (
    is => 'rw',
    isa => CodeRef,
    default => sub { sub {} }, # The way of the Moose is sometimes confusing.
);

=head1 METHODS

=head2 retry

Its purpose is to execute the passed subroutine, over and over, until it
succeeds, or the number of retries is exceeded. The delay between retries
increases exponentially. (Failure is indicated by the sub dying)

If the subroutine succeeds, then its scalar return value will be returned by
retry.

For example, you could replace this:

  my $val = unreliable_web_request();

With this:

   my $val = Retry->new->retry(
       sub { unreliable_web_request() }
   );

=cut

sub retry {
    my ($self, $sub) = @_;

    my $delay = $self->retry_delay;
    my $retries = $self->max_retry_attempts;

    while () {
        my $result = eval { $sub->() };
        return $result unless $@;
        my $error = $@;
        $self->failure_callback->($error);

        die($error) unless $retries--;

        sleep($delay);
        $delay *= 2;
    }
}

=head1 AUTHOR

Toby Corkindale -- L<https://github.com/TJC/>

=head1 LICENSE

This module is released under the Perl Artistic License 2.0: L<http://www.perlfoundation.org/artistic_license_2_0>

It is based upon source code which is Copyright 2010 Strategic Data Pty Ltd,
however it is used and released with permission.

=head1 SEE ALSO

L<Attempt>

Retry differs from Attempt in having exponentially increasing delays, and by
having a callback inbetween attempts.

However L<Attempt> has a simpler syntax.

=cut

1;
