package Password::Policy::Rule::Length;
$Password::Policy::Rule::Length::VERSION = '0.04';
use strict;
use warnings;

use parent 'Password::Policy::Rule';

use String::Multibyte;

use Password::Policy::Exception::InsufficientLength;

sub default_arg { return 8; }

sub check {
    my $self = shift;
    my $password = $self->prepare(shift);
    my $strmb = String::Multibyte->new('UTF8');
    my $len = $strmb->length($password);
    if($len < $self->arg) {
        Password::Policy::Exception::InsufficientLength->throw;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Rule::Length

=head1 VERSION

version 0.04

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
