package Test::Deep::Fuzzy;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Exporter 5.57 qw/import/;
our @EXPORT = qw/is_fuzzy_num/;

use Test::Deep::Fuzzy::Number;

sub is_fuzzy_num($;$) { Test::Deep::Fuzzy::Number->new(@_) }

1;
__END__

=encoding utf-8

=head1 NAME

Test::Deep::Fuzzy - fuzzy number comparison with Test::Deep

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::Fuzzy;

    my $range = 0.001;

    cmp_deeply({
        number => 0.0078125,
    }, {
        number => is_fuzzy_num(0.008, $range),
    }, 'number is collect');

=head1 DESCRIPTION

Test::Deep::Fuzzy provides fuzzy number comparison with L<Test::Deep>.

=head1 FUNCTIONS

=over 2

=item B<is_fuzzy_num> EXPECTED, RANGE

Rounds the values before comparing the values.
The RANGE is used for C<Math::Round::nearest()> to compare the values.

=back

=head1 SEE ALSO

L<Math::Round>
L<Test::Deep>
L<Test::Number::Delta>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
