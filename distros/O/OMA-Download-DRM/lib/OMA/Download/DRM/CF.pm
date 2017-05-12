package OMA::Download::DRM::CF;
use strict;
BEGIN {
    use Crypt::Rijndael;
}
=head1 NAME

OMA::Download::DRM::CF - Perl extension for formatting content objects according to the OMA DRM 1.0 specification

=head1 DESCRIPTION

Packs & encrypts content objects  according to the Open Mobile Alliance Digital Rights Management 1.0 specification

=head1 SYNOPSIS

    use OMA::Download::DRM::CF;

=head1 CONSTRUCTOR

=head2 new
	
    my $cf = OMA::Download::DRM::CF->new(
        
        ### Mandatory
        'key'                 => '0123456789ABCDEF',
        'data'                => \$data,
        'content-type'        => 'image/gif',
        'content-uri'         => 'cid:image239872@foo.bar',
        'Rights-Issuer'       => 'http://example.com/pics/image239872',
        'Content-Name'        => 'Kilimanjaro Uhuru Peak',
        
        ### Optional
        'Content-Description' => 'Nice image from Kilimanjaro',
        'Content-Vendor'      => 'IT Development Belgium',
        'Icon-URI'            => 'http://example.com/icon.gif',
    );

=cut
### Class constructor ----------------------------------------------------------
sub new {
    my ($class, %arg)=@_;
    
    for ('key', 'data', 'content-type', 'content-uri', 'Rights-Issuer', 'Content-Name') {
        die 'Need '.$_ unless $arg{$_};
    }
    die "Key must be 128-bit long" if length($arg{key}) != 16;
    
    my $self={
        'key'          => $arg{key},
        'data'         => $arg{data},
        'content-type' => $arg{'content-type'},
        'content-uri'  => $arg{'content-uri'},
        headers => {
            #'Encryption-Method'   => $arg{'Encryption-Method'}   || 'AES128CBC;padding=RFC2630;plaintextlen='.length(${$arg{data}}),
            'Encryption-Method'   => $arg{'Encryption-Method'}   || 'AES128CBC',
            'Rights-Issuer'       => $arg{'Rights-Issuer'},
            'Content-Name'        => $arg{'Content-Name'},
            'Content-Description' => $arg{'Content-Description'} || '',
            'Content-Vendor'      => $arg{'Content-Vendor'}      || '',
            'Icon-URI'            => $arg{'Icon-URI'}            || ''
        },
        'block-size' => 16,
    };
    $self=bless $self, $class;
    $self;
}



=head1 PROPERTIES

=head2 key

get or set the 128-bit ASCII encryption key

  print $cf->key;
  
  $cf->key('0123456789ABCDEF');

=cut
sub key {
    my($self, $val)=@_;
	if(defined $val && length($val) == 16) {
		$self->{key} = $val ;
	}
	$self->{key};
}

=head2 data

Get or set the reference to the binary content data

  print ${$cf->data};
  
  $cf->data(\$data);

=cut
sub data {
    my($self, $val)=@_;
	$self->{data} = $val if defined $val;
	$self->{data};
}

=head2 content_type

Get or set the content MIME type

  print $cf->content_type;
  
  $cf->content_type('image/gif');

=cut
sub content_type {
    my($self, $val)=@_;
	$self->{'content-type'} = $val if defined $val;
	$self->{'content-type'};
}

=head2 content_uri

Get or set the content URI

  print $cf->content_uri;
  
  $cf->content_type('image12345@example.com');

=cut
sub content_uri {
    my($self, $val)=@_;
	$self->{'content_uri'} = $val if defined $val;
	$self->{'content_uri'};
}

=head2 header

Get or set a header

  print $cf->header('Content-Vendor');
  
  $cf->header('Content-Vendor', 'My Company');

=cut
sub header {
    my($self, $key, $val)=@_;
	$self->{headers}{$key} = $val if defined $val;
    $self->{headers}{$key} || undef;
}

=head2 mime

Returns the formatted content MIME type

  print $cf->mime;

=cut
sub mime      { 'application/vnd.oma.drm.content' }

=head2 extension

Returns the formatted content file extension

  print $cf->extension;

=cut
sub extension { '.dcf' }

=head1 METHODS 

=head2 packit

Formats the content object

  print $cf->packit;

=cut
sub packit {
    my $self=$_[0];
    my $res='';
    
    my $cdat='';                                      # Encrypted data variable
    $self->_crypt($self->{data}, \$cdat);             # Crypt data
    
    #$self->{headers}{'Encryption-Method'}.=length($cdat);      #
    
    #my $head=$self->_headers."\r\n";                  # Get headers
    my $head=$self->_headers;                          # Get headers
    
    $res.=pack("C", 1);                               # CF Version Number (1)
    $res.=pack("C", length($self->{'content-type'})); # Length of ContentType field
    $res.=pack("C", length($self->{'content-uri'}));  # Length of ContentURI field
    $res.=$self->{'content-type'};                    # ContentType field
    $res.=$self->{'content-uri'};                     # ContentURI field
    $res.=_uint2uintvar(length($head));               # Length of the Headers field
    $res.=_uint2uintvar(length($cdat));               # Length of Data field
    $res.=$head;                                      # Headers
    $res.=$cdat;                                      # Encrypted data
    return $res;
} 




#--- Support routines ----------------------------------------------------------
sub _crypt {
    my($self,$data,$cdat)=@_;    
    my $cipher = Crypt::Rijndael->new($self->{'key'}, Crypt::Rijndael::MODE_CBC);
    $$cdat = $cipher->encrypt($$data._padding($data, $self->{'block-size'}));
    1
}
sub _padding {                                        # Fill in missed bytes
    my($data,$blocksize)=@_;
    ### rfc2630 6.3
    my $numpad = $blocksize - (length($$data) % $blocksize);
    pack("C", $numpad) x $numpad;
}
sub _headers {
    my $self=$_[0];
    my $res='';
    for (keys %{$self->{headers}}) {
        if ($self->{headers}{$_}) {
            $res.=$_.': '.$self->{headers}{$_}."\r\n";
        }
    }
    $res;
}
sub _uint2uintvar {
    ### Lightweight algorithm implementation
    my $int=$_[0] || return pack("C", 0);
    my $lst=0;                                    # We begin with the last octet
    my $res='';                                   
    while ($int > 0) {
        $res=pack("C", ($int & 127) | $lst).$res; # Take 7 LSBits, MSBit is clear if last octet
        $int>>=7;                                 # Shift 7 bits right
        $lst=128;                                 # Next octets wont be lastes
    }
    $res;
}


1;

__END__

=head1 SEE ALSO

* OMA-Download-CF-V1_0-20040615-A

* WAP-230-WSP-20010705-a

* RFC2760

* Crypt::Rijndael

* RFC2630 6.3

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bpgn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Bernard Nauwelaerts.

Released under the GPL.

=cut
