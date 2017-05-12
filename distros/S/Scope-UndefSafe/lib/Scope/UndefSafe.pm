package Scope::UndefSafe;
use strict;
use warnings;
use utf8;

our $VERSION = "0.03";

use Exporter qw/import/;
our @EXPORT_OK = qw/let apply/;

sub let (&$; &) {
    my ($func, $value) = @_;

    if (defined $value) {
        local $_ = $value;
        return $func->();
    }

    return undef;
}

sub apply (&$; &) {
    my ($func, $value) = @_;
    let(\&$func, $value);
    return $value;
}

1;
__END__

=encoding utf-8

=head1 NAME

Scope::UndefSafe - The functions to limit the scope.

=head1 SYNOPSIS

    use Scope::UndefSafe qw/let apply/;

    my $obj = AnyObject->new;
    let { $_->method() } $obj; # `method` is executed.
    apply { $_->method() } $obj; # `method` is executed, and return $obj.

    $obj = undef;
    let { $_->method() } $obj; # `method` is not executed.
    apply { $_->method() } $obj; # `method` is not executedm, but return $obj.


=head1 DESCRIPTION

Scope::UndefSafe has two functions to limit scope undef safety.

=head2 METHODS

=head3 C<let>

Invoke block if pass non undef value as second argument.
And return block returned value.

The following two are the same behavior.

    let { $_->method() } $obj;
    $obj ? $obj->method() : undef;

=head3 C<apply>

Invoke block if pass non undef value as a second argument.
And return a second argument.

The following two are the same behavior.

    apply { $_->method() } $obj;
    $obj ? do { $obj->method(); $obj } : undef;

=head1 SEE ALSO

=over

=item * L<stdlib.kotlin.let|https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html>

=item * L<stdlib.kotlin.apply|https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/apply.html>

=back

=head1 LICENSE

The MIT License (MIT)

Copyright (c) 2016 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 AUTHOR

Pine Mizune E<lt>pinemz@gmail.comE<gt>

=cut

