package Net::SAML2::AttributeConsumingService;
use Moose;
use XML::Generator;
use URN::OASIS::SAML2 qw(URN_METADATA NS_METADATA);
our $VERSION = '0.80'; # VERSION

# ABSTRACT: An attribute consuming service object

has namespace => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { return [NS_METADATA() => URN_METADATA()] },
);

has service_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has service_description => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_service_description',
);

has index => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has default => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has attributes => (
    is      => 'ro',
    isa     => 'ArrayRef[Net::SAML2::RequestedAttribute]',
    traits  => ['Array'],
    default => sub { [] },
    handles => { add_attribute => 'push', },
);

has _xml_gen => (
    is       => 'ro',
    isa      => 'XML::Generator',
    default  => sub { return XML::Generator->new() },
    init_arg => undef,
);


sub to_xml {
    my $self = shift;

    die "Unable to create attribute consuming service, we require attributes"
      unless @{ $self->attributes };

    my $xml = $self->_xml_gen();

    return $xml->AttributeConsumingService(
        $self->namespace,
        {
            index     => $self->index,
            isDefault => $self->default ? 'true' : 'false',
        },
        $xml->ServiceName($self->namespace, { 'xml:lang' => 'en' }, $self->service_name),
        $self->_has_service_description ? $xml->ServiceDescription($self->namespace, { 'xml:lang' => 'en' }, $self->service_description) : (),
        map { $_->to_xml } @{ $self->attributes },
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::AttributeConsumingService - An attribute consuming service object

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  use Net::SAML2::AttributeConsumingService;

  my $service = Net::SAML2::AttributeConsumingService->new(
    # required
    service_name => 'My Service Name',
    index => 1,

    #optional
    service_description => 'My Service description',

    # defaults to:
    namespace => 'md',
    default => 0,
  );
  my $fragment = $service->to_xml;

=head1 DESCRIPTION

=head1 METHODS

=head2 to_xml

Create an XML fragment for this object

=head2 add_attributes

Add a way to add requested attributes

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
