package SRU::Request::Explain;
{
  $SRU::Request::Explain::VERSION = '1.01';
}
#ABSTRACT: A class for representing SRU explain requests

use strict;
use warnings;
use base qw( Class::Accessor SRU::Request );
use SRU::Utils qw( error );


sub new {
    my ($class,%args) = @_;
    return SRU::Request::Explain->SUPER::new( \%args );
}


my @validParams = qw( 
    version 
    recordPacking 
    stylesheet 
    extraRequestData 
);


# no pod since this is used in SRU::Request
sub validParams { return @validParams };

SRU::Request::Explain->mk_accessors( @validParams, 'missingOperator' ); 

1;

__END__

=pod

=head1 NAME

SRU::Request::Explain - A class for representing SRU explain requests

=head1 SYNOPSIS

    ## creating a new request
    my $request = SRU::Request::Explain->new();

=head1 DESCRIPTION

SRU::Request::Explain is a class for representing SRU 'explain' requests. 
Explain requests essentially ask the server to describe its services.

=head1 METHODS

=head2 new()

The constructor, which you can pass the optional parameters parameters: 
version, recordPacking, stylesheet, and extraRequestData parameters.

    my $request = SRU::Request::Explain->new( 
        version     => '1.1',
        stylesheet  => 'http://www.example.com/styles/mystyle.xslt'
    );

Normally you'll probably want to use the factory SRU::Response::newFromURI
to create requests, instead of calling new() yourself.

=cut

=head2 version()

=head2 recordPacking()

=head2 stylesheet()

=head2 extraRequestData()

=cut

=head2 validParams()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
