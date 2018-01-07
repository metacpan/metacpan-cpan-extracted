package Number::ZipCode::JP::Table;

use strict;
use warnings;

our $VERSION = '0.20171228';

no warnings 'once';

our %ZIP_TABLE = Number::ZipCode::JP::_merge_table(
    qw/ Number::ZipCode::JP::Table::Area Number::ZipCode::JP::Table::Company /
);

sub import {
    my $class = shift;
    my $pkg = caller(0);
    no strict 'refs';
    %{"$pkg\::ZIP_TABLE"} = %ZIP_TABLE;
}

1;
__END__

=head1 NAME

Number::ZipCode::JP::Table - Regex table for all of the Japanese zip-codes

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

This module defines all of the Japanese zip-codes table to use
by Number::ZipCode::JP.

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Number::ZipCode::JP>,
http://www.post.japanpost.jp/zipcode/download.html

=cut
