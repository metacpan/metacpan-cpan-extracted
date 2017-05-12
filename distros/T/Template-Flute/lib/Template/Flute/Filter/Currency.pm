package Template::Flute::Filter::Currency;

use strict;
use warnings;

use Number::Format;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Currency - Currency filter for prices

=head1 DESCRIPTION

Filters prices to be displayed according to the locale and
displayed with a currency symbol.

This filter is based on L<Number::Format>. Any options are
passed through to the L<Number::Format> object.

=head1 PREREQUISITES

L<Number::Format> module.

=head1 METHODS

=head2 init

=cut

sub init {
    my ($self, %args) = @_;

    $self->{format} = Number::Format->new(%{$args{options} || {}});
}

=head2 filter

Currency filter.

=cut

sub filter {
    my ($self, $amount) = @_;

    return $self->{format}->format_price($amount);
}


=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
