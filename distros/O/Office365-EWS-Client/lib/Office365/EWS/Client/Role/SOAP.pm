use strict;
use warnings;
package Office365::EWS::Client::Role::SOAP;
use Moose::Role;
use Carp;
with 'EWS::Client::Role::SOAP';
sub _build_wsdl {
    my $self = shift;
    XML::Compile->addSchemaDirs( $self->schema_path );
    my $wsdl = eval {
        my $wsdl = XML::Compile::WSDL11->new($self->server_version.'-ews-services.wsdl');
        $wsdl->importDefinitions($self->server_version.'-ews-types.xsd');
        $wsdl->importDefinitions($self->server_version.'-ews-messages.xsd');
        return $wsdl;
    };
    if ( $@ ) {
        croak "$@ Unable to process WSDL. Are you specifying a 'server_version' that has a WSDL bundled (look in 'share' directory) with Office365::EWS::Client?\n";
    }
    return $wsdl;
}
sub _build_schema_path {
    my $self = shift;
    return File::ShareDir::dist_dir('Office365-EWS-Client');
}
has server_version => (
    is => 'ro',
    isa => 'Str',
    default => 'Exchange2010_SP2',
    required => 0,
);
no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Office365::EWS::Client::Role::SOAP

=head1 VERSION

version 1.142410

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
