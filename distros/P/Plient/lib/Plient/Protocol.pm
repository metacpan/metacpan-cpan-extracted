package Plient::Protocol;

use warnings;
use strict;
use Carp;

sub prefix { warn "needs subclass prefix"; '' }
sub methods { warn "needs subclass methods"; '' }

sub support_method {
    # trans $args here to let handlers to decide to pass or not
    my ( $class, $method_name, $args ) = @_;
    $method_name = lc $method_name;
    $args ||= {};

    if ( ! $args->{check_only} && !grep { $method_name eq $_ } $class->methods ) {
        warn "$method_name for $class is not officially supported yet";
    }

    return $class->can($method_name) if $class->can($method_name);
    my $handler_method_name = $class->prefix . "_$method_name";
    for my $handler ( Plient->handlers( $class->prefix ) ) {
        $handler->init if $handler->can('init');
        if ( my $method =
            $handler->support_method( $handler_method_name, $args ) )
        {
            return $method;
        }
    }
    warn "$handler_method_name is not supported in available handlers"
      unless $args->{check_only};
    return;
}

1;

__END__

=head1 NAME

Plient::Protocol - 


=head1 SYNOPSIS

    use Plient::Protocol;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

