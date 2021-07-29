package SDL2::Locale {
    use SDL2::Utils;
    has
        language => 'opaque',    # string
        country  => 'opaque';    # string

=encoding utf-8

=head1 NAME

SDL2::Locale - Language and locality structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<language> - A language name, like "en" for English

=item C<country> - A country, like "US" for the United States of America. Can be NULL

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
