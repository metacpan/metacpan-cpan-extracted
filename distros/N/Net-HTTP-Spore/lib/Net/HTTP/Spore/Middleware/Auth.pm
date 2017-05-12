package Net::HTTP::Spore::Middleware::Auth;
{
  $Net::HTTP::Spore::Middleware::Auth::VERSION = '0.06';
}

# ABSTRACT: base class for Authentication middlewares

use Moose;
extends 'Net::HTTP::Spore::Middleware';

sub should_authenticate { $_[1]->env->{'spore.authentication'} }

sub call { die "should be implemented" }

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Auth - base class for Authentication middlewares

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Authentication middleware should extends this base class and implement the B<call> method

=head1 AUTHORS

=over 4

=item *

franck cuny <franck@lumberjaph.net>

=item *

Ash Berlin <ash@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
