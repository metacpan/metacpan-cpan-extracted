package Mojo::Autobox;

use Mojo::Base -strict;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use Mojo::Base 'autobox';

require Mojo::Autobox::String;
require Mojo::Autobox::Array;
require Mojo::Autobox::Hash;

sub import {
  my $class = shift;
  $class->SUPER::import(
    STRING => 'Mojo::Autobox::String',
    ARRAY  => 'Mojo::Autobox::Array',
    HASH   => 'Mojo::Autobox::Hash',
  );
}

1;

=head1 NAME

Mojo::Autobox - Some extra Mojo for Perl native datatypes

=head1 SYNOPSIS

 use Mojo::Base -strict;
 use Mojo::Autobox;

 # "site.com\n"
 '{"html": "<a href=\"http://site.com\"></a>"}'
   ->json('/html')
   ->dom->at('a')->{href}
   ->url->host
   ->byte_stream->say;

=head1 DESCRIPTION

Using L<autobox>, methods are provided to Perl native datatypes.
This ability is then used to provide methods useful with classes from the L<Mojolicious> toolkit.
These are especially useful to contruct objects to continue a "chain" of method invocations.

The effect is lexical, and therefore is contained within the scope that the module is imported into.

=head1 CLASSES

When the pragma is in effect, the types are effectively blessed into the following classes:

=over

=item STRING - L<Mojo::Autobox::String>

=item ARRAY - L<Mojo::Autobox::Array>

=item HASH - L<Mojo::Autobox::Hash>

=back

=head1 ONE-LINERS

Additionally, for one-liner fun, the class L<ojoBox> may be used to load L<Mojo::Autobox> and L<ojo>.

 perl -MojoBox -E 'g("http://mojolicio.us")->dom->find("a")->each(sub{$_->{href}->url->host->b->say})'

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-Autobox>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

