package Office365::EWS::GAL::Item;
use Moose;
use Encode;
has DisplayName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has Surname => (
    is => 'ro',
    isa => 'Str',
);
has GivenName => (
    is => 'ro',
    isa => 'Str',
);
has DisplayNameLastFirst => (
    is => 'ro',
    isa => 'Str',
);
has ImAddress => (
    is => 'ro',
    isa => 'Str',
);
has WorkCity => (
    is => 'ro',
    isa => 'Str',
);
has PersonaType => (
    is => 'ro',
    isa => 'Str',
);
has DisplayNameFirstLast => (
    is => 'ro',
    isa => 'Str',
);
has FileAs => (
    is => 'ro',
    isa => 'Str',
);
has CreationTime => (
    is => 'ro',
    isa => 'Str',
);
has RelevanceScore => (
    is => 'ro',
    isa => 'Str',
);
has EmailAddress => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);
has EmailAddresses => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);
sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});
    foreach my $key (keys %$params) {
        if (not ref $params->{$key}) {
            $params->{$key} = Encode::encode('utf8', $params->{$key});
        }
    }
    return $params;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Office365::EWS::GAL::Item

=head1 VERSION

version 1.142410

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
