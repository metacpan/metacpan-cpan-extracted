use strict;
use warnings;
package Mixin::Linewise;
# ABSTRACT: write your linewise code for handles; this does the rest
$Mixin::Linewise::VERSION = '0.108';
use 5.006;
use Carp ();
Carp::confess "not meant to be loaded";

#pod =head1 DESCRIPTION
#pod
#pod It's boring to deal with opening files for IO, converting strings to
#pod handle-like objects, and all that.  With L<Mixin::Linewise::Readers> and
#pod L<Mixin::Linewise::Writers>, you can just write a method to handle handles, and
#pod methods for handling strings and filenames are added for you.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::Linewise - write your linewise code for handles; this does the rest

=head1 VERSION

version 0.108

=head1 DESCRIPTION

It's boring to deal with opening files for IO, converting strings to
handle-like objects, and all that.  With L<Mixin::Linewise::Readers> and
L<Mixin::Linewise::Writers>, you can just write a method to handle handles, and
methods for handling strings and filenames are added for you.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Steinbrunner Graham Knop

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
