package POE::Component::Server::Bayeux::Message::Factory;

=head1 NAME

POE::Component::Server::Bayeux::Message::Factory - create messages in the right subclass

=head1 DESCRIPTION

Implements create(), which will find the appropriate Message subclass to handle the data packet.

=cut

use strict;
use warnings;
use POE qw(
    Component::Server::Bayeux::Message::Invalid
    Component::Server::Bayeux::Message::Meta
    Component::Server::Bayeux::Message::Service
    Component::Server::Bayeux::Message::Publish
);

use Params::Validate qw(validate HASHREF ARRAYREF);

sub create {
    my $class = shift;

    my %args = validate(@_, {
        request => 1,
        data    => { type => HASHREF },
    });

    my $channel = $args{data}{channel};

    my $build_class;
    if (! $channel) {
        $build_class = 'Invalid';
    }
    elsif ($channel =~ m{^/meta/}) {
        $build_class = 'Meta';
    }
    elsif ($channel =~ m{^/service/}) {
        $build_class = 'Service';
    }
    else {
        $build_class = 'Publish';
    }

    $build_class = 'POE::Component::Server::Bayeux::Message::' . $build_class;
    return $build_class->new(%args);
}

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut

1;
