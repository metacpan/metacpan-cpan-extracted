package Socialtext::WikiObject::PreBlock;
use strict;
use warnings;
use base 'Socialtext::WikiObject';

=head1 NAME

Socialtext::WikiObject::PreBlock - Parse out the first '.pre' block

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 parse_wikitext()

Override parent method to load the pre block

=cut

sub parse_wikitext {
    my $self = shift;
    my $wikitext = shift;

    # Load the YAML
    $wikitext =~ s/^.*?\.pre\n(.+)\.pre.+$/$1/s;
    chomp $wikitext;
    $wikitext .= "\n";
    $self->{_pre_block} = $wikitext;
}

=head2 pre_block

Return the parsed .pre block

=cut

sub pre_block { $_[0]->{_pre_block} }

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
