package Module::Build::Version;

use strict;
use warnings;

use parent 'version';
our $VERSION = '0.87';

1;

# ABSTRACT: DEPRECATED

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::Version - DEPRECATED

=head1 VERSION

version 0.4210

=head1 DESCRIPTION

Module::Build now lists L<version> as a C<configure_requires> dependency
and no longer installs a copy.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
