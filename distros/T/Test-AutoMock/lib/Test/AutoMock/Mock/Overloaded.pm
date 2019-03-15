BEGIN {
    # A hack to suppress redefined warning caused by circulation dependency
    $INC{'Test/AutoMock/Mock/Overloaded.pm'} //= do {
        require File::Spec;
        File::Spec->rel2abs(__FILE__);
    };
}

package Test::AutoMock::Mock::Overloaded;
use strict;
use warnings;
use parent qw(Test::AutoMock::Mock::Basic);
use Scalar::Util ();
use Test::AutoMock::Mock::Functions ();
use overload (
    '${}' => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_overload_nomethod(@_, '${}')
    },
    '@{}' => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_deref_array(@_)
    },
    '%{}' => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_deref_hash(@_)
    },
    '&{}' => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_deref_code(@_)
    },
    '*{}' => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_overload_nomethod(@_, '*{}')
    },
    nomethod => sub {
        my $self = shift;
        my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
        $manager->_overload_nomethod(@_);
    },
    fallback => 0,
);

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Mock::Overloaded - Mock that supports operator overloading

=head1 SYNOPSIS

  use Test::AutoMock qw(mock_overloaded manager);
  use Test::More import => [qw(is done_testing)];

  my $mock = mock_overloaded;

  # define operators, hashes, arrays
  manager($mock)->add_method('`+`' => 10);
  manager($mock)->add_method('{key}' => 'value');
  manager($mock)->add_method('[0]' => 'zero');

  # call overloaded operators
  is($mock + 5, 10);
  is($mock->{key}, 'value');
  is($mock->[0], 'zero');

  # varify calls
  manager($mock)->called_with_ok('`+`', [5, '']);
  manager($mock)->called_ok('{key}');
  manager($mock)->called_ok('[0]');

=head1 DESCRIPTION

It is a subclass of L<Test::AutoMock::Mock::Basic> that supports operator
overloading.

Do not instantiate this class directly. Use L<Test::AutoMock::mock_overloaded>
instead.

=head1 SPECIAL METHODS

This class supports special notation methods. It can be used with methods such
as C<< manager($mock)->called_ok >> and C<< manager($mock)->add_method >>.

=head2 OPERATOR OVERLOADING

The method name enclosed in back-tick (C<`>) means operator overloading. The
operator name is the same as the L<overload> module.

Most operator overloads return child AutoMock, just like regular methods.
The following methods return default values that match type. Please overwrite
it if necessary.

=over 4

=item C<`bool`> : C<!!1>

=item C<`""`> : a unique name of instance

=item C<`0+`> : C<1>

=item C<`qr`> : C<qr//>

=back

Also, in order to avoid infinite loops, C<< `<>` >> defaults to C<undef>.

There are two arguments to be recorded, C<$other> and C<$swap>, according to the
L<overload> module specifications. Please be careful when using
C<automock_called_with_ok>.

Below is a complete list of possible names.

=over 4

=item C<`+`>, C<`-`>, C<`*`>, C<`/`>, C<`%`>, C<`**`>, C<`<<`>, C<<< `>>` >>>, C<`x`>, C<`.`>

=item C<`+=`>, C<`-=`>, C<`*=`>, C<`/=`>, C<`%=`>, C<`**=`>, C<`<<=`>, C<<< `>>=` >>>, C<`x=`>, C<`.=`>

=item C<`<`>, C<`<=`>, C<< `>` >>, C<< `>=` >>, C<`==`>, C<`!=`>

=item C<< `<=>` >>, C<`cmp`>

=item C<`lt`>, C<`le`>, C<`gt`>, C<`ge`>, C<`eq`>, C<`ne`>

=item C<`&`>, C<`&=`>, C<`|`>, C<`|=`>, C<`^`>, C<`^=`>

=item C<`neg`>, C<`!`>, C<`~`>

=item C<`++`>, C<`--`>

=item C<`atan2`>, C<`cos`>, C<`sin`>, C<`exp`>, C<`abs`>, C<`log`>, C<`sqrt`>, C<`int`>

=item C<`bool`>, C<`""`>, C<`0+`>, C<`qr`>

=item C<< `<>` >>

=item C<`-X`>

=item C<`${}`>, C<`*{}`>

=back

C<@{}> and C<%{}>, C<&{}> are not supported. see L<"HASH, ARRAY, CODE ACCESS">
instead.

=head2 HASH, ARRAY, CODE ACCESS

In this class, you can handle operations with the same notation as hash-ref,
array-ref, code-ref.

=over 4

=item C<[index]>, C<FETCHSIZE>, C<STORESIZE>, C<CLEAR>, C<PUSH>, C<POP>, C<SHIFT>, C<UNSHIFT>, C<DELETE>, C<EXISTS>

This name is used when the mock is called as an array reference.
See L<Test::AutoMock::Mock::TieArray> for details.

=item C<{key}>, C<DELETE>, C<CLEAR>, C<EXISTS>, C<FIRSTKEY>, C<NEXTKEY>, C<SCALAR>

This name is used when the mock is called as an hash reference.
See L<Test::AutoMock::Mock::TieHash> for details.

=item C<()>

This name is used when the mock is called as a code reference. You can also
access its arguments.

=back

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

