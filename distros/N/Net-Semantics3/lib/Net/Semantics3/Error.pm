package Net::Semantics3::Error;

use Moose;
with 'Throwable';
use namespace::clean -except => 'meta';
use Data::Dumper;

use Carp;

has 'type'    => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'message' => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'param'   => (is => 'ro', isa => 'Maybe[Str]');

sub BUILD {
    my $self = shift;
    my $msg = "Error: " . $self->type . "\nMessage: ". $self->message."\n";
    $msg .= "Failed at parameter: " . $self->param if $self->param;
    croak $msg;
};

=head1 NAME

Net::Semantics3::Error

=head1 SEE ALSO

L<https://semantics3.com>, L<https://semantics3.com/docs>

=head1 AUTHOR

Sivamani Varun, varun@semantics3.com

=head1 COPYRIGHT AND LICENSE

Net-Semantics3 is Copyright (C) 2013 Semantics3 Inc.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

__PACKAGE__->meta->make_immutable;
1;
