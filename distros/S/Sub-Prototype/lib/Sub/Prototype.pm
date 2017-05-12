use strict;
use warnings;

package Sub::Prototype;

require 5.008001;

use XSLoader;

our $VERSION = '0.02';

XSLoader::load(__PACKAGE__, $VERSION);

use Sub::Exporter -setup => {
    exports => ['set_prototype'],
    groups  => { default => ['set_prototype'] },
};

1;

__END__

=head1 NAME

Sub::Prototype - Set a subs prototype

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

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  Florian Ragwitz

This module is free software.

It may distribute it under the same terms as perl itself.

=cut
