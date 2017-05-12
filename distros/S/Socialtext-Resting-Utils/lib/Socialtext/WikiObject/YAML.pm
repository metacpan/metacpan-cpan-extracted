package Socialtext::WikiObject::YAML;
use strict;
use warnings;
use base 'Socialtext::WikiObject::PreBlock';
use YAML;

=head1 NAME

Socialtext::WikiObject::YAML - Parse page content as YAML

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 parse_wikitext()

Override parent method to load the wikitext as YAML.

=cut

sub parse_wikitext {
    my $self = shift;
    my $wikitext = shift;

    $self->SUPER::parse_wikitext($wikitext);
    $wikitext = $self->pre_block;

    my $data = {};
    eval { $data = Load($wikitext) };
    $data->{yaml_error} = $@ if $@;
    $self->{_hash} = $data;

    # Store the data into $self
    for my $k (keys %$data) {
        $self->{$k} = $self->{lc $k} = $data->{$k};
    }
}

=head2 as_hash

Return the parsed YAML as a hash.

=cut

sub as_hash { $_[0]->{_hash} }

# TODO - Add AUTOLOADed methods?

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
