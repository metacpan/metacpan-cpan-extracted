package PICA::Store;
{
  $PICA::Store::VERSION = '0.585';
}
#ABSTRACT: CRUD interface to a L<PICA::Record> storage
use strict;

use Config::Simple;
use PICA::SOAPClient;
use PICA::SQLiteStore;
use Carp qw(croak);
use Cwd qw(cwd abs_path);



sub new {
    my ($class, %params) = (@_);

    readconfigfile( \%params, $ENV{PICASTORE} )
        if exists $params{config} or exists $params{conf} ;

    return PICA::SOAPClient->new( %params ) if defined $params{webcat};
    return PICA::SQLiteStore->new( %params ) if defined $params{SQLite};

    croak('please specify a store type (webcat/SQLite) - possibly in a config file');
}


sub get {
    croak('abstract method "get" is not implemented');  
}


sub create {
    croak('abstract method "create" is not implemented');  
}


sub update {
    croak('abstract method "update" is not implemented');  
}


sub delete {
    croak('abstract method "delete" is not implemented');  
}


sub access {
    my ($self, %params) = @_;

    for my $key (qw(userkey password dbsid language)) {
        # do nothing
    }

    return $self;
}


sub about {
    my $self = shift;
    return ref($self);
}


sub readconfigfile {
    my ($params, $defaultfile) = @_;

    return unless exists $params->{conf} or exists $params->{config};

    $params->{config} = $params->{conf} unless defined $params->{config};

    if ( not defined $params->{config} ) {
        if ( $defaultfile ) {
            $params->{config} = $defaultfile;
        } elsif (-e cwd.'/pica.conf' ) {
            $params->{config} = cwd.'/pica.conf' ;   
        }
    }

    my $cfile = $params->{config};
    return unless defined $cfile;

    my %config;

    croak("config file not found: $cfile") unless -e $cfile;
    Config::Simple->import_from( $cfile, \%config)
        or croak( "Failed to parse config file $cfile" );

    while (my ($key, $value) = each %config) {
        $key =~ s/default.//; # remove default namespace
        # TODO: add support of blocks/namespaces in config file
        $params->{$key} = $value unless exists $params->{$key};
    }
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::Store - CRUD interface to a L<PICA::Record> storage

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  use PICA::Store;

  # connect to store via SOAP API (SOAPClient)
  $store = PICA::Store->new( webcat => $baseurl, %params );

  # connect to SQLiteStore
  $store = PICA::Store->new( SQLite => $dbfile, %params );

  # Get connection details from a config file
  $store = PICA::Store->new( config => "myconf.conf" );

  # CRUD operations
  %result = $store->get( $id );
  %result = $store->create( $record );
  %result = $store->update( $id, $record, $version );
  %result = $store->delete( $id );

  # set additional access parameters
  $store->access( userkey => $userkey, password => $passwd );

=head1 DESCRIPTION

This class is an abstract class to provide a simple CRUD
(create/insert, retrieve/get, update, delete) access to a 
record store of L<PICA::Record> objects. 

See L<PICA::SQLiteStore> and L<PICA::SOAPClient> for specific
implementations. Other implementations that may be implemented
later include WebDAV, and REST (for instance Jangle).

=head1 METHODS

=head2 new ( %parameters )

Return a new PICA::Store. You must either specify a parameter named
'webcat' to get a L<PICA::SOAPClient> or a parameter named 'SQLite' 
to get a L<PICA::SQLiteStore>. Alternatively you can specify a
parameter named 'config' that points to a configuration file. 
If you set this parameter to undef, the file will be searched as
environment variable PICASTORE or pica.conf in the current 
directory.

=head2 get ( $id )

Retrieve the latest revision of record by ID. Returns a hash with either
'errorcode' and 'errormessage' or a hash with 'id', 'record' 
(a L<PICA::Record> object), 'version', and 'timestamp'.

=head2 create ( $record )

Insert a new record. The parameter must be a L<PICA::Record> object.
Returns a hash with either 'errorcode' and 'errormessage' or a hash
with 'id', 'record', 'version', and 'timestamp'.

=head2 update ( $id, $record [, $version ] )

Update a record by ID, updated record (of type L<PICA::Record>),
and version (of a previous get, create, or update command).

Returns a hash with either 'errorcode' and 'errormessage'
or a hash with 'id', 'record', 'version', and 'timestamp'.

=head2 delete ( $id )

Delete a record by ID. Returns a hash with either 'errorcode' and 
'errormessage' or a hash with 'id'.

=head2 access ( key => value ... )

Set general access parameters (userkey, password, dbsid and/or language).
Returns the store itself so you can chain anothe method call. By default
the parameters are just ignored so any subclass should override this 
method to make sense of it.

=head2 about

Return a string with printable information about this store, for
instance a name and/or a base URL.

=head1 INTERNAL FUNCTIONS

=head2 readconfigfile ( $hashref, $defaultfile )

Expand a hash with config parameters by reading from a config file.
The config file may be set in C<$hashref-E<gt>{config}> or the file
C<$defaultfile> or in the file C<pica.conf> in the current directory.

=head1 SEE ALSO

This distribution contains the command line client C<picawebcat> 
based on PICA::Store. See also L<PICA::SQLiteStore>, L<PICA::SOAPClient>,
and L<PICA::SOAPServer>.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
