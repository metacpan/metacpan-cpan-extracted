package Number::Object::Plugin::Tax;

use strict;
use warnings;
use base 'Class::Component::Plugin';

use POSIX ();

our $RATE = '1.05';

sub tax :Method {
    my($self, $c, $args) = @_;
    $c->clone($self->calc($c));
}

sub include_tax :Method {
    my($self, $c, $args) = @_;
    $c->clone($self->calc($c) + $c->{value});
}

sub calc {
    my($self, $c, $rate) = @_;
    $rate ||= $self->config->{rate} || 1;
    my $price = $c->{value};

    my $method = $self->config->{method} || 'floor';
    $method = 'floor' unless $method eq 'ceil';
    $method = "calc_$method";

    $self->$method(($price * $rate) - $price);
}

sub calc_floor {
    my($self, $price) = @_;
    POSIX::floor($price);
}

sub calc_ceil {
    my($self, $price) = @_;
    POSIX::ceil($price);
}

1;
__END__

=head1 NAME

Number::Object::Plugin::Tax - tax calc

=head1 CONFIGS

  my $price = Number::Object->new(100, {
    load_plugins => [qw/ Tax /],
    config => {
        Tax => { rate => 1.5, method => 'ceil' }
    }
  });


=over 4

=item rate

tax rate

=item method

Method of processing decimal point.

floor or ceil( default is floor )

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Number::Object>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

