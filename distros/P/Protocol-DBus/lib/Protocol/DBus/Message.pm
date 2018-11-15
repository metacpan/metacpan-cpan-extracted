package Protocol::DBus::Message;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Message

=head1 DESCRIPTION

This class encapsulates a single DBus message. You generally should not
instantiate it directly.

=cut

use Protocol::DBus::Marshal ();
use Protocol::DBus::Message::Header ();

use constant _PROTOCOL_VERSION => 1;

sub parse {
    my ($class, $buf_sr) = @_;

    if ( my ($hdr, $hdr_len, $is_be) = Protocol::DBus::Message::Header::parse_simple($buf_sr) ) {

        if (length($$buf_sr) >= ($hdr_len + $hdr->[4])) {

            my $body_sig = $hdr->[6]{ Protocol::DBus::Message::Header::FIELD()->{'SIGNATURE'} };

            if ($hdr->[4]) {
                die "No SIGNATURE header field!" if !defined $body_sig;
            }

            my $body_data;

            if ($body_sig) {
                ($body_data) = Protocol::DBus::Marshal->can( $is_be ? 'unmarshal_be' : 'unmarshal_le' )->($buf_sr, $hdr_len, $body_sig);
            }

            my %self = ( _body_sig => $body_sig );
            @self{'_type', '_flags', '_serial', '_hfields', '_body'} = (@{$hdr}[1, 2, 5, 6], $body_data);

            # Remove the unmarshaled bytes.
            substr( $$buf_sr, 0, $hdr_len + $hdr->[4], q<> );

            return bless \%self, $class;
        }
    }

    return undef;
}

use constant _REQUIRED => ('type', 'serial', 'hfields');

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !defined $opts{$_} } _REQUIRED();
    die "missing: @missing" if @missing;

    $opts{'type'} = Protocol::DBus::Message::Header::MESSAGE_TYPE()->{ $opts{'type'} } || die "Bad “type”: '$opts{'type'}'";

    my $flags = 0;
    if ($opts{'flags'}) {
        for my $f (@{ $opts{'flags'} }) {
            $flags |= Protocol::DBus::Message::Header::FLAG()->{$f} || die "Bad “flag”: $f";
        }
    }

    $opts{'flags'} = $flags;

    my %hfields;

    if ($opts{'hfields'}) {
        my $field_num;

        my $fi = 0;
        while ( $fi < @{ $opts{'hfields'} } ) {
            my ($name, $value) = @{ $opts{'hfields'} }[ $fi, 1 + $fi ];
            $fi += 2;

            $field_num = Protocol::DBus::Message::Header::FIELD()->{$name} || do {
                die "Bad “hfields” name: “$name”";
            };

            $hfields{ $field_num } = [
                Protocol::DBus::Message::Header::FIELD_SIGNATURE()->{$name},
                $value,
            ];

            if ($field_num == Protocol::DBus::Message::Header::FIELD()->{'SIGNATURE'}) {
                $opts{'body_sig'} = $value;
            }
        }
    }

    $opts{'hfields'} = bless \%hfields, 'Protocol::DBus::Type::Dict';

    if ($opts{'body'}) {
        die "“body” requires a SIGNATURE header!" if !$opts{'body_sig'};
    }
    elsif ($opts{'body_sig'}) {
        die "SIGNATURE header given without “body”!";
    }
    else {
        $opts{'body'} = \q<>;
    }

    my %self = map { ( "_$_" => $opts{$_} ) } keys %opts;

    return bless \%self, $class;
}

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<OBJ>->get_header( $NAME )

$NAME is, e.g., C<PATH>.

=cut

sub get_header {
    if ($_[1] =~ tr<0-9><>c) {
        return $_[0]->{'_hfields'}{ Protocol::DBus::Message::Header::FIELD()->{$_[1]} || die("Bad header: “$_[1]”") };
    }

    return $_[0]->{'_hfields'}{$_[1]};
}

=head2 I<OBJ>->get_body()

