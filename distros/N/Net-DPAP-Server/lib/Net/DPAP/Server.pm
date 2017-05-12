package Net::DPAP::Server;
use strict;
use warnings;
use Net::DPAP::Server::Image;
use File::Find::Rule;
use base qw( Net::DMAP::Server );
our $VERSION = '0.02';

sub protocol { 'dpap' }

sub default_port { 8770 }

sub find_tracks {
    my $self = shift;
    for my $file ( find name => "*.jpeg", in => $self->path ) {
        my $track = Net::DPAP::Server::Image->new_from_file( $file );
        $self->tracks->{ $track->dmap_itemid } = $track;
    }
}

sub server_info {
    my ($self, $request, $response) = @_;
    $response->content( $self->_dmap_pack(
        [[ 'dmap.serverinforesponse' => [
            [ 'dmap.status' => 200 ],
            [ 'dmap.protocolversion' => 2 ],
            [ 'dpap.protocolversion' => 1 ],
            [ 'dmap.itemname' => $self->name ],
            [ 'dmap.loginrequired' =>  0 ],
            [ 'dmap.timeoutinterval' => 0 ],
            [ 'dmap.supportsautologout' => 0 ],
            [ 'dmap.authenticationmethod' => 0 ],
            [ 'dmap.databasescount' => 1 ],
           ]]] ));
}

sub _always_answer {
    my $self = shift;
    return qw( dmap.itemid ) if $self->uri =~ /dpap.(thumb|hires)/;
    return ( $self->SUPER::_always_answer, 'dpap.imagefilename' );
}

1;
__END__

=head1 NAME

Net::DPAP::Server - Provide a DPAP Server

=head1 SYNOPSIS

 use POE;
 use Net::DPAP::Server;

 my $server = Net::DAAP::Server->new(
     path => '/my/photo/album',
     port => 666,
     name => "My holiday snaps",
 );
 $poe_kernel->run;


=head1 DESCRIPTION

Net::DPAP::Server takes a directory of JPEG files and makes it
available to iPhoto and work-alikes which can use the Digital Photo
Access Protocol

=head1 METHODS

=head2 new

Creates a new dpap server, takes the following arguments

=over

=item path

A directory that will be scanned for *.jpeg files to share.

=item name

The name of your DPAP share, will default to a combination of the
module name, hostname, and process id.

=item port

The port to listen on, will default to the default port, 8770.

=back

=head1 CAVEATS

Currently only shares .jpeg files.

Doesn't support albums.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Net::DPAP::Client

=cut
