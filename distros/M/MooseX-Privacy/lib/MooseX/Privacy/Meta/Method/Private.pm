package MooseX::Privacy::Meta::Method::Private;
BEGIN {
  $MooseX::Privacy::Meta::Method::Private::VERSION = '0.05';
}

use Moose;
extends 'Moose::Meta::Method';

use Carp qw/confess/;

sub wrap {
    my $class = shift;
    my %args  = @_;

    my $method       = delete $args{body};
    my $private_code = sub {
        confess "The "
            . $args{package_name} . "::"
            . $args{name}
            . " method is private"
            unless ( scalar caller() ) eq $args{package_name};

        goto &{$method};
    };
    $args{body} = $private_code;
    $class->SUPER::wrap(%args);
}

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Meta::Method::Private

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

