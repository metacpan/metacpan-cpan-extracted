package Socialtext::WikiObject::TableConfig;
use strict;
use warnings;
use base 'Socialtext::WikiObject';

=head1 NAME

Socialtext::WikiObject::TableConfig - Extract a table into a hash

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 table

Return a hashref to the parsed table.

=cut

sub table {
    my $self = shift;

    my $table = $self->{table} or die "Can't find a table on the page!\n";
    if ($table->[0][0] =~ m/^\*.+\*$/) {
        shift @$table; # remove the table header
    }

    my %results;
    for my $r (@$table) {
        $results{$r->[0]} = $r->[1];
    }

    return \%results;
}

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
