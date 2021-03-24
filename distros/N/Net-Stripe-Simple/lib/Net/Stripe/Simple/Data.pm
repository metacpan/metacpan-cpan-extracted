package Net::Stripe::Simple::Data;
$Net::Stripe::Simple::Data::VERSION = '0.005';
# ABSTRACT: collection of methods to augment a JSON hash


use v5.10;
use strict;
use warnings;

use Scalar::Util qw(refaddr);

use overload '""' => sub {
    my $self = shift;
    return $self->{id} if exists $self->{id};
    return __PACKAGE__ . sprintf '=HASH(0x%x)', refaddr $self;
};

use overload 'cmp' => sub {
    my ( $left, $right, $reversed ) = @_;
    my $v = "$left" cmp "$right";
    return $reversed ? -$v : $v;
};

# an unknown method is an accessor
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift or return;
    ( my $key = $AUTOLOAD ) =~ s{.*::}{};
    my $accessor = sub { shift->{$key} };
    {
        no strict 'refs';
        *$AUTOLOAD = $accessor;
    }
    unshift @_, $self;
    goto &$AUTOLOAD;
}


sub unbless { _unbless(shift) }

sub _unbless {
    my $v = shift;
    my $ref = ref($v);

    if ($ref eq 'ARRAY') {
        return [ map { _unbless($_) } @$v ];
    } elsif ($ref eq 'Net::Stripe::Simple::Data') {
        return {
            map { $_ => _unbless( $v->{$_} ) } keys %$v
        }
    } elsif ($ref =~ /^JSON/) {
        return "$v";
    } else {
        return $v;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stripe::Simple::Data - collection of methods to augment a JSON hash

=head1 SYNOPSIS

  my $subscription = $stripe->subscriptions(  # API methods give us data objects
      update => {
          customer => $customer,              # a data object as a parameter value
          id       => $subscription,          # and another
          plan     => $spare_plan,            # and another
      }
  );

=head1 DESCRIPTION

L<Net::Stripe::Simple::Data> is simply a L<JSON> hash with a little magic added
to it. Principally, it will autoload any attribute name into an accessor method.
So you can say

  $data->id

instead of

  $data->{id}

This magic is applied recursively, so instead of

  $data->{metadata}{foo}

you can type

  $data->metadata->foo

This hardly saves any keystrokes but it is arguably easier to read.

The second bit of magic is that the stringification operator is overloaded
so that data objects with an id attribute are stringified as their id rather
than as

  Net::Stripe::Simple::Data=HASH(0xfeefaaf00)

This is useful because Stripe expects to see lots of different ids in its
various methods, so you can type

  $stripe->subscriptions(
      update => {
          customer => $customer,
          id       => $subscription,
          plan     => $spare_plan,
      }
  );

instead of

  $stripe->subscriptions(
      update => {
          customer => $customer->id,
          id       => $subscription->id,
          plan     => $spare_plan->id,
      }
  );

or worse yet

  $stripe->subscriptions(
      update => {
          customer => $customer->{id},
          id       => $subscription->{id},
          plan     => $spare_plan->{id},
      }
  );

The 'cmp' operator is overloaded as well so the stringification works mostly
as you expect. I.e.,

  $data eq $string;

is equivalent to

  $string eq $data;

=head1 NAME

Net::Stripe::Simple::Data - collection of methods to augment a JSON hash

=head1 METHODS

=head2 $self->unbless

Returns a copy of the data with all the magic stripped away. JSON objects are
converted to their stringified form. The intended use of this is prettier
debugging dumps.

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
