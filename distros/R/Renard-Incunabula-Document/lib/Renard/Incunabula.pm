use Renard::Incunabula::Common::Setup;
package Renard::Incunabula;
# ABSTRACT: The base library for Project Renard
$Renard::Incunabula::VERSION = '0.004';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula - The base library for Project Renard

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This library contains various modules that can be used throughout other parts
of Project Renard.  Among these is L<Renard::Incunabula::Common::Setup> which
provides an easy way to export commonly used features such as use of
L<Function::Parameters> for function signatures and type-checking.

=head1 SEE ALSO

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Renard-Incunabula/>

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
