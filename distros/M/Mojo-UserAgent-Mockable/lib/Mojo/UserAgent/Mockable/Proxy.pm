use 5.014;

# ABSTRACT: Proxy class for Mojo::UserAgent::Mockable that will not set any proxy.

package Mojo::UserAgent::Mockable::Proxy;
$Mojo::UserAgent::Mockable::Proxy::VERSION = '1.56';
use Mojo::Base 'Mojo::UserAgent::Proxy';

1;
sub detect { # Do not set any proxy 
    return; 
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Mockable::Proxy - Proxy class for Mojo::UserAgent::Mockable that will not set any proxy.

=head1 VERSION

version 1.56

=head1 AUTHOR

Kit Peters <popefelix@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
