use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::AccelMap;
# ABSTRACT: Role for accelerators
$Renard::Curie::Component::MainWindow::Role::AccelMap::VERSION = '0.003';
use Moo::Role;
use Renard::Curie::Component::AccelMap;

after setup_window => method() {
	Renard::Curie::Component::AccelMap->new;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::AccelMap - Role for accelerators

=head1 VERSION

version 0.003

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
