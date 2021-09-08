package SDL2::iconv_t 0.01 {
    use SDL2::Utils qw[has];
    has src_fmt => 'int', dst_fmt => 'int';

=encoding utf-8

=head1 NAME

SDL2::iconv_t - SDL Character Conversion System

=head1 SYNOPSIS

    use SDL2 qw[:stdinc];

=head1 DESCRIPTION

SDL2::iconv_t is part of SDL's internal character conversion system.

=head1 Fields

=head2 C<src_fmt( )>

The input charset.

=head2 C<dst_fmt( )>

The output charset.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

charset

=end stopwords

=cut

};
1;
