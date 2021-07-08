
package SDL2::FRect {
    use SDL2::Utils;
    has x => 'float', y => 'float', w => 'float', h => 'float';

=encoding utf-8

=head1 NAME

SDL2::FRect - A Rectangle with the Origin at the Upper Left in Floating Point
Numbers

=head1 SYNOPSIS

    use SDL2 qw[:all];
    my $rect = SDL2::FRect->new( { x => 50.7, y => 1.5, w => 99.75, h => 50.75 } );

=head1 DESCRIPTION

SDL2::FRect

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
