use strict;
use warnings;

package    #private
  Scalar::Boolean::Value;

my $true  = bless \do { ( my $data = 1 ) }, __PACKAGE__;
my $false = bless \do { ( my $data = 0 ) }, __PACKAGE__;

use overload
  '!'    => sub { ${ $_[0] } ? $false : $true },
  'bool' => sub { ${ $_[0] } },
  'eq'   => sub { ${ $_[0] } eq $_[1] ? $true : $false },
  '=='   => sub { ${ $_[0] } == $_[1] ? $true : $false };

sub boolean($) { $_[0] ? $true : $false }
sub true()     { $true }
sub false()    { $false }

1;

__END__
=pod

=head1 NAME

Scalar::Boolean::Value

=head1 VERSION

version 1.02

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

