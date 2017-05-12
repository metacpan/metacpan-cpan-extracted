package Password::Policy::Encryption::SHA1;
{
  $Password::Policy::Encryption::SHA1::VERSION = '0.02';
}

# ABSTRACT: The SHA-1 algorithm for Password::Policy

use strict;
use warnings;

use parent 'Password::Policy::Encryption';

use Digest::SHA1 qw/sha1_hex/;

sub enc {
    my $self = shift;
    my $password = $self->prepare(shift);
    return sha1_hex($password);
}

1;



=pod

=head1 NAME

Password::Policy::Encryption::SHA1 - The SHA-1 algorithm for Password::Policy

=head1 VERSION

version 0.02

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
