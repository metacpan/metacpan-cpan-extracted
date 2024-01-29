package Password::Policy::Encryption;
$Password::Policy::Encryption::VERSION = '0.06';
use strict;
use warnings;

use Password::Policy::Exception::EmptyPassword;

sub new { bless {} => shift; }
sub enc { return "This was not implemented properly."; }

# alias
sub encrypt {
    my ($self, $arg) = @_;
    return $self->enc($arg);
}

sub prepare {
    my ($self, $password) = @_;
    return $password || Password::Policy::Exception::EmptyPassword->throw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Encryption

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
