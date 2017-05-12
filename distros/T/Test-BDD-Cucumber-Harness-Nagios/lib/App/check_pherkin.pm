package App::check_pherkin;

use Moose;

our $VERSION = '1.002'; # VERSION
# ABSTRACT: check_pherkin command interface


extends 'App::pherkin';

sub _process_arguments {
	my $self = shift;

	my ( $options, @feature_files ) = $self->SUPER::_process_arguments(@_);

	return( { harness => 'Nagios' }, @feature_files );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::check_pherkin - check_pherkin command interface

=head1 VERSION

version 1.002

=head1 Description

Extends the App::Pherkin command inteface for nagios.

See L<check_pherkin> for more info.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
