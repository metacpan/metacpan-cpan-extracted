#===============================================================================
#
#  DESCRIPTION:  Inline comments
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::Z;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::Z - Inline comments

=head1 SYNOPSIS

    The "exeunt" command Z<Think about renaming this command?> is used
    to quit all applications.

=head1 DESCRIPTION

The C<ZE<lt>E<gt>> formatting code indicates that its contents constitute a
B<zero-width comment>, which should not be rendered by any renderer.
For example:

    The "exeunt" command Z<Think about renaming this command?> is used
    to quit all applications.
=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut



