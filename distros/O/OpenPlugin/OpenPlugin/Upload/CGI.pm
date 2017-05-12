package OpenPlugin::Upload::CGI;

# $Id: CGI.pm,v 1.11 2003/04/03 01:51:26 andreychek Exp $

use strict;
use OpenPlugin::Upload();
use base   qw( OpenPlugin::Upload );
use CGI    qw( -no_debug );

$OpenPlugin::Upload::CGI::VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    return $self unless $self->OP->request->object;

    foreach my $field ( $self->OP->request->object->param() ) {
        my $fh = $self->OP->request->object->upload( $field );
        next unless ( $fh );

        my $cgi_filename = $self->OP->request->object->param( $field );
        my $upload_info  = $self->OP->request->object->uploadInfo( $cgi_filename );

        # TODO: Ensure this works
        my ( $filename ) = $upload_info->{'Content-Disposition'} =~ /filename="(.*?)"/;

        $self->set_incoming({
                              name         => $field,
                              content_type => $upload_info->{'Content-Type'},
                              size         => (stat $fh)[7],
                              filehandle   => $fh,
                              filename     => $filename,
        });

    }

    return $self;
}


#sub new {}

#sub name {}

#sub filename {}

#sub fh { my $u = shift; return $u->filehandle( @_ ) }

#sub filehandle {}

#sub type { my $u = shift; return $u->content_type( @_ ) }

#sub content_type {}

#sub size {}

1;

=pod

=head1 NAME

OpenPlugin::Upload::CGI - CGI driver for the OpenPlugin::Upload plugin

=head1 PARAMETERS

You may optionally pass in an existing CGI object.  For example:

 my $q = CGI->new();
 my $OP = OpenPlugin->new( request => { cgi => $q } );

This is typically unnecessary.  If you do not pass in a CGI object, one will be
created for you.

After the plugin is initialized, the CGI object is accessible
to you using:

 $q = $OP->state->{ request }{ cgi };

=head1 CONFIG OPTIONS

=over 4

=item 4 driver

CGI

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<CGI|CGI>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
