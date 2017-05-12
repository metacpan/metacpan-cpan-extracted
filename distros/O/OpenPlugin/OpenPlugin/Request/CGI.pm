package OpenPlugin::Request::CGI;

# $Id: CGI.pm,v 1.7 2003/04/03 01:51:26 andreychek Exp $

use strict;
use OpenPlugin::Param();
use base   qw( OpenPlugin::Param );
use CGI    qw( -no_debug );

$OpenPlugin::Request::CGI::VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    unless ( $self->state->{'cgi'} ) {

        # Use an existing CGI object if given one
        if(( not exists $self->state->{'cgi'} ) &&
           ( ref $args->{'cgi'} eq "CGI" )) {

            $self->state->{'cgi'} = $args->{'cgi'};
        }
        # Otherwise, create a new one
        else {
            $self->state->{'cgi'} = CGI->new();
        }
    }

    # Set the uri
    $self->state->{'uri'} = $self->state->{'cgi'}->url;

    return $self;
}


sub object { my $self = shift; return $self->state->{'cgi'}; }
sub uri    { my $self = shift; return $self->state->{'uri'}; }

1;

__END__

=pod

=head1 NAME

OpenPlugin::Request::CGI - CGI driver for the OpenPlugin::Request plugin

=head1 PARAMETERS

You may optionally pass in an existing CGI object.  For example:

 my $q = CGI->new();
 my $OP = OpenPlugin->new( request => { cgi => $q } );

This is typically unnecessary.  If you do not pass in a CGI object, one will be
created for you.

After the plugin is initialized, the CGI object is accessible
to you using:

 $q = $OP->request->object();

=head1 CONFIG OPTIONS

=over 4

=item * driver

CGI

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

OpenPlugin, OpenPlugin::Param, CGI

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
