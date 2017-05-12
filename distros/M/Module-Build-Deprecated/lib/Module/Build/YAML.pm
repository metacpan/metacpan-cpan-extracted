package Module::Build::YAML;

use strict;
use warnings;
use base 'CPAN::Meta::YAML';
our $VERSION  = '1.41';

1;

# ABSTRACT: DEPRECATED

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::YAML - DEPRECATED

=head1 VERSION

version 0.4210

=head1 DESCRIPTION

This module was originally an inline copy of L<YAML::Tiny>.  It has been
deprecated in favor of using L<CPAN::Meta::YAML> directly.  This module is kept
as a subclass wrapper for compatibility.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
