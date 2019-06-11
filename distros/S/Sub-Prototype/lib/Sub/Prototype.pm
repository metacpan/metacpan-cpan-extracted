use strict;
use warnings;

package Sub::Prototype; # git description: 0.02-3-gb5d237a
# ABSTRACT: Set a sub's prototype

require 5.008001;

use XSLoader;

our $VERSION = '0.03';

XSLoader::load(__PACKAGE__, $VERSION);

use Sub::Exporter -setup => {
    exports => ['set_prototype'],
    groups  => { default => ['set_prototype'] },
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Prototype - Set a sub's prototype

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Sub::Prototype;

    BEGIN {
        my $code = sub { ... };
        set_prototype($code, '&@');
        *main::my_func = $code;
    }

    my_func { ... } @list;

=head1 FUNCTIONS

This module only has one function, which is also exported by default:

=head2 set_prototype(\&coderef, $prototype)

    set_prototype(\&some_function, '$$');

Sets the prototype for C<coderef> to C<$prototype>.

=head1 THANKS

Shawn M Moore for the idea and tests.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Prototype>
(or L<bug-Sub-Prototype@rt.cpan.org|mailto:bug-Sub-Prototype@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
