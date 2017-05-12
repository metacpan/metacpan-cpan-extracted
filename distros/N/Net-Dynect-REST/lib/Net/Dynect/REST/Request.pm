package Net::Dynect::REST::Request;
# $Id: Request.pm 149 2010-09-26 01:33:15Z james $
use strict;
use warnings;
use Carp;
use overload '""' => \&_as_string;
our $VERSION = do { my @r = (q$Revision: 149 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::Request - A request object to supply to Dynect

=head1 SYNOPSIS

 use Net::Dynect::REST::Request;
 $request = Net::Dynect::REST::Request->new(operation => 'read', service => 'Zone', params => {zone => 'example.com'});

=head1 DESCRIPTION

The Request object in the REST interface will form the basis of the underlying HTTP request that is made to the REST server. It will format the optional parameters in one of the supported formats.

=head1 METHODS

=head2 Creating

=over 4

=item new

This creator method will return a new Net::Dynect::REST::Request object. You may use the following arguments:

=over 4

=item * operation => $value

The operation is either 'create', 'read', 'update', or 'delete' (CRUD).

=item * service => $service

The service is the end of the URI that will handle the request. The base of the URI, including hte protocol, server name and port, and a base path, is already known in the session object - your session should already be established to pass this request to be executed. Hence the I<service> value is one of a list as documented in the manual (eg, I<Zone>). Note this is B<case sensative>.

=item * params => {list => $value1, of => $value2, parameters => $values3);

A reference to a hash with the set of parameters being passed to the service. The exact list of valid parameters depends upon the service being accessed; it may be a zone name, a record name, etc.

=back

=back

=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;

    $self->operation( $args{operation} ) if defined $args{operation};

    $self->service( $args{service} ) if defined $args{service};
    $self->params( $args{params} )   if defined $args{params};

    return $self;
}

=head2 Attributes

=over 4

=item operation

This is the operation to perform upon the service. It is one of:

=over 4

=item * create

=item * read

=item * update

=item * delete

=back

=cut

sub operation {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^create|read|update|delete$/ ) {
            carp
"Invalid operation: $new. Must be one of create, read, update, delete (CRUD)";
            return;
        }
        $self->{operation} = $new;
    }
    return $self->{operation};
}

=item service 

This is the end of the URI that will handle the REST request. There is a long list of the implemented services in the Dynect REST API manual. 

=cut

sub service {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~
/^Session|QPSReport|ACL|Contact|Password|User|AAAARecord|ANYRecord|ARecord|CNAMERecord|DNSKEYRecord|DSRecord|KEYRecord|LOCRecord|MXRecord|NSRecord|PTRRecord|RPRecord|SOARecord|SRVRecord|TXTRecord|Job|Node|NodeList|Secondary|Zone|ZoneChanges(\/.*)?$/
          )
        {
            carp "Invalid service. See manual for list of valid services.";
            return;
        }
        $self->{service} = $new;
    }
    return $self->{service};
}

=item format 

This is the format that we will send our request in, and hope to recieve our response in. It is one of:

=over 4

=item * JSON

=item * XML

=item * YAML

=item * HTML

=back

=cut

sub format {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^JSON|XML|YAML|HTML$/ ) {
            carp "Invalid format. Must be one of JSON, XML, YAML, or HTML.";
            return;
        }
        $self->{format} = $new;
    }
    return $self->{format} || "JSON";
}

=item mime_type

This returns the mime type for the L</format> already selected.

=cut

sub mime_type {
    my $self = shift;

    if ( not defined $self->format ) {
        carp "format() needs to be set";
        return;
    }
    return "application/json" if $self->format eq "JSON";
    return "text/xml"         if $self->format eq "XML";
    return "application/yaml" if $self->format eq "YAML";
    return "text/html"        if $self->format eq "HTML";
}

=item params

This is a hash reference of the parameters to be supplied with the request, if any. The valid parameters depend upon the service being accessed and the operation being performed.

=cut

sub params {
    my $self = shift;
    if (@_) {
        $self->{params} = shift;
    }

    if ( $self->format eq "JSON" ) {

        # If we have no params, just return.
        return unless defined $self->{params};
        require JSON;
        JSON->import('encode_json');
        return encode_json( $self->{params} );
    }
    if ( $self->format eq "YAML" ) {

        # If we have no params, just return.
        return unless defined $self->{params};
        require YAML;
        YAML->import('Dump');
        return Dump( $self->{params} );
    }
    return $self->{params};
}

sub _as_string {
    my $self = shift;
    my @texts;
    push @texts, sprintf "Operation: '%s'", $self->operation
      if defined $self->operation;
    push @texts, sprintf "Service: '%s'", $self->service
      if defined $self->service;
    push @texts, sprintf "Format: '%s'", $self->format
      if defined $self->operation;
    push @texts, sprintf "Params: '%s'", $self->params if defined $self->params;
    return join( "\n", @texts );
}

=back 

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::info>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
