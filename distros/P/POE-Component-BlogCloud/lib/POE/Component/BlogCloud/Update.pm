# $Id: Update.pm 1783 2005-01-09 05:44:52Z btrott $

package POE::Component::BlogCloud::Update;
use strict;
use base qw( Class::Accessor );

__PACKAGE__->mk_accessors(qw( uri name service feed_uri updated_at ));

1;
__END__

=head1 NAME

POE::Component::BlogCloud::Update - Represents an update to a weblog

=head1 SYNOPSIS

    ## In a ReceivedUpdate handler...
    my($update) = $_[ ARG0 ];
    print "Weblog ", $update->uri, " updated at ", $update->updated_at, "\n";

=head1 DESCRIPTION

I<POE::Component::BlogCloud::Update> represents an update to a weblog
received through the blo.gs streaming cloud server.

=head1 USAGE

=head2 $update->uri

The URI of the weblog.

=head2 $update->name

The name of the weblog.

=head2 $update->feed_uri

The feed URI for the weblog.

=head2 $update->updated_at

A I<DateTime> object representing the date and time at which the weblog
was updated.

=head2 $update->service

The service through which the update was found.

=head1 AUTHOR & COPYRIGHT

Please see the I<POE::Component::BlogCloud> manpage for author, copyright,
and license information.

=cut
