package Template::Extract::Parser;
$Template::Extract::Parser::VERSION = '0.41';

use 5.006;
use strict;
use warnings;
use base 'Template::Parser';

sub new {
    my $class = shift;
    my $params = shift || {};

    $class->SUPER::new(
        {
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
            %$params,
        }
    );
}

1;

__END__

=head1 NAME

Template::Extract::Parser - Template parser for extraction

=head1 SYNOPSIS

    use Template::Extract::Parser;

    my $parser = Template::Extract::Parser->new(\%config);
    my $template = $parser->parse($text) or die $parser->error();

=head1 DESCRIPTION

This is a trivial subclass of C<Template::Extract>; the only difference
with its base class is that C<PRE_CHOMP> and C<POST_CHOMP> is enabled by
default.

=head1 SEE ALSO

L<Template::Extract>, L<Template::Extract::Run>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2005, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

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
