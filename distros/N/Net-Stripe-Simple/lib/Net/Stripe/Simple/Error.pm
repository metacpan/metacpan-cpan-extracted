package Net::Stripe::Simple::Error;
$Net::Stripe::Simple::Error::VERSION = '0.005';
# ABSTRACT: general error class for Net::Stripe::Simple


use parent 'Net::Stripe::Simple::Data';


sub trace { shift->{_trace}->as_string }

use overload '""' => sub {
    my $e = shift;
    my ( $type, $message ) = @$e{qw(type message)};
    $message = '[no message]' unless length( $message // '' );
    $type    = 'unknown'      unless length( $type    // '' );
    my $msg = sprintf 'Error: %s - %s', $type, $message;
    $msg .= " On parameter: " . $e->{param} if exists $e->{param};
    $msg .= "\n\tCode: " . $e->{code}       if exists $e->{code};
    return $msg;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stripe::Simple::Error - general error class for Net::Stripe::Simple

=head1 DESCRIPTION

This is a subclass of L<Net::Stripe::Simple::Data>. It has no constructor but
rather is constructed by L<Net::Stripe::Simple>. It is guaranteed to have a
C<_trace> parameter.

It's stringification method differs from its parent's in that it stringifies to
a concatenation of its message and type and will report its param and code
attributes if these are available. The default stringification, for an error
with no specified message or type, is

Error: unknown - [no message]

The general stringification pattern is

  sprintf 'Error: %s - %s', $type, $message;

with 'unknown' reported as the type when the type is unspecified and
'[no message]' as the message.

=head1 NAME

Net::Stripe::Simple::Error - general error class for Net::Stripe::Simple

=head1 METHODS

=head2 trace

Returns the stringification of the C<_trace> parameter, which is a
L<Devel::StackTrace> trace which omits frames in L<Net::Stripe::Simple>.

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

David F. Houghton <dfhoughton@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

David F. Houghton <dfhoughton@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
