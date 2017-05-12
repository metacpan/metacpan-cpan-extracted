package SemanticWeb::OAI::ORE;

=head1 NAME

SemanticWeb::OAI::ORE - Modules to build, write and read OAI-ORE 
Resource Maps

=head1 VERSION

Version 1.00. Written against the v1.0 OAI-ORE specification
(L<http://www.openarchives.org/ore/1.0/toc>).

=cut

our $VERSION = '1.00';

=head1 DESCRIPTION

These modules are designed to build, write and read OAI-ORE
Resource Maps following the v1.0 OAI-ORE specification
(L<http://www.openarchives.org/ore/1.0/toc>). The main module is 

=over

=item L<SemanticWeb::OAI::ORE::ReM>

=back

with IO modules imlpementing parse/serialize for different formats

=over

=item L<SemanticWeb::OAI::ORE::N3>

=item L<SemanticWeb::OAI::ORE::RDFXML>

=item L<SemanticWeb::OAI::ORE::TriX>

=back

and supporting modules

=over

=item L<SemanticWeb::OAI::ORE::Model>

=item L<SemanticWeb::OAI::ORE::Agent>

=item L<SemanticWeb::OAI::ORE::Constant>

=back

=head1 METHODS

This module provides no methods, see L<SemanticWeb::OAI::ORE::ReM>. Use:

 use SemanticWeb::OAI::ORE;

to include all modules listed above.

=cut

use SemanticWeb::OAI::ORE::ReM;
use SemanticWeb::OAI::ORE::N3;
use SemanticWeb::OAI::ORE::RDFXML;
use SemanticWeb::OAI::ORE::TriX;

=head1 SEE ALSO

L<http://www.openarchives.org/ore>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2013 Simeon Warner.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
