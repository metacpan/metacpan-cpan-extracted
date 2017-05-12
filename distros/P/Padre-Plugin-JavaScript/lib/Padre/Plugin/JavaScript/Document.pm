package Padre::Plugin::JavaScript::Document;
BEGIN {
  $Padre::Plugin::JavaScript::Document::VERSION = '0.29';
}

# ABSTRACT: JavaScript Document for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our @ISA = 'Padre::Document';


#####################################################################
# Padre::Document::JavaScript Methods

# Copied from Padre::Document::Perl
sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	return $text =~ m/[\012\015]function\s+(\w+(?:::\w+)*)/g;
}

sub get_function_regex {
	return qr/(?:(?<=^)function\s+$_[1]|(?<=[\012\0125])function\s+$_[1])\b/;
}

sub comment_lines_str { return '//' }

1;

__END__
=pod

=head1 NAME

Padre::Plugin::JavaScript::Document - JavaScript Document for Padre

=head1 VERSION

version 0.29

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Adam Kennedy <adamk@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

