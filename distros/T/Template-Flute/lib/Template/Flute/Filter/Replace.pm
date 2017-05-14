package Template::Flute::Filter::Replace;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Replace - Substitutes literal text in a string.

=head1 SYNOPSIS

  $replace_filter = Template::Flute::Filter::Replace->new(options => {
                        from => 'foo',
                        to => 'bar',
                    });

  $barbar = $replace->filter('foobar');

=head1 DESCRIPTION

The replace filter locates a substring within a string and substitutes
each occurence with another string.

=head1 METHODS

=head2 init

Initializes object with replace options.

=cut

sub init {
    my ($self, %args) = @_;

    for (qw/from to/) {
        $self->{$_} = $args{options}->{$_};
    }
}

=head2 filter

Carries out the actual substitution and returns
the filtered value.

=cut

sub filter {
    my ($self, $value) = @_;
    my ($qtd);

    return $value unless defined $self->{from}
        && length $self->{from};

    $qtd = quotemeta($self->{from});

    $value =~ s/$qtd/$self->{to}/g;

    return $value;
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
