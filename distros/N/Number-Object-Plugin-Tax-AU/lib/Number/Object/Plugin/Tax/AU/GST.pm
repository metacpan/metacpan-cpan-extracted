package Number::Object::Plugin::Tax::AU::GST;

use warnings;
use strict;

use base 'Number::Object::Plugin::Tax';

our $VERSION = 0.06;
our $RATE    = 1.1;

sub calc {
  my($self, $c) = @_;

  my $price = $c->{value};
  my $total = $price * $RATE;

  return $total - $price;
}

sub deduct_tax : Method {
  my ($self, $c) = @_;

  my $price = $c->{value};
  my $total = $price / $RATE;

  return $total;
}

sub inc_price_tax_portion : Method {
  my ($self, $c) = @_;

  my $price = $c->{value};

  return $price / 11;
}

sub ex_price_tax_portion : Method {
  my ($self, $c) = @_;

  my $price = $c->{value};

  return $price / 10;
}

=head1 NAME

Number::Object::Plugin::Tax::AU::GST - a Number::Object plugin for Australian GST

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

    use Number::Object;
    Number::Object->load_components('Autocall');
    Number::Object->load_plugins('Tax::AU::GST');

    my $amount = Number::Object->new(99.95);

    say $amount;              # 99.95
    say "$amount";            # 99.95
    say $amount + 0;          # 99.95
    say $amount->value;       # 99.95

    say $amount->tax;         # 9.995
    say $amount->include_tax; # 109.945

=cut

=head1 AUTHOR

Matt Koscica, C<< <matt at qx.net.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number::object::plugin::tax::au::gst at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number::Object::Plugin::Tax::AU::GST>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Object::Plugin::Tax::AU::GST

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number::Object::Plugin::Tax::AU::GST>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number::Object::Plugin::Tax::AU::GST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number::Object::Plugin::Tax::AU::GST>

=item * Search CPAN

L<http://search.cpan.org/dist/Number::Object::Plugin::Tax::AU::GST/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Matt Koscica.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Number::Object::Plugin::Tax::AU::GST
