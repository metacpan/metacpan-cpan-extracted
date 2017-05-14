package Office365::EWS::GAL::Role::Reader;
use Moose::Role;

use Office365::EWS::GAL::ResultSet;
use Carp;

sub _check_for_errors {
    my ($self, $kind, $response) = @_;

    my $code = $response->{"${kind}Result"}->{ResponseCode} || '';
    croak "Fault returned from Exchange Server: $code\n"
        if $code ne 'NoError';
}

sub _list_galitems {
    my ($self, $kind, $response) = @_;

    return map  { $_->{Persona} }
           grep { defined $_->{'Persona'}->{'DisplayName'} and length $_->{'Persona'}->{'DisplayName'} }
           map  { @{ $_->{People}->{cho_Persona} || [] } }
           map  { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map  { $_->{"${kind}Result"} } 
                  $response;
}

sub _get_gal {
    my ($self, $opts) = @_;

    return scalar $self->client->FindPeople->(
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        RequestVersion => {
            Version => $self->client->server_version,
        },
        ParentFolderId => {
                DistinguishedFolderId =>
                    {
                        Id => 'directory',
                    }
        },
        IndexedPageItemView => {
                MaxEntriesReturned => '100',
                Offset => 0,
                BasePoint => 'Beginning',
        },
        QueryString => $opts->{querystring},
    );
}

sub retrieve {
    my ($self, $opts) = @_;

    my $get_response = $self->_get_gal($opts);

    $self->_check_for_errors('FindPeople', $get_response);

    return Office365::EWS::GAL::ResultSet->new({
        items => [ $self->_list_galitems('FindPeople', $get_response) ]
    });
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Office365::EWS::GAL::Role::Reader

=head1 VERSION

version 1.142410

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
