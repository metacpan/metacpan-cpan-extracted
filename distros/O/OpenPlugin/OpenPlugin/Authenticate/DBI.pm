package OpenPlugin::Authenticate::DBI;

# $Id: DBI.pm,v 1.11 2003/04/03 01:51:24 andreychek Exp $

use strict;
use OpenPlugin::Authenticate();
use base          qw( OpenPlugin::Authenticate );

#use OpenPlugin::Authenticate();
#$OpenPlugin::Authenticate::DBI::ISA = qw( OpenPlugin::Authenticate );

$OpenPlugin::Authenticate::DBI::VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

sub authenticate {
    my ($self, $args) = @_;

    return 0 if $args->{username} eq "";

    my $ret = 0;

    $args->{username_field} ||= "username";
    $args->{password_field} ||= "password";
    $args->{table}          ||= "";

    $self->OP->exception->throw ("No datasource or table argument given" )
         unless (($args->{datasource}) && ($args->{table}));

    $self->OP->log->info( "Authenticating $args->{username}");

    my $dbh = eval { $self->OP->datasource->connect( $args->{datasource} ); };

    if ( $@ ) {
        $self->OP->exception->throw("Connection Error: $@\n");
    }

    my $sth = $dbh->prepare("SELECT $args->{username_field} FROM " .
                            "$args->{table} where $args->{username_field} = " .
                            "'$args->{username}' and "     .
                            "$args->{password_field} = " .
                            "'$args->{password}'");
    $sth->execute;

    my $row = $sth->fetchrow_hashref;

    $ret = 1 if $row->{ $args->{username_field} } eq $args->{username};

    $self->OP->log->info( "Authenticate returned ($ret)");

    return($ret);
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Authenticate::DBI - Authenticate using DBI

=head1 SYNOPSIS

 my $OP = OpenPlugin->new({ config_src => 'myconf.xml' });

 $OP->Authenticate->authenticate({ username => 'foo',
                                   password => 'bar',
                                   service  => 'ldap' });


=head1 DESCRIPTION

This driver authenticates users via DBI.  For a given username and password,
they will be authenticated based on a username and password listed in the
database.

=head1 METHODS

B<authenticate()>

Tests the credentials of a user.

Returns: True is successful, false otherwise.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
