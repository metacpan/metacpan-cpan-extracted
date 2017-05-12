package MooseX::Privacy::Meta::Method::Protected;
BEGIN {
  $MooseX::Privacy::Meta::Method::Protected::VERSION = '0.05';
}

use Moose;
extends 'Moose::Meta::Method';

use Carp qw/confess/;

sub wrap {
    my $class = shift;
    my %args  = @_;

    my $method         = delete $args{body};
    my $protected_code = sub {
        my $caller = caller();
        confess "The "
            . $args{package_name} . "::"
            . $args{name}
            . " method is protected"
            unless $caller eq $args{package_name}
                || $caller->isa( $args{package_name} );

        goto &{$method};
    };
    $args{body} = $protected_code;
    $class->SUPER::wrap(%args);
}

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Meta::Method::Protected

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

