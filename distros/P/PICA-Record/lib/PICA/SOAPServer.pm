package PICA::SOAPServer;
{
  $PICA::SOAPServer::VERSION = '0.585';
}
#ABSTRACT: Provide a SOAP interface to a L<PICA::Store>
use strict;
use warnings;

use SOAP::Lite;
use PICA::Record;

our @ISA = qw(Exporter SOAP::Server::Parameters);


# private functions to wrap SOAP nightmare

# die with a SOAP fault
my $fault = sub {
    my ($code, $string) = @_;
    die SOAP::Fault->new( faultcode => $code, faultstring => $string );
};

# unpack a SOAP envelope with named parameters of type string
my $unpack = sub {
    my ($envelope, $required, $optional) = @_;
    my %result;
    foreach my $name ((@$required,@$optional)) { 
        my $param = $envelope->dataof($name);
        $result{$name} = $param->value if $param;
    }
    foreach my $name (@$required) {
        $fault->("BADREQUEST", "Missing parameter $name") 
            unless defined $result{$name};
    }

    return %result;
};

# pack a SOAP response object
my $pack = sub {
    my (%values) = @_;
    return SOAP::Data->name( "response" =>
        \SOAP::Data->value(  
            SOAP::Data->name('dbsid'   => $values{'dbsid'})->type('string'),  
            SOAP::Data->name('ppn'     => $values{'ppn'})->type('string'),  
            SOAP::Data->name('record'  => $values{'record'})->type('string'),  
            SOAP::Data->name('version' => $values{'version'})->type('string'),
            SOAP::Data->name('format'  => 'pp')->type('string'),  
        )  
    );
};


sub new {
    my ($class, $store) = @_;
    my $self = bless {
        store => $store
    }, $class;
    if (not UNIVERSAL::isa( $store, 'PICA::Store' ) ) {
        $self->{error} = $store ? "$store" : 'No PICA::Store available';
        $self->{store} = undef;
    }
    return $self;
}


sub get {
    my $self = shift;
    my $env = pop;
    my %params = $unpack->($env, [qw(userkey password dbsid ppn)], [qw(language format)]);
    $fault->(1, $self->{error}) unless $self->{store};

    my %r = $self->{store}->access( %params )->get( $params{ppn} );
    $fault->($r{errorcode}, $r{errormessage}) if defined $r{errorcode};
    
    return $pack->(
        ppn => $r{id},
        record => $r{record}->string,
        version => $r{version},
        dbsid => $params{dbsid}
    );
}


sub create {
    my $self = shift;
    my %params = $unpack->(pop, [qw(userkey password dbsid record)], [qw(language format rectype)]);
    $fault->(1, $self->{error}) unless $self->{store};

    my %r = $self->{store}->access( %params )->create( PICA::Record->new($params{record}) );
    $fault->($r{errorcode}, $r{errormessage}) unless defined $r{id};

    return $pack->(
        ppn => $r{id},
        record => $r{record}->string,
        version => $r{version},
        dbsid => $params{dbsid}
    );
}


sub update {
    my $self = shift;
    my %params = $unpack->(pop, [qw(userkey password dbsid ppn record version)], [qw(language format)]);
    $fault->(1, $self->{error}) unless $self->{store};

    my %r = $self->{store}->access( %params )
          -> update( $params{ppn}, PICA::Record->new($params{record}), $params{version} );
    $fault->($r{errorcode}, $r{errormessage}) unless defined $r{id};

    return $pack->(
        ppn => $r{id},
        record => $r{record}->string,
        version => $r{version},
        dbsid => $params{dbsid}
    );
}


sub delete {
    my $self = shift;
    my %params = $unpack->(pop, [qw(userkey password dbsid ppn)], [qw(language)]);
    $fault->(1, $self->{error}) unless $self->{store};

    # get the record before deleting
    my %r = $self->{store}->access( %params )->get( $params{ppn} );
    $fault->($r{errorcode}, $r{errormessage}) if defined $r{errorcode};

    # actually delete it
    my %r2 = $self->{store}->access( %params )->delete( $params{ppn} );
    $fault->( $r2{errorcode}, $r2{errormessage} ) unless defined $r2{id};

    return $pack->(
        ppn => $r{id},
        record => $r{record}->string,
        version => $r{version},
        dbsid => $params{dbsid}
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::SOAPServer - Provide a SOAP interface to a L<PICA::Store>

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  use PICA::SOAPServer;
  use PICA::SQLiteStore;
  use SOAP::Transport::HTTP;

  my $dbfile = "path/to/picawiki.db";
  my $store = eval { PICA::SQLiteStore->new( $dbfile ); } || $@;
  my $server = PICA::SOAPServer->new( $store );

  SOAP::Transport::HTTP::CGI   
    -> serializer( SOAP::Serializer->new->envprefix('soap') )
    -> dispatch_with( { 'http://www.gbv.de/schema/webcat-1.0' => $server } )
    -> handle;

=head1 DESCRIPTION

THIS CLASS WILL BE REMOVED IN A FUTURE RELEASE!

This class wraps the CRUD-methods (create, get, update, delete) of 
a given L<PICA::Store> and makes them accessible via SOAP. This way
you can provide a so called PICA Webcat interface for a database
of PICA+ records. See L<PICA::SOAPClient> for a webcat client interface.

Each SOAP method returns five named values of type string:

=over

=item ppn

The id (PPN) of the record

=item record

The record as string

=item version

The version of the record

=item dbsid

The database id the record was accessed in (may be the empty string)

=item format

The record format which is always 'pp' for PICA+.

=back

=head1 METHODS

=head2 new ( $store )

Create a new SOAPServer with underlying L<PICA::Store>. This method is not
meant to be called via SOAP but to initialize a server. The server can then 
be run this way:

  $server = PICA::SOAPServer->new ( $store );
  SOAP::Transport::HTTP::CGI   
    -> dispatch_with( { 'http://www.gbv.de/schema/webcat-1.0' => $server } )
    -> handle;

=head2 get

Retrieve a PICA+ record by its id (ppn). Mandatory SOAP parameters are ppn,
userkey, password, and dbsid. Optional parameters are language and format.

=head2 create

Create a new PICA+ record. Mandatory SOAP parameters are record, userkey,
password, and dbsid. Optional parameters are language, format, and rectype.

=head2 update

Modify an existing PICA+ record. Mandatory SOAP parameters are ppn, record,
version, userkey, password, and dbsid. Optional parameters are language 
and format.

=head2 delete

Delete a PICA+ record. Mandatory SOAP parameters are ppn, userkey, password,
and dbsid. The only optional parameter is language.

=head1 SEE ALSO

See L<PICA::Store>, L<PICA::SOAPClient> and L<SOAP::Lite>.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
