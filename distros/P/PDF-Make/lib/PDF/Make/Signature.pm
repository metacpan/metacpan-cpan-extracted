package PDF::Make::Signature;

use strict;
use warnings;
use 5.020;
use PDF::Make ();  # XS supplies _verify, _count, _sign_doc and the SigningIdentity / Certificate accessors

=head1 NAME

PDF::Make::Signature - Digital signature support for PDF documents

=head1 SYNOPSIS

    use PDF::Make;
    
    my $pdf = PDF::Make->new();
    $pdf->page;
    $pdf->text("Signed Document", 100, 700);
    
    # Load signing identity from PKCS#12 file
    my $identity = PDF::Make::Signature->load_identity(
        file     => 'signer.p12',
        password => 'secret'
    );
    
    # Sign the document
    my $signed_pdf = $pdf->sign(
        identity => $identity,
        reason   => 'Document approval',
        location => 'New York, NY',
        contact  => 'signer@example.com'
    );
    
    # Write signed PDF
    open my $fh, '>', 'signed.pdf' or die;
    binmode $fh;
    print $fh $signed_pdf;
    close $fh;
    
    # Verify a signature
    my $result = PDF::Make::Signature->verify(
        file => 'signed.pdf'
    );
    
    if ($result->is_valid) {
        print "Signature is valid\n";
        print "Signed by: ", $result->signer_name, "\n";
        print "Signed at: ", $result->signing_time, "\n";
    }

=head1 DESCRIPTION

PDF::Make::Signature provides digital signature capabilities for PDF documents,
implementing the signature format specified in ISO 32000-2:2020 §12.8.

Features:

=over 4

=item * RSA and ECDSA signatures with SHA-256/384/512

=item * PKCS#7 detached signature format (adbe.pkcs7.detached)

=item * Certificate chain embedding

=item * Signature verification

=item * Visual and invisible signature fields

=item * Certification signatures (MDP)

=back

=cut

our $VERSION = '0.02';

use Carp qw(croak);
use Scalar::Util qw(blessed);

# Hash algorithm constants
use constant {
    HASH_SHA1   => 0,
    HASH_SHA256 => 1,
    HASH_SHA384 => 2,
    HASH_SHA512 => 3,
};

# Signature subfilter constants
use constant {
    SUBFILTER_PKCS7_DETACHED => 0,
    SUBFILTER_PKCS7_SHA1     => 1,
    SUBFILTER_ETSI_CADES     => 2,
    SUBFILTER_ETSI_RFC3161   => 3,
};

# MDP (Modification Detection and Prevention) levels
use constant {
    MDP_NONE       => 0,  # Not a certification signature
    MDP_NO_CHANGES => 1,  # No changes permitted
    MDP_FORM_FILL  => 2,  # Form filling + signing allowed
    MDP_ANNOTATE   => 3,  # Annotations + form fill + signing allowed
};

=head1 CLASS METHODS

=head2 load_identity

Load a signing identity from a PKCS#12 file or separate key/certificate files.

    # From PKCS#12
    my $identity = PDF::Make::Signature->load_identity(
        file     => 'signer.p12',
        password => 'secret'
    );
    
    # From separate files
    my $identity = PDF::Make::Signature->load_identity(
        key_file  => 'private.pem',
        cert_file => 'cert.pem',
        chain_file => 'chain.pem',  # optional
        password  => 'keypass'      # for encrypted keys
    );

Returns a L<PDF::Make::SigningIdentity> object.

=cut

sub load_identity {
    my ($class, %args) = @_;
    
    if ($args{file}) {
        # Load from PKCS#12
        return PDF::Make::SigningIdentity->from_pkcs12(
            $args{file},
            $args{password}
        );
    }
    elsif ($args{key_file} && $args{cert_file}) {
        # Load from separate files
        return PDF::Make::SigningIdentity->from_files(
            key_file   => $args{key_file},
            cert_file  => $args{cert_file},
            chain_file => $args{chain_file},
            password   => $args{password}
        );
    }
    else {
        croak "load_identity requires 'file' (PKCS#12) or 'key_file' and 'cert_file'";
    }
}

=head2 verify

Verify a digital signature in a PDF file.

    my $result = PDF::Make::Signature->verify(
        file  => 'signed.pdf',
        index => 0,  # optional, signature field index (default: 0)
    );
    
    # Or verify from bytes
    my $result = PDF::Make::Signature->verify(
        data => $pdf_bytes,
    );

Returns a L<PDF::Make::SignatureResult> object.

=cut

