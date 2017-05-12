package Net::MundiPagg;
$Net::MundiPagg::VERSION = '0.000003';
use Moo;
use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;

use File::ShareDir qw{ module_file };

has 'client' => (
    is      => 'ro',
    builder => sub {
        my $wsdl = module_file( ref $_[0], 'mundipagg.wsdl' );
        my $client = XML::Compile::WSDL11->new($wsdl);

        foreach my $i ( 0 .. 2 ) {
            my $xsd = module_file( ref $_[0], "schema$i.xsd" );
            $client->importDefinitions($xsd);
        }

        $client->compileCalls;

        return $client;
    },
);

sub BUILD {
    my ($self) = @_;

    no strict 'refs';    ## no critic(TestingAndDebugging::ProhibitNoStrict)
    foreach my $method ( map { $_->name } $self->client->operations ) {
        *{$method} = sub {
            my ( $this, %args ) = @_;
            return $this->client->call( $method, %args );
        };
    }

    return;
}

1;

#ABSTRACT: Net::MundiPagg - Documentation coming soon :)

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::MundiPagg - Net::MundiPagg - Documentation coming soon :)

=head1 VERSION

version 0.000003

=head1 METHODS

=head2 BUILD

Private method

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
