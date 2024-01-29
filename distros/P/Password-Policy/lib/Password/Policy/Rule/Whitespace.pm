package Password::Policy::Rule::Whitespace;
$Password::Policy::Rule::Whitespace::VERSION = '0.06';
use strict;
use warnings;

use parent 'Password::Policy::Rule';

use Password::Policy::Exception::InsufficientWhitespace;

sub check {
    my $self = shift;
    my $password = $self->prepare(shift);
    my @whitespace = ($password =~ m/\s/g);
    my $count = scalar @whitespace;
    if($count < $self->arg) {
        Password::Policy::Exception::InsufficientWhitespace->throw;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Rule::Whitespace

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
