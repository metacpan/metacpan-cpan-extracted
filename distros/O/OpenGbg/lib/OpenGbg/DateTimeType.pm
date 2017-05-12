package OpenGbg::DateTimeType;
our $VERSION = '0.1402';
use 5.10.0;
use strict;
use warnings;

use DateTime;
use Type::Library -base, -declare => qw/DateTime/;
use Type::Utils;

class_type(DateTime, { class => 'DateTime' });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGbg::DateTimeType

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
