package Template::Reverse::Part;
use Moo;

our $VERSION = '0.143'; # VERSION
# ABSTRACT: Part class.

has pre=>(is=>'rw', default=>sub{[]});
has post=>(is=>'rw' , default=>sub{[]});
has type=>(is=>'rw');

sub as_arrayref{
  my ($self) = @_;
  return [$self->pre, $self->post];
}
1;

__END__

=pod

=head1 NAME

Template::Reverse::Part - Part class.

=head1 VERSION

version 0.143

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
