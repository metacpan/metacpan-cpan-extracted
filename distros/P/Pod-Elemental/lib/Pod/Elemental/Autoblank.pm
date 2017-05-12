package Pod::Elemental::Autoblank;
# ABSTRACT: a paragraph that always displays an extra blank line in Pod form
$Pod::Elemental::Autoblank::VERSION = '0.103004';
use namespace::autoclean;
use Moose::Role;

#pod =head1 OVERVIEW
#pod
#pod This role exists primarily to simplify elements produced by the Pod5
#pod transformer.  Any element with this role composed into it will append an extra
#pod newline to the normally generated response to the C<as_pod_string> method.
#pod
#pod That's it!
#pod
#pod =cut

around as_pod_string => sub {
  my ($orig, $self, @arg) = @_;
  my $str = $self->$orig(@arg);
  "$str\n\n";
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Autoblank - a paragraph that always displays an extra blank line in Pod form

=head1 VERSION

version 0.103004

=head1 OVERVIEW

This role exists primarily to simplify elements produced by the Pod5
transformer.  Any element with this role composed into it will append an extra
newline to the normally generated response to the C<as_pod_string> method.

That's it!

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
