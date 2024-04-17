package Mojolicious::Plugin::Sessionless 0.01;
use v5.26;
use warnings;

# ABSTRACT: Installs noop handlers to disable Mojolicious sessions

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Sessionless - disable Mojolicious sessions

=head1 SYNOPSIS

    plugin 'Sessionless';

    app->session(key => 'value'); #noop

=head1 DESCRIPTION

L<Mojolicious::Plugin::Sessionless> is an extremely simple plugin that disables
Mojolicious's session support, replacing the Session load/save handlers with
C<noop>s

=head1 METHODS

L<Mojolicious::Plugin::Sessionless> inherits all methods from L<Mojolicious::Plugin>
and implements the following new onees

=head2 register

Register plugin in L<Mojolicious> application. Takes no parameters.

=head2 load

Load session data. Noop.

=head2 store

Store session data. Noop.

=cut

use Mojo::Base 'Mojolicious::Plugin';

use experimental qw(signatures);

sub register($self, $app, $conf) {
  $app->sessions(bless({}, '__Sessionless'));
  {
    no strict 'refs';
    *{'__Sessionless::load'} = *{'__Sessionless::store'} = sub { };
  }
}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
