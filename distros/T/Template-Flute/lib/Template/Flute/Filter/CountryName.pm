package Template::Flute::Filter::CountryName;

use strict;
use warnings;

use Locales;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::CountryName - country name filter

=head1 DESCRIPTION

Country name filter based on L<Locales>.

=head1 PREREQUISITES

L<Locales> module.

=head1 METHODS

=head2 init

The init method allows you to set the following options:

=over 4

=item locale

Locale for country name output.

=item clear_current_locale

Whether to return an empty string for the current locale or not.

=back

=cut

sub init {
    my ($self, %args) = @_;

    $self->{locale} = $args{options}->{locale} || 'en';
    $self->{clear_current_locale} = $args{options}->{clear_current_locale};

    unless ($self->{object} = Locales->new($self->{locale})) {
        die $@;
    }
}

=head2 filter

Country name filter.

=cut

sub filter {
    my ($self, $code) = @_;
    my $name = '';

    if ($code) {
        unless ($self->{clear_current_locale} && $code eq $self->{locale}) {
            $name = $self->{object}->get_territory_from_code($code);
        }
    }
    
    return $name;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
