package SPOPS::Tool::LDAP::Datasource;

# $Id: Datasource.pm,v 3.3 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( ERROR OK NOTIFY );

my $log = get_logger();

$SPOPS::Tool::LDAP::Datasource::VERSION = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

sub behavior_factory {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Installing LDAP datasource configuration for ($class)" );
    return { manipulate_configuration => \&datasource_access };
}

my $generic_ds_sub = <<'DS';

sub %%CLASS%%::global_datasource_handle {
    my ( $class ) = @_;
    unless ( $%%CLASS%%::LDAP ) {
        require Net::LDAP;
        $%%CLASS%%::LDAP = Net::LDAP->new( '%%HOST%%', port    => %%PORT%%,
                                                       version => %%VERSION%% )
                              or SPOPS::Exception->throw( "Cannot connect to LDAP directory: $@" );
        $%%CLASS%%::LDAP->bind(%%BIND_INFO%%);
    }
    return $%%CLASS%%::LDAP;
}
DS

sub datasource_access {
    my ( $class ) = @_;
    my $ldap_config = $class->CONFIG->{ldap_config};

    my $host    = $ldap_config->{host} || 'localhost';
    my $port    = $ldap_config->{port} || 389;
    my $version = $ldap_config->{version} || 2;

    my $bind_info = '';
    if ( $ldap_config->{bind_dn} ) {
        $bind_info = " dn => '$ldap_config->{bind_dn}', " .
                     " password => '$ldap_config->{bind_password}' ";
    }

    my $ds_code = $generic_ds_sub;
    $ds_code =~ s/%%CLASS%%/$class/g;
    $ds_code =~ s/%%HOST%%/$host/g;
    $ds_code =~ s/%%PORT%%/$port/g;
    $ds_code =~ s/%%VERSION%%/$version/g;
    $ds_code =~ s/%%BIND_INFO%%/$bind_info/g;
    {
        local $SIG{__WARN__} = sub { return undef };
        eval $ds_code;
    }
    if ( $@ ) {
        warn "Code: $ds_code\n";
        return ( ERROR, "Cannot create 'global_datasource_handle() for ($class): $@" );
    }
    return ( OK, undef );
}

1;

__END__

=head1 NAME

SPOPS::Tool::LDAP::Datasource -- Embed the parameters for a LDAP handle in object configuration

=head1 SYNOPSIS

 # Connect to a server running on localhost:389 using an anonymous
 # bind (no username/password)

 my $spops = {
   myobject => {
     class      => 'My::Object',
     rules_from => [ 'SPOPS::Tool::LDAP::Datasource' ]
     field      => [ qw/ cn sn givenname displayname mail
                         telephonenumber objectclass uid ou / ],
     id_field   => 'uid',
     ldap_base_dn => 'ou=People,dc=MyCompany,dc=com',
     ...
   },
 };
 SPOPS::Initialize->process({ config => $spops });
 my $ldap_filter = '&(objectclass=inetOrgPerson)(mail=*cwinters.com)';
 my $list = My::Object->fetch_group({ where => $ldap_filter });
 foreach my $object ( @{ $list } ) {
     print "Name: $object->{givenname} at $object->{mail}\n";
 }

=head1 DESCRIPTION

This rule allows you to embed the LDAP connection information in your
object rather than using the strategies described elsewhere. This is
very handy for creating simple, one-off scripts, but you should still
use the subclassing strategy from
L<SPOPS::Manual::Cookbook|SPOPS::Manual::Cookbook> if you will have
multiple objects using the same datasource.

=head1 METHODS

B<behavior_factory( $class )>

Generates a behavior to generate the datasource retrieval code during
the 'manipulate_configuration' phase.

B<datasource_access( $class )>

Generates the 'global_datasource_handle()' method that retrieves an
opened database handle if it exists or creates one otherwise.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration>

L<SPOPS::LDAP|SPOPS::LDAP>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Thanks to jeffa on PerlMonks
(http://www.perlmonks.org/index.pl?node_id=18800) for suggesting this!
