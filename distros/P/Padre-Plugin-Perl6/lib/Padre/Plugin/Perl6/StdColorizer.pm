package Padre::Plugin::Perl6::StdColorizer;
BEGIN {
  $Padre::Plugin::Perl6::StdColorizer::VERSION = '0.71';
}

# ABSTRACT: Perl 6 Colorizer

use strict;
use warnings;

use Padre::Plugin::Perl6::Colorizer ();
our @ISA = ('Padre::Plugin::Perl6::Colorizer');

sub colorize {
	my $self = shift;
	$Padre::Plugin::Perl6::Colorizer::colorizer = 'STD';
	$self->SUPER::colorize(@_);
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::Perl6::StdColorizer - Perl 6 Colorizer

=head1 VERSION

version 0.71

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

