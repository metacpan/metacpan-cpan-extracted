package Net::Lighthouse::User::Membership;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;

# read only attr
has [qw/id user_id/] => (
    isa => 'Int',
    is  => 'ro',
);

has [qw/account project/] => (
    isa => 'Str',
    is  => 'ro',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load_from_xml {
    my $self = shift;
    validate_pos( @_,
        { type => SCALAR | HASHREF, regex => qr/^\s*<membership|^HASH\(\w+\)$/ } );
    my $ref = $self->_translate_from_xml(shift);

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

sub _translate_from_xml {
    my $self = shift;
    my $ref  = Net::Lighthouse::Util->translate_from_xml(shift);

    # current $ref contains user entry, which is not shown in the document,
    # and it's not so useful too, let's delete it for now
    delete $ref->{user} if exists $ref->{user};

    return $ref;
}

1;

__END__

=head1 NAME

Net::Lighthouse::User::Membership - User Membership 

=head1 SYNOPSIS

    use Net::Lighthouse::User::Membership;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item id, user_id

ro, Int

=item account, project

ro, Str

=back

=head1 INTERFACE

=over 4

=item load_from_xml( $hashref | xml_string )

load membership, return loaded membership

=back

=head1 SEE ALSO

membership in L<http://lighthouseapp.com/api/users>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

