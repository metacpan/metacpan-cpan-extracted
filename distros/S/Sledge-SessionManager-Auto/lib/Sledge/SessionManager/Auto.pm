package Sledge::SessionManager::Auto;

use strict;
use warnings;
use base 'Sledge::SessionManager';
our $VERSION = '0.04';

use Sledge::SessionManager::Cookie;
use Sledge::SessionManager::StickyQuery;
use Sledge::SessionManager::MobileID;
use HTTP::MobileAgent;

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    no strict 'refs';
    *{"$pkg\::redirect"} = sub {
        my ($self,) = @_;

        my $meth = (
            $self->mobile_agent->is_non_mobile
              or ( $ENV{HTTP_X_UP_SUBNO} || $ENV{HTTP_X_JPHONE_UID} )
          )
          ? 'Sledge::Pages::Base::redirect'
          : 'Sledge::SessionManager::StickyQuery::redirect_filter';

        $meth->(@_);
    };
}

sub new {
    my ( $class, $page ) = @_;

    my $klass =
      $page->mobile_agent->is_non_mobile
      ? 'Sledge::SessionManager::Cookie'
      : ( $ENV{HTTP_X_UP_SUBNO} || $ENV{HTTP_X_JPHONE_UID} )
        ? 'Sledge::SessionManager::MobileID'
        : 'Sledge::SessionManager::StickyQuery';

    my $self = $klass->new($page);
    return $self;
}

1;
__END__

=head1 NAME

Sledge::SessionManager::Auto - Sledge's session manger switcher

=head1 SYNOPSIS

  # in Controller
  use Sledge::SessionManager::Auto;
  sub create_manager {
      my $self = shift;
      return Sledge::SessionManager::Auto->new($self);
  }

=head1 DESCRIPTION

Sledge::SessionManager::Auto is Sledge's session manger switcher.
If user agent is non mobile, use L<Sledge::SessionManager::Cookie>.
If user agent is mobile phone and can use mobile identify, use L<Sledge::SessionManager::Mobile>.
If user agent is mobile phone, use L<Sledge::SessionManager::StickyQuery>.

=head1 AUTHOR

TOKUHIRO Matsuno E<lt>tokuhirom at mobilefactory dot jpE<gt>
KAN Fushihara E<lt>kan at mobilefactory dot jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
