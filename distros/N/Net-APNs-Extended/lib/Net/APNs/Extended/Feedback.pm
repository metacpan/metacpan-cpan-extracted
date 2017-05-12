package Net::APNs::Extended::Feedback;

use strict;
use warnings;
use parent 'Net::APNs::Extended::Base';

my %default = (
    host_production => 'feedback.push.apple.com',
    host_sandbox    => 'feedback.sandbox.push.apple.com',
    is_sandbox      => 0,
    port            => 2196,
);

sub new {
    my ($class, %args) = @_;
    $class->SUPER::new(%default, %args);
}

sub retrieve_feedback {
    my $self = shift;
    my $data = $self->_read;

    my $res = [];
    while ($data) {
        my ($time_t, $token_bin);
        ($time_t, $token_bin, $data) = unpack 'N n/a a*', $data;
        push @$res, {
            time_t    => $time_t,
            token_bin => $token_bin,
            token_hex => unpack 'H*', $token_bin,
        };
    }

    return $res;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::APNs::Extended::Feedback - Client library for APNs feedback service

=head1 SYNOPSIS

  use Net::APNs::Extended::Feedback;

  my $feedback = Net::APNs::Extended::Feedback->new(
      is_sandbox => 1,
      cert_file   => 'xxx',
  );

  my $feedbacks = $feedback->retrieve_feedback;
  # [
  #   {
  #     time_t    => ...,
  #     token_bin => ...,
  #     token_hex => ...,
  #   },
  #   {
  #     time_t    => ...,
  #     token_bin => ...,
  #     token_hex => ...,
  #   },
  #   ...
  # ]

=head1 METHODS

=head2 new(%args)

Create a new instance of C<< Net::APNs::Extended::Feedback >>.

Supported args same as L<< Net::APNs::Extended >>.

=head2 retrieve_feedback()

This method is receive the feedback from APNs.

 my $feedbacks = $feedback->retrieve_feedback;

=head1 AUTHOR

xaicron E<lt>xaicron {@} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
