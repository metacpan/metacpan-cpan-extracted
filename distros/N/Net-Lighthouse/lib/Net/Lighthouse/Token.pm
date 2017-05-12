package Net::Lighthouse::Token;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;
extends 'Net::Lighthouse::Base';

# read only attr
has 'created_at' => (
    isa => 'DateTime',
    is  => 'ro',
);

has 'user_id' => (
    isa => 'Int',
    is  => 'ro',
);

has 'project_id' => (
    isa => 'Maybe[Int]',
    is  => 'ro',
);

has 'read_only' => (
    isa => 'Bool',
    is  => 'ro',
);

has 'token' => (
    isa => 'Str',
    is  => 'ro',
);

has [ 'account', 'note' ] => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\w{40}$/ } );
    my $token = shift;

    my $ua = $self->ua;
    my $url = $self->base_url . '/tokens/' . $token . '.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub load_from_xml {
    my $self = shift;
    my $ref = Net::Lighthouse::Util->translate_from_xml(shift);

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

1;

__END__

=head1 NAME

Net::Lighthouse::Token - Token

=head1 SYNOPSIS

    use Net::Lighthouse::Token;
    my $token = Net::Lighthouse::Token->new(
        account => 'sunnavy',
        auth    => { token => '...' },
    );
    $token->load( 'abcdedf...' );

=head1 ATTRIBUTES

=over 4

=item created_at

ro, DateTime object, UTC based

=item user_id

ro, Int

=item project_id

ro, Maybe Int

=item read_only

ro, Bool

=item token

ro, Str

=item account, note
ro, Maybe Str

=item

=back

=head1 INTERFACE

=over 4

=item load( $token_string ) load_from_xml( $hashref | $xml_string )

load a token, return loaded token object

=back

=head1 SEE ALSO

token part in L<http://lighthouseapp.com/api/users>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

