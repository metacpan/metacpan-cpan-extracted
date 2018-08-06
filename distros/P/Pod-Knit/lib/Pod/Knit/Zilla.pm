package Pod::Knit::Zilla;
our $AUTHORITY = 'cpan:YANICK';
$Pod::Knit::Zilla::VERSION = '0.0.1';
use strict;
use warnings;

use Moose::Role;

has zilla => (
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Zilla

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

