use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::ViewOptions::Zoom;
# ABSTRACT: An abstract class for a set of options for zooming
$Renard::Curie::Model::ViewOptions::Zoom::VERSION = '0.004';
use Moo;

with qw(MooX::Role::CloneSet);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::ViewOptions::Zoom - An abstract class for a set of options for zooming

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<MooX::Role::CloneSet>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
