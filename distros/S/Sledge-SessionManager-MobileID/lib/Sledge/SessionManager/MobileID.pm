package Sledge::SessionManager::MobileID;
use strict;
use warnings;
use base 'Sledge::SessionManager';

our $VERSION = 0.02;

use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(gettimeofday);

sub new {
    my ($class, $page) = @_;

    $page->add_trigger(
        AFTER_INIT => sub {
            my $page = shift;
            $page->construct_session unless $page->session;
            my $session_class = ref($page->{session}) . "::__MobileID";
            {
                no strict 'refs';
                unless (@{"$session_class\::ISA"}) {
                    unshift @{"$session_class\::ISA"}, ref $page->{session};

                    *{"$session_class\::_gen_session_id"} = sub {
                        my $self = shift;

                        return (
                                $ENV{HTTP_X_UP_SUBNO}
                            || $ENV{HTTP_X_JPHONE_UID}
                            || die "can't get moile id !"
                        );
                    };
                }
            }
            $page->{session} = bless +{ %{$page->{session}} }, $session_class;
        }
    );

    bless {}, $class;
}

sub get_session_id {
    my ( $self, $page ) = @_;

    return ( $page->r->header_in("X_UP_SUBNO")
          || $page->r->header_in("X_JPHONE_UID") );
}

sub set_session_id {}


1;
__END__

=head1 NAME

Sledge::SessionManager::MobileID - Sledge's session manager use mobile phone identify.

=head1 SYNOPSIS

  # in Project::Pages
  use Sledge::SessionManager::MobileID;
  sub create_manager {
      my $self = shift;
      return Sledge::SessionManager::MobileID->new($self);
  }

=head1 DESCRIPTION

Sledge::SessionManager::MobileID is Sledge's session manager use mobile phone identify.
It can use part of KDDI and SoftBank mobile phones.

=head1 AUTHOR

TOKUHIRO Matsuno E<lt>tokuhirom at mobilefactory dot jpE<gt>
KAN Fushihara E<lt>kan at mobilefactory dot jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
