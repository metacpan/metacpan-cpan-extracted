package Password::Policy::Rule::Uppercase;
$Password::Policy::Rule::Uppercase::VERSION = '0.06';
use strict;
use warnings;

use parent 'Password::Policy::Rule';

use Password::Policy::Exception::InsufficientUppercase;

sub check {
    my $self = shift;
    my $password = $self->prepare(shift);
    my @uppercase = ($password =~ m/[A-Z]/g);
    my $count = scalar @uppercase;
    if($count < $self->arg) {
        Password::Policy::Exception::InsufficientUppercase->throw;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Rule::Uppercase

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
