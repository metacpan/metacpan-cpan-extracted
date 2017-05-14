package Office365::EWS::Client::Role::FindPeople;
use Moose::Role;
has FindPeople => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);
sub _build_FindPeople {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'FindPeople',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindPeople' ),
    );
}
no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Office365::EWS::Client::Role::FindPeople

=head1 VERSION

version 1.142410

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
