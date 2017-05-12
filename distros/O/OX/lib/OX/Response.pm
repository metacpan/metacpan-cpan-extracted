package OX::Response;
BEGIN {
  $OX::Response::AUTHORITY = 'cpan:STEVAN';
}
$OX::Response::VERSION = '0.14';
use Moose;
use namespace::autoclean;
# ABSTRACT: response object for OX

extends 'Web::Response';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::Response - response object for OX

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use OX::Request;

  my $req = OX::Request->new(env => $env);
  my $response = $req->new_response;

=head1 DESCRIPTION

This class is a simple subclass of L<Web::Response>. Right now, it doesn't add
any additional functionality, but it does provide a place to add new features
in later.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy@tozt.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
