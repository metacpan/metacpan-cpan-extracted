package Net::Stripe::Resource;
$Net::Stripe::Resource::VERSION = '0.37';
# ABSTRACT: represent a Resource object from Stripe

use Moose;
use Kavorka;

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    # Break out the JSON::XS::Boolean values into 1/0
    for my $field (keys %args) {
        if (ref($args{$field}) =~ /^(JSON::XS::Boolean|JSON::PP::Boolean)$/) {
            $args{$field} = $args{$field} ? 1 : 0;
        }
    }

    for my $f (qw/card default_card/) {
        next unless $args{$f};
        next unless ref($args{$f}) eq 'HASH';
        $args{$f} = Net::Stripe::Card->new($args{$f});
    }

    if (my $s = $args{subscription}) {
        if (ref($s) eq 'HASH') {
            $args{subscription} = Net::Stripe::Subscription->new($s);
        }
    }
    if (my $s = $args{coupon}) {
        if (ref($s) eq 'HASH') {
            $args{coupon} = Net::Stripe::Coupon->new($s);
        }
    }
    if (my $s = $args{discount}) {
        if (ref($s) eq 'HASH') {
            $args{discount} = Net::Stripe::Discount->new($s);
        }
    }
    if (my $p = $args{plan}) {
        if (ref($p) eq 'HASH') {
            $args{plan} = Net::Stripe::Plan->new($p);
        }
    }

    $class->$orig(%args);
};

method form_fields_for_metadata {
    my $metadata = $self->metadata();
    my @metadata = ();
    while( my($k,$v) = each(%$metadata) ) {
      push @metadata, 'metadata['.$k.']';
      push @metadata, $v;
    }
    return @metadata;
}

method fields_for($for) {
    return unless $self->can($for);
    my $thingy = $self->$for;
    return unless $thingy;
    return $thingy->form_fields if ref($thingy) =~ m/^Net::Stripe::/;
    return ($for => $thingy);
}

1;

__END__

=pod

=head1 NAME

Net::Stripe::Resource - represent a Resource object from Stripe

=head1 VERSION

version 0.37

=head1 AUTHORS

=over 4

=item *

Luke Closs

=item *

Rusty Conover

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Prime Radiant, Inc., (c) copyright 2014 Lucky Dinosaur LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
