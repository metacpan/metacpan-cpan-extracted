package Solstice::Cookie;

=head1 NAME

Solstice::Cookie - An interface for managing cookies in your solstice apps.

=head1 SYNOPSIS

  my $cookie = Solstice::Cookie->new();
  $cookie->setName('name');
  $cookie->setValue('value');
  $cookie->setExpiration(Solstice::DateTime->new());
  $cookie->bake();

  $cookie->expire();

  my $cookie = Solstice::Cookie->new('name');
  my $value  = Solstice::Cookie->getValue();

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use constant TRUE   => 1;
use constant FALSE  => 0;

use base qw(Solstice::Model);

use CGI::Cookie;

=over 4

=item new()
=item new('cookie_name')

Creates a new cookie.  If passed a name, it will try to find the value for that cookie.

=cut

sub new {
    my $obj = shift;
    my $name = shift;

    my $self = $obj->SUPER::new();

    if (defined $name) {
        $self->_init($name);
    }

    return $self;
}

sub _init {
    my $self = shift;
    my $name = shift;

    my $server = Solstice::Server->new();
    my %cookies = fetch CGI::Cookie;
    my $cookie = $cookies{$name};

    if (defined $cookie) {
        $self->setName($name);
        $self->setValue($cookie->value());
    }

    return TRUE;
}

=item bake()

Sends the cookie to the browser.

=cut

sub bake {
    my $self = shift;

    my $expiration_seconds;
    my $expiration = $self->getExpiration();

    if (defined $expiration) {
        my $current = Solstice::DateTime->new(time);
        $expiration_seconds = $current->getTimeApart($expiration);
    }

    my $path = '/'.Solstice::Configure->new()->getVirtualRoot();
    $path =~ s/\/+/\//g;

    my $expiration_string;
    if (defined $expiration_seconds) {
        $expiration_string = '+'.$expiration_seconds.'s';
    }
    my $cookie = CGI::Cookie->new(
        -name    => $self->getName(),
        -value   => $self->getValue(),
        -expires => (defined $expiration_string ? $expiration_string : undef),
        -path    => $path,
    );

    my $server = Solstice::Server->new();
    $server->addHeader('Set-Cookie', $cookie);
}

sub _getAccessorDefinition {
    return [
    {
        name        => 'Name',
        type        => 'String',
    },
    {
        name        => 'Value',
        type        => 'String',
    },
    {
        name        => 'Expiration',
        type        => 'DateTime',
    },
    ];
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<Solstice::LogService|Solstice::LogService>,
L<Solstice::UserService|Solstice::UserService>,
L<Solstice::ValidationParam|Solstice::ValidationParam>,
L<Solstice::CGI|Solstice::CGI>,
L<Data::FormValidator|Data::FormValidator>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 3177 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut



