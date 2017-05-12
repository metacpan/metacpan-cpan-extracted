package String::Numeric::XS;
use strict;
use warnings;

BEGIN {
    our $VERSION   = 0.9;
    our @EXPORT_OK = qw(
      is_numeric
      is_float
      is_decimal
      is_integer
      is_int
      is_int8
      is_int16
      is_int32
      is_int64
      is_int128
      is_uint
      is_uint8
      is_uint16
      is_uint32
      is_uint64
      is_uint128
    );

    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);

    require Exporter;
    *import = \&Exporter::import;
}

*is_numeric = \&is_float;
*is_integer = \&is_int;

1;

__END__

=head1 NAME

String::Numeric::XS - XS implementation of String::Numeric

=head1 DESCRIPTION

The main L<String::Numeric> package will use this package automatically if it 
can find it. Do not use this package directly, use L<String::Numeric> instead.

=head1 AUTHOR

Christian Hansen, E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Christian Hansen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

