package Password::Policy::Rule;
$Password::Policy::Rule::VERSION = '0.04';
use strict;
use warnings;

use Password::Policy::Exception::EmptyPassword;

sub new {
    my $class = shift;
    my $arg = shift || 0;

    my $self = bless {
        arg => $arg
    } => $class;
    return $self;
}

sub arg {
    my $self = shift;
    return $self->{arg} || $self->default_arg;
}

sub check { return "This was not implemented properly."; }
sub default_arg { return 1; }

sub prepare {
    my ($self, $password) = @_;
    return $password || Password::Policy::Exception::EmptyPassword->throw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Rule

=head1 VERSION

version 0.04

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