sub verify {
    my ($class, %args) = @_;
    
    my $data;
    if ($args{file}) {
        open my $fh, '<', $args{file} or croak "Cannot open $args{file}: $!";
        binmode $fh;
        local $/;
        $data = <$fh>;
        close $fh;
    }
    elsif ($args{data}) {
        $data = $args{data};
    }
    else {
        croak "verify requires 'file' or 'data'";
    }
    
    my $index = $args{index} // 0;
    
    # Call the XS verification function
    return PDF::Make::Signature::_verify($data, $index);
}

=head2 count_signatures

Count the number of signature fields in a PDF.

    my $count = PDF::Make::Signature->count_signatures(
        file => 'document.pdf'
    );

=cut

sub count_signatures {
    my ($class, %args) = @_;
    
    my $data;
    if ($args{file}) {
        open my $fh, '<', $args{file} or croak "Cannot open $args{file}: $!";
        binmode $fh;
        local $/;
        $data = <$fh>;
        close $fh;
    }
    elsif ($args{data}) {
        $data = $args{data};
    }
    else {
        croak "count_signatures requires 'file' or 'data'";
    }
    
    return PDF::Make::Signature::_count($data);
}

=head1 INSTANCE METHODS (for PDF::Make documents)

These methods are called on PDF::Make document objects.

=head2 sign

Sign the document with a digital signature.

    my $signed_pdf = $pdf->sign(
        identity => $identity,
        
        # Optional metadata
        reason   => 'Document approval',
        location => 'New York, NY',
        contact  => 'signer@example.com',
        name     => 'John Doe',  # default: from certificate
        
        # Signature options
        hash     => 'sha256',  # sha256, sha384, sha512
        
        # Certification (MDP) - makes this a certification signature
        certify  => 0,  # 0=none, 1=no changes, 2=form fill, 3=annotate
        
        # Visual signature (optional)
        visible  => 0,  # default: invisible signature
        page     => 1,  # page number for visible signature
        rect     => [100, 100, 300, 200],  # signature rectangle
        
        # Timestamp (optional)
        timestamp_url => 'http://timestamp.example.com/tsa',
    );

Returns the signed PDF as bytes.

=cut

