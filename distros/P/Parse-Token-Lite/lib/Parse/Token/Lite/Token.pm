package Parse::Token::Lite::Token;
use Moose;

our $VERSION = '0.200'; # VERSION
# ABSTRACT: Token class


has data=>(is=>'rw');


has rule=>(is=>'rw');

sub as_string{
  my ($self) = @_;
  return $self->data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Token::Lite::Token - Token class

=head1 VERSION

version 0.200

=head1 ATTRIBUTES

=head2 data

returns current matched string.

=head2 rule

returns current matched rule.

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
