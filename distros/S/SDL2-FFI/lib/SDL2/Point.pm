package SDL2::Point {
    use SDL2::Utils;
    has
        x => 'int',
        y => 'int';

=encoding utf-8

=head1 NAME

SDL2::Point - The Structure that Defines a Point with Integers

=head1 SYNOPSIS

    use SDL2 qw[:all];
    my $point = SDL2::Point->new( { x => 1, y => 1 } );
    warn $point->x;

=head1 DESCRIPTION

SDL2::Point

=head1 Fields

=over

=item C<x>

=item C<y>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
