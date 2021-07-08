package SDL2::Rect {
    use SDL2::Utils;
    has x => 'int', y => 'int', w => 'int', h => 'int';

=encoding utf-8

=head1 NAME

SDL2::Rect - A Rectangle with the Origin at the Upper Left in Integers

=head1 SYNOPSIS

    use SDL2 qw[:all];
    my $rect = SDL2::Rect->new( { x => 1, y => 1, w => 100, h => 100 } );

=head1 DESCRIPTION

SDL2::Rect

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
