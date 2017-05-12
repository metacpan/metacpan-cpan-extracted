package OpenPlugin::Session::ApacheSession;

# $Id: ApacheSession.pm,v 1.5 2003/06/10 00:30:23 andreychek Exp $

use strict;
use OpenPlugin::Session();
use base        qw( OpenPlugin::Session );
use Apache::Session::Flex();

$OpenPlugin::Session::ApacheSession::VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);


sub init {
    my ( $self, $args ) = @_;

    my $params = $self->_init_params;

    # FIXME -- I'm not sure this belongs here.  Could we somehow add "File" as
    # a datasource type, and upon a 'connect', do a permissions check?
    if ($params->{Store} eq "File") {
        # Can we write to the session dir, and is it really a directory?
        unless (-w $params->{Directory} and -d $params->{Directory}) {

            # We only do this is it's really a dir, and it's writable
            $params->{Directory} =~ /^(.*)$/;
            $params->{Directory} = $1;

            unless (mkdir $params->{Directory}, 0760) {
                $self->OP->exception->throw(
                    "The session dir ($params->{Directory}) is not writable " .
                    "by the Apache's httpd process! Please change the owner " .
                    "of that directory to the user ID your webserver is "     .
                    "running as."
                );
            }
        }
        # Can we write to the lockfile dir, and is it really a directory?
        unless (-w $params->{LockDirectory} and -d $params->{LockDirectory}) {

            # We only do this is it's really a dir, and it's writable
            $params->{LockDirectory} =~ /^(.*)$/;
            $params->{LockDirectory} = $1;

            unless (mkdir $params->{LockDirectory}, 0760) {
                $self->OP->exception->throw(
                    "The lock dir ($params->{LockDirectory}) is not writable ".
                    "by the Apache's httpd process! Please change the owner " .
                    "of that directory to the user ID your webserver is "     .
                    "running as."
                );
            }
        }
    }

    return $self;
}

# This session connects to the session, and returns data in it as a hashref
sub get_session_data {
    my ( $self, $session_id ) = @_;

    my $params = $self->_init_params;

    my %session = ();

    eval { tie %session, 'Apache::Session::Flex', $session_id, { %$params }; };
    if ( $@ ) {
        $self->OP->log->warn( "Failed to initiate session: $@" );
        return undef;
    }

    return ( \%session );

}

sub _init_params {
    my $self = shift;

    my $params =
        $self->OP->config->{'plugin'}{'session'}{'driver'}{'ApacheSession'};

    # Some reasonable (IMHO) defaults if we haven't been told certain parameters
    $params->{Store}         ||= "File";
    $params->{Lock}          ||= "Null";
    $params->{Generate}      ||= "MD5";
    $params->{Serialize}     ||= "Storable";

    # Untaint values Apache::Session uses as module names
    foreach my $key ( qw( Store Serialize Lock Generate ) ) {
        $params->{ $key } =~ m/^([-\w]+)$/;
        $params->{ $key } = $1;
    }

    if ( $params->{Store} eq "File" ) {
        $params->{Directory}     ||= "/tmp";
        $params->{LockDirectory} ||= "/tmp";

        if ( -d $params->{Directory} ) {
            $params->{Directory} =~ m/^(.*)$/;
            $params->{Directory} = $1;
        }

        if ( -d $params->{LockDirectory} ) {
            $params->{LockDirectory} =~ m/^(.*)$/;
            $params->{LockDirectory} = $1;
        }

    }

    if ( $self->OP->config->{'plugin'}{'session'}{'datasource'} ) {

        $params->{'Handle'} =
         $self->OP->datasource->connect( $self->OP->config->{'plugin'}{'session'}{'datasource'} );
    }

    return $params;
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Session::Apache - Apache driver (using Apache::Session) for the OpenPlugin session plugin

=head1 PARAMETERS

None.

=head1 CONFIG OPTIONS

=over 4

=item * expires

You can set a detault expire time in the config file.  If an expiration is not
passed in with your data to cache, this default time from the config is used.

Example:
expires = +3h

=item * parameters section

See the Apache::Session docs.

You'll also need to define a parameters block, which is used to pass parameters
directly to Apache::Session.  The parameters used depend on the Apache::Session
driver being used.  For instance, the following is what you would define if you
wanted to store session in files:

 <parameters>
    Store         = File
    Directory     = /tmp/openthought   # Directories should begin with a "/"
    LockDirectory = /tmp/openthought
 </parameters

Again, you'll find all of those parameters explained in the Apache::Session
docs.  This driver uses Apache::Session::Flex to interface with
Apache::Session.

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Apache::Session>
L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Session|OpenPlugin::Session>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