Always returned as an array reference or undef. See below about mapping
between D-Bus and Perl.

=cut

sub get_body {
    return $_[0]->{'_body'};
}

=head2 I<OBJ>->get_type()

Returns a number. Cross-reference with the D-Bus specification.

=cut

sub get_type {
    return $_[0]->{'_type'};
}

=head2 I<OBJ>->type_is( $NAME )

Convenience method; $NAME is, e.g., C<METHOD_CALL>.

=cut

sub type_is {
    my ($self, $name) = @_;

    return $_[0]->{'_type'} == (Protocol::DBus::Message::Header::MESSAGE_TYPE()->{$name} || do {
        die "Invalid type name: $name";
    });
}

=head2 I<OBJ>->get_flags()

Returns a number. Cross-reference with the D-Bus specification.

=cut

sub get_flags {
    return $_[0]->{'_flags'};
}

=head2 I<OBJ>->flags_have( @NAME )

Convenience method; indicates whether all of the given @NAMES
(e.g., C<NO_AUTO_START>) correspond to flags that are set in the message.

=cut

sub flags_have {
    my ($self, @names) = @_;

    die "Need flag names!" if !@names;

    for my $name (@names) {
        return 0 if !($_[0]->{'_flags'} & (Protocol::DBus::Message::Header::FLAG()->{$name} || do {
        die "Invalid flag name: “$name”";
        }));
    }

    return 1;
}

=head2 I<OBJ>->get_serial()

Returns a number.

=cut

sub get_serial {
    return $_[0]->{'_serial'};
}

#----------------------------------------------------------------------

our $_use_be;
BEGIN {
    $_use_be = 0;
}

sub to_string_le {
    return _to_string(@_);
}

sub to_string_be {
    local $_use_be = 1;
    return _to_string(@_);
}

#----------------------------------------------------------------------

use constant _LEADING_BYTE => map { ord } ('l', 'B');

sub _to_string {
    my ($self) = @_;

    my $body_m_sr;

    if ($self->{'_body_sig'}) {
        $body_m_sr = Protocol::DBus::Marshal->can( $_use_be ? 'marshal_be' : 'marshal_le' )->(
            $self->{'_body_sig'},
            $self->{'_body'},
        );
    }

    my $data = [
        (_LEADING_BYTE())[ $_use_be ],
        $self->{'_type'},
        $self->{'_flags'},
        _PROTOCOL_VERSION(),
        $body_m_sr ? length( $$body_m_sr ) : 0,
        $self->{'_serial'},
        $self->{'_hfields'},
    ];

    my $buf_sr = Protocol::DBus::Marshal->can( $_use_be ? 'marshal_be' : 'marshal_le' )->(
        Protocol::DBus::Message::Header::SIGNATURE(),
        $data,
    );

    Protocol::DBus::Pack::align_str($$buf_sr, 8);

    $$buf_sr .= $$body_m_sr if $body_m_sr;

    return $buf_sr;
}

#----------------------------------------------------------------------

=head1 MAPPING D-BUS TO PERL

=over

=item * Numeric and string types are represented as plain Perl scalars.

=item * Containers are represented as blessed references:
C<Protocol::DBus::Type::Dict>, C<Protocol::DBus::Type::Array>, and
C<Protocol::DBus::Type::Struct>. Currently these are just plain hash and
array references that are bless()ed; i.e., the classes don’t have any
methods defined.

=item * Variant signatures are B<not> preserved; the values are represented
according to the above logic.

=back

=head1 MAPPING PERL TO D-BUS

=over

=item * Use plain Perl scalars to represent all numeric and string types.

=item * Use array references to represent D-Bus arrays and structs.
Use hash references for dicts.

=item * Use a two-member array reference—signature then value—to represent
a D-Bus variant.

=back

=head2 Examples

=over

=item * C<s(s)> - C<( $s0, [ $s1 ] )>

=item * C<a(s)> - C<( \@ss )>

=item * C<a{ss}> - C<( \%ss )>

=back

=cut

1;
