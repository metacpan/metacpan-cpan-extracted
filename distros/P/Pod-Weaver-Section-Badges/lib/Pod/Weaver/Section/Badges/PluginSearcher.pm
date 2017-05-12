use 5.10.0;
use strict;
use warnings;

package Pod::Weaver::Section::Badges::PluginSearcher;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0402';

use Moose;
use Module::Pluggable search_path => ['Badge::Depot::Plugin'], require => 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Badges::PluginSearcher

=head1 VERSION

Version 0.0402, released 2016-02-20.

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Weaver-Section-Badges>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Weaver-Section-Badges>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
