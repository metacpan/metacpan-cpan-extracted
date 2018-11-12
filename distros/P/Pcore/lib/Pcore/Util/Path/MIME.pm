package Pcore::Util::Path::MIME;

use Pcore -role, -const;
use Pcore::Util::Scalar qw[is_plain_scalarref];

has _mime_spec => ( init_arg => undef );

around _clear_cache => sub ( $orig, $self ) {
    delete $self->@{qw[_mime_spec]};

    return $self->$orig;
};

# shebang Bool or ScalarRef to file content
sub _mime_spec ( $self, $shebang = undef ) {
    if ( !exists $self->{_mime_spec} ) {
        my $spec;

        if ( defined $self->{filename} ) {
            $spec = P->mime->mime_filename( $self->{filename} );

            if ( !defined $spec && defined $self->{suffix} ) {
                $spec = P->mime->mime_custom_suffix( $self->{suffix} );

                $spec = P->mime->mime_suffix( $self->{suffix} ) if !defined $spec;
            }

            if ( !defined $spec && $shebang ) {
                if ( !is_plain_scalarref $shebang ) {
                    if ( -f $self ) {

                        # read first 50 bytes
                        P->file->read_bin(
                            $self->encoded,
                            buf_size => 50,
                            cb       => sub {
                                $shebang = $_[0];

                                return;
                            }
                        );
                    }
                    else {
                        undef $shebang;
                    }
                }

                $spec = P->mime->mime_shebang( $shebang->$* ) if defined $shebang;
            }
        }

        $self->{_mime_spec} = $spec;
    }

    return $self->{_mime_spec};
}

sub mime_type ( $self, $shebang = undef ) {
    my $spec = $self->_mime_spec($shebang);

    return defined $spec ? $spec->[0] : undef;
}

sub mime_type_is ( $self, $type, $shebang = undef ) {
    my $spec = $self->_mime_spec($shebang);

    return defined $spec && $spec->[0] eq $type;
}

sub mime_tags ( $self, $shebang = undef ) {
    my $spec = $self->_mime_spec($shebang);

    return defined $spec ? $spec->[1] : undef;
}

sub mime_has_tag ( $self, $tag, $shebang = undef ) {
    my $spec = $self->_mime_spec($shebang);

    return defined $spec && $spec->[1]->{$tag};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path::MIME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
