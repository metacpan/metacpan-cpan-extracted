package Net::Easypost::CustomsItem;
$Net::Easypost::CustomsItem::VERSION = '0.19';
use Types::Standard qw/Num Str Undef/;

use Moo;
with qw/Net::Easypost::PostOnBuild/;
with qw/Net::Easypost::Resource/;
use namespace::autoclean;

has [qw/description hs_tariff_number origin_country code currency/] => (
    is  => 'rw',
    isa => Str|Undef
);

has [qw/quantity value weight/] => (
    is  => 'rw',
    isa => Num
);

sub _build_fieldnames {
    return [
	qw/
	code
	currency
	description
	hs_tariff_number
	origin_country
	quantity
	value
	weight
	/
    ];
}

sub _build_role { 'customs_item' }

sub _build_operation { '/customs_items' }

sub clone {
    my ($self) = @_;

    return Net::Easypost::CustomsItems->new(
       map  { $_ => $self->$_ }
       grep { defined $self->$_ } @{ $self->fieldnames }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::CustomsItem

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 Net::Easypost::CustomsItem->new

=head1 NAME

 Net::Easypost::CustomsItem

=head1 ATTRIBUTES

=over 4

=item description

 string: Required, description of item being shipped

=item quantity

 float: Required, greater than zero

=item value

 float (USD): Required, greater than zero, total value (unit value * quantity)

=item weight

 float (oz): Required, greater than zero, total weight (unit weight * quantity)

=item hs_tariff_number

 string: Harmonized Tariff Schedule, e.g. "6109.10.0012" for Men's T-shirts

=item code

 string: SKU/UPC or other product identifier

=item origin_country

 string: Required, 2 char country code

=item currency

 string: 3 char currency code, default USD

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
