package Password::Policy::Encryption::MD5;
{
  $Password::Policy::Encryption::MD5::VERSION = '0.02';
}

# ABSTRACT: The MD5 algorithm for Password::Policy

use strict;
use warnings;

use parent 'Password::Policy::Encryption';

use Digest::MD5 qw/md5_hex/;

sub enc {
    my $self = shift;
    my $password = $self->prepare(shift);
    return md5_hex($password);
}

1;



=pod

=head1 NAME

Password::Policy::Encryption::MD5 - The MD5 algorithm for Password::Policy

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


