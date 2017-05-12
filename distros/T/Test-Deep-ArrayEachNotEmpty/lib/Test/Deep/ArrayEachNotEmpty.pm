package Test::Deep::ArrayEachNotEmpty;
use strict;
use warnings;
use utf8;

use parent qw/Test::Deep::ArrayEach/;

use Exporter qw/import/;

our $VERSION = "0.01";
our @EXPORT  = qw/array_each_not_empty/;

sub descend {
    my ($self, $got) = @_;

    return if _is_empty_array($got);
    return $self->SUPER::descend($got);
}

sub renderExp {
    my ($self, $exp) = @_;

    return $self->SUPER::renderExp($exp) . ' with not empty';
}

sub renderGot {
    my ($self, $got) = @_;

    return 'Empty array' if _is_empty_array($got);
    return $self->SUPER::renderGot($got);
}

sub _is_empty_array {
    my $value = shift;

    return ref $value eq 'ARRAY' && !@$value;
}

sub array_each_not_empty {
    my $expect = shift;

    return Test::Deep::ArrayEachNotEmpty->new($expect);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Deep::ArrayEachNotEmpty - an alternative to Test::Deep::ArrayEach

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::ArrayEachNotEmpty;

    my $empty = [];
    my $array = [{ foo => 1 }];

    cmp_deeply $empty, array_each({ foo => 1 });
    # => pass

    cmp_deeply $array, array_each({ foo => 1 });
    # => pass

    cmp_deeply $empty, array_each_not_empty({ foo => 1 });
    # => fail

    cmp_deeply $array, array_each_not_empty({ foo => 1 });
    # => pass

=head1 DESCRIPTION

Test::Deep::ArrayEachNotEmpty is a sub class of Test::Deep::ArrayEach
which forbid an empty array.

=head1 LICENSE

Copyright (C) Mihyaeru/mihyaeru21.

Released under the MIT license.

See C<LICENSE> file.

=head1 AUTHOR

Mihyaeru E<lt>mihyaeru21@gmail.comE<gt>

=cut

