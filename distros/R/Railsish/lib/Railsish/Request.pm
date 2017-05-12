package Railsish::Request;
our $VERSION = '0.21';

use Any::Moose;

extends 'HTTP::Engine::Request';

__PACKAGE__->meta->make_immutable;

__END__
=head1 NAME

Railsish::Request

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