sub _sign_document {
    my ($pdf, %args) = @_;
    
    croak "sign requires 'identity'" unless $args{identity};
    
    # Validate identity
    my $identity = $args{identity};
    croak "identity must be a PDF::Make::SigningIdentity"
        unless blessed($identity) && $identity->isa('PDF::Make::SigningIdentity');
    
    # Map hash algorithm name to constant
    my %hash_map = (
        sha1   => HASH_SHA1,
        sha256 => HASH_SHA256,
        sha384 => HASH_SHA384,
        sha512 => HASH_SHA512,
    );
    my $hash_alg = $hash_map{lc($args{hash} // 'sha256')} // HASH_SHA256;
    
    # Build config
    my $config = {
        identity  => $identity,
        hash_alg  => $hash_alg,
        subfilter => SUBFILTER_PKCS7_DETACHED,
        reason    => $args{reason},
        location  => $args{location},
        contact   => $args{contact},
        name      => $args{name},
        mdp       => $args{certify} // MDP_NONE,
        visible   => $args{visible} // 0,
        page      => $args{page} // 1,
        rect      => $args{rect} // [0, 0, 0, 0],
        timestamp_url => $args{timestamp_url},
        signing_time => $args{signing_time},
        tst_token    => $args{tst_token},
    };

    # Build the appearance hashref handed to the XS layer.
    #
    # Three supported input shapes, in precedence order:
    #
    #   appearance => sub { my ($sa) = @_; ...draw onto $sa... }
    #       — user draws via a PDF::Make::Builder::SignatureAppearance
    #         helper; we capture the resulting content-stream + font map.
    #
    #   appearance => { stream => $raw_bytes, fonts => { F1 => 'Helvetica' } }
    #       — fully-custom precomputed content stream.  Advanced.
    #
    #   visible => 1 (with page/rect)
    #       — use the C builder's default signer/date/reason block.
    my $appearance;
    if ($args{visible} || $args{appearance}) {
        my $rect = $args{rect} // [0, 0, 0, 0];
        my ($x0, $y0, $x1, $y1) = @$rect;
        my $w = $x1 - $x0;
        my $h = $y1 - $y0;

        my $stream;
        my $fonts;
        my $xobjects;
        if (ref $args{appearance} eq 'CODE') {
            require PDF::Make::Builder::SignatureAppearance;
            my $sa = PDF::Make::Builder::SignatureAppearance->new(
                w => $w, h => $h, doc => $pdf,
            );
            $args{appearance}->($sa);
            $stream   = $sa->stream;
            $fonts    = $sa->fonts;
            $xobjects = $sa->xobjects;
        } elsif (ref $args{appearance} eq 'HASH') {
            $stream   = $args{appearance}{stream};
            $fonts    = $args{appearance}{fonts};
            $xobjects = $args{appearance}{xobjects};
        }

        $appearance = {
            visible => 1,
            page    => $args{page} // 1,
            rect    => $rect,
            (defined $stream   ? (stream   => $stream)   : ()),
            (defined $fonts    ? (fonts    => $fonts)    : ()),
            (defined $xobjects ? (xobjects => $xobjects) : ()),
            show_name   => $args{show_name}   // 1,
            show_date   => $args{show_date}   // 1,
            show_reason => $args{show_reason} // 1,
        };
    }
    $config->{appearance} = $appearance;

    # Pass 1: sign without TSA (or sign once if no TSA requested).
    my $signing_time = $config->{signing_time} // time();
    $config->{signing_time} = $signing_time;

    # When a TSA is requested the CMS grows by the size of the embedded
    # TimeStampToken (~6KB for Digicert/GlobalSign).  Bump the default
    # /Contents placeholder so the larger CMS still fits.
    if ($config->{timestamp_url} && !$config->{placeholder_size}) {
        $config->{placeholder_size} = 32768;   # 16KB CMS headroom
    }

    my $signed = PDF::Make::Signature::_sign($pdf, $config);

    # Pass 2: if a timestamp_url was provided, embed an RFC 3161 token.
    if ($config->{timestamp_url} && !defined $config->{tst_token}) {
        require Digest::SHA;
        require HTTP::Tiny;

        my $cms_der = _extract_contents_cms_bytes($signed)
            or croak "sign: failed to locate /Contents CMS in signed PDF";
        my $sig_bytes = PDF::Make::Signature::_extract_cms_signature($cms_der);
        my $imprint   = Digest::SHA::sha256($sig_bytes);

        my $req_der = PDF::Make::Signature::_build_tsa_request(
            $hash_alg, $imprint, 1);

        my $http = HTTP::Tiny->new(
            timeout => $args{tsa_timeout} // 30,
            verify_SSL => 1,
        );
        my $resp = $http->post($config->{timestamp_url}, {
            headers => {
                'Content-Type' => 'application/timestamp-query',
                'Accept'       => 'application/timestamp-reply',
            },
            content => $req_der,
        });
        unless ($resp->{success}) {
            croak "sign: TSA HTTP error $resp->{status} $resp->{reason}"
                . " from $config->{timestamp_url}";
        }
        my $token = PDF::Make::Signature::_parse_tsa_response($resp->{content});

        # Pass 2: re-sign with same signing_time + tst_token.
        $config->{tst_token} = $token;
        $signed = PDF::Make::Signature::_sign($pdf, $config);
    }

    return $signed;
}

# Locate /Contents <...> in a signed PDF and return the decoded DER bytes
# (stripping trailing zero padding).  Used to fish the CMS out after
# pass 1 so we can timestamp the RSA signature value.
sub _extract_contents_cms_bytes {
    my ($pdf_bytes) = @_;
    return unless $pdf_bytes =~ /\/Contents \s* < ([0-9A-Fa-f]+) >/sx;
    my $hex = $1;
    # Strip trailing zero padding (last non-zero hex-digit boundary).
    $hex =~ s/(?:00)+\z//;
    return pack('H*', $hex);
}

=head2 add_signature_field

Add a signature field to the document (without signing).

    my $field = $pdf->add_signature_field(
        name    => 'Signature1',
        page    => 1,
        rect    => [100, 100, 300, 200],
    );

This creates an unsigned signature field that can be signed later.

=cut

sub _add_signature_field {
    my ($pdf, %args) = @_;
    
    my $name = $args{name} // 'Signature1';
    my $page = $args{page} // 1;
    my $rect = $args{rect} // [0, 0, 0, 0];
    
    # Call the XS function to add field
    return PDF::Make::Signature::_add_field($pdf, $name, $page, $rect);
}

sub _sign {
    my ($pdf, $config) = @_;

    # Use XS signing implementation
    my $identity = $config->{identity}
        or croak "Signature requires identity";
    my $hash_alg = $config->{hash_alg} // 1; # SHA256

    my $signed_bytes = eval {
        # & prefix bypasses the XS-generated prototype, which may be stale
        # vs the XS param list during development rebuilds.
        &PDF::Make::Signature::_sign_doc(
            $pdf,
            $identity,
            $hash_alg,
            $config->{reason},
            $config->{location},
            $config->{contact},
            $config->{name},
            $config->{signing_time},
            $config->{tst_token},
            $config->{placeholder_size},
            $config->{appearance},
        );
    };
    if ($@) {
        croak "Signing failed: $@";
    }
    return $signed_bytes;
}

sub _add_field {
    my ($pdf, $name, $page, $rect) = @_;
    # Stub - XS implementation pending
    croak "add_signature_field not yet implemented";
}

1;

#============================================================================
# PDF::Make::SigningIdentity - Represents a signing key + certificate
#============================================================================

package PDF::Make::SigningIdentity;

use strict;
use warnings;
use Carp qw(croak);

=head1 NAME

PDF::Make::SigningIdentity - Signing key and certificate pair

=head1 DESCRIPTION

Represents a signing identity consisting of a private key and certificate chain.

=cut

sub new {
    my ($class, %args) = @_;
    
    my $self = bless {
        privkey  => $args{privkey},
        cert     => $args{cert},
        chain    => $args{chain} // [],
        _ptr     => $args{_ptr},  # XS pointer
    }, $class;
    
    return $self;
}

sub from_pkcs12 {
    my ($class, $file, $password) = @_;
    
    croak "PKCS#12 file required" unless $file;
    croak "Cannot read PKCS#12 file: $file" unless -r $file;
    
    # Read file
    open my $fh, '<', $file or croak "Cannot open $file: $!";
    binmode $fh;
    local $/;
    my $data = <$fh>;
    close $fh;
    
    # Call XS to parse PKCS#12
    return $class->_parse_pkcs12($data, $password // '');
}

sub from_files {
    my ($class, %args) = @_;
    
    my $key_file = $args{key_file} or croak "key_file required";
    my $cert_file = $args{cert_file} or croak "cert_file required";
    
    # Read key file
    open my $fh, '<', $key_file or croak "Cannot open $key_file: $!";
    binmode $fh;
    local $/;
    my $key_data = <$fh>;
    close $fh;
    
    # Read cert file
    open $fh, '<', $cert_file or croak "Cannot open $cert_file: $!";
    binmode $fh;
    my $cert_data = <$fh>;
    close $fh;
    
    # Read chain file if provided
    my $chain_data = '';
    if ($args{chain_file}) {
        open $fh, '<', $args{chain_file} or croak "Cannot open $args{chain_file}: $!";
        binmode $fh;
        $chain_data = <$fh>;
        close $fh;
    }
    
    # Call XS to parse files
    return $class->_parse_files($key_data, $cert_data, $chain_data, $args{password} // '');
}

# XS stubs
sub _parse_pkcs12 {
    my ($class, $data, $password) = @_;
    require PDF::Make;  # Ensure XS is loaded
    return $class->_from_pkcs12($data, $password // '');
}

sub _parse_files {
    my ($class, $key_data, $cert_data, $chain_data, $password) = @_;
    # Stub - would call pdfmake_privkey_parse_pem and pdfmake_x509_parse_pem
    croak "PEM parsing not yet implemented";
}

1;

#============================================================================
# PDF::Make::SignatureResult - Verification result
#============================================================================

package PDF::Make::SignatureResult;

use strict;
use warnings;

=head1 NAME

PDF::Make::SignatureResult - Signature verification result

=head1 DESCRIPTION

Represents the result of signature verification.

=cut

sub new {
    my ($class, %args) = @_;
    
    return bless {
        valid              => $args{valid} // 0,
        signature_valid    => $args{signature_valid} // 0,
        digest_valid       => $args{digest_valid} // 0,
        cert_valid         => $args{cert_valid} // 0,
        timestamp_valid    => $args{timestamp_valid},
        document_modified  => $args{document_modified} // 0,
        signer_name        => $args{signer_name},
        signer_email       => $args{signer_email},
        signing_time       => $args{signing_time},
        cert               => $args{cert},
        chain              => $args{chain},
        error              => $args{error},
    }, $class;
}

# Accessors
sub is_valid           { $_[0]->{valid} }
sub signature_valid    { $_[0]->{signature_valid} }
sub digest_valid       { $_[0]->{digest_valid} }
sub cert_valid         { $_[0]->{cert_valid} }
sub timestamp_valid    { $_[0]->{timestamp_valid} }
sub document_modified  { $_[0]->{document_modified} }
sub signer_name        { $_[0]->{signer_name} }
sub signer_email       { $_[0]->{signer_email} }
sub signing_time       { $_[0]->{signing_time} }
sub certificate        { $_[0]->{cert} }
sub certificate_chain  { $_[0]->{chain} }
sub error              { $_[0]->{error} }

1;

#============================================================================
# PDF::Make::Certificate - X.509 certificate wrapper
#============================================================================

package PDF::Make::Certificate;

use strict;
use warnings;
use Carp qw(croak);

=head1 NAME

PDF::Make::Certificate - X.509 certificate wrapper

=head1 DESCRIPTION

Represents an X.509 certificate for digital signatures.

=cut

sub new {
    my ($class, %args) = @_;
    
    return bless {
        _ptr              => $args{_ptr},
        version           => $args{version},
        serial            => $args{serial},
        issuer            => $args{issuer},
        subject           => $args{subject},
        not_before        => $args{not_before},
        not_after         => $args{not_after},
        key_usage         => $args{key_usage},
        ext_key_usage     => $args{ext_key_usage},
        is_ca             => $args{is_ca},
        is_self_signed    => $args{is_self_signed},
    }, $class;
}

sub load {
    my ($class, %args) = @_;
    
    my $data;
    if ($args{file}) {
        open my $fh, '<', $args{file} or croak "Cannot open $args{file}: $!";
        binmode $fh;
        local $/;
        $data = <$fh>;
        close $fh;
    }
    elsif ($args{data}) {
        $data = $args{data};
    }
    else {
        croak "load requires 'file' or 'data'";
    }
    
    # Detect format
    if ($data =~ /^-----BEGIN CERTIFICATE-----/) {
        return $class->_parse_pem($data);
    }
    else {
        return $class->_parse_der($data);
    }
}

# Accessors
sub version        { $_[0]->{version} }
sub serial         { $_[0]->{serial} }
sub issuer         { $_[0]->{issuer} }
sub subject        { $_[0]->{subject} }
sub not_before     { $_[0]->{not_before} }
sub not_after      { $_[0]->{not_after} }
sub key_usage      { $_[0]->{key_usage} }
sub ext_key_usage  { $_[0]->{ext_key_usage} }
sub is_ca          { $_[0]->{is_ca} }
sub is_self_signed { $_[0]->{is_self_signed} }

sub is_valid {
    my ($self, $time) = @_;
    $time //= time();
    return ($time >= $self->{not_before} && $time <= $self->{not_after});
}

sub can_sign_documents {
    my ($self) = @_;
    
    # Check key usage if present
    if (defined $self->{key_usage} && $self->{key_usage}) {
        # Need digitalSignature (bit 0) or nonRepudiation (bit 1)
        return 0 unless ($self->{key_usage} & 0x03);
    }
    
    # Check extended key usage if present
    if (defined $self->{ext_key_usage} && $self->{ext_key_usage}) {
        # Need document signing, PDF signing, email protection, or code signing
        return 0 unless ($self->{ext_key_usage} & 0xFC);
    }
    
    return 1;
}

# XS stubs
sub _parse_pem {
    my ($class, $data) = @_;
    # Would call pdfmake_x509_parse_pem
    croak "PEM certificate parsing not yet implemented";
}

sub _parse_der {
    my ($class, $data) = @_;
    # Would call pdfmake_x509_parse_der
    croak "DER certificate parsing not yet implemented";
}

1;

__END__

=head1 SIGNATURE FORMAT

PDF::Make::Signature implements the C<adbe.pkcs7.detached> signature format,
which is the recommended format for PDF signatures per ISO 32000-2:2020.

The signature is a PKCS#7 SignedData structure containing:

=over 4

=item * Signer certificate and chain

=item * Signed attributes (content type, message digest, signing time)

=item * RSA or ECDSA signature

=item * Optional timestamp token (RFC 3161)

=back

=head1 CERTIFICATION SIGNATURES

Certification signatures (MDP - Modification Detection and Prevention) can
restrict what changes are allowed after signing:

=over 4

=item B<MDP_NO_CHANGES (1)> - No changes allowed

=item B<MDP_FORM_FILL (2)> - Form filling and signing allowed

=item B<MDP_ANNOTATE (3)> - Annotations, form fill, and signing allowed

=back

Only the first signature in a document can be a certification signature.

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Form>

ISO 32000-2:2020 §12.8 - Digital Signatures

RFC 5652 - Cryptographic Message Syntax (CMS)

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
