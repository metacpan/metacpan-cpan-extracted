package OMA::Download::DRM::REL::WBXML;
use strict;
BEGIN {
    use OMA::Download::DRM::REL;
	push @OMA::Download::DRM::REL::WBXML::ISA, 'OMA::Download::DRM::REL';
}
=head1 NAME

OMA::Download::DRM::REL::WBXML - WBXML representation of OMA DRM REL 1.0

=head1 DESCRIPTION

WBXML representation of the Open Mobile Alliance Digital Rights Management Rights Expression Language 1.0. Used e.g. with Wap Push.

=head1 SYNOPSIS

  use OMA::Download::DRM::REL::WBXML;

=head1 CONSTRUCTOR

  my $rel=OMA::Download::DRM::REL::WBXML->new(%args);

=head1 PROPERTIES

=head2 mime

Returns the WBXML rights object MIME type

  print $rel->mime;

=cut
sub mime      { 'application/vnd.oma.drm.rights+wbxml' }

=head2 extension

Returns the WBXML rights object extension

  print $rel->extension;

=cut
sub extension { '.drc' }


=head1 METHODS

=head2 packit

Packs data using WBXML format

  print $rel->packit;

=cut
sub packit {
    my ($self)=@_;
    my $res='';
    
	# header
	$res.=pack("C", 3);                               # WBXML Version Number (1.3)
    $res.=pack("C", 0x0e);                            # Public Identifier (~//OMA//DTD REL 1.0//EN)
    $res.=pack("C", 0x6a);                            # UTF-8
    $res.=pack("C", 0x00);                            # String Table Length (empty)
    
    # rights element attributes
    my $rattr='';
    #$rattr.=pack("C", 0xC5); # <o-ex:rights
    $rattr.=pack("C", 0x05); # xmlns:o-ex=
    $rattr.=pack("C", 0x85); # "http://odrl.net/1.1/ODRL-EX"
    $rattr.=pack("C", 0x06); # xmlns:o-dd=
    $rattr.=pack("C", 0x86); # "http://odrl.net/1.1/ODRL-DD"
    $rattr.=pack("C", 0x07); # xmlns:o-ds=
    $rattr.=pack("C", 0x87); # "http://www.w3.org/2000/09/xmldsig#/"
    $rattr.=pack("C", 0x01); # >
	
    return $res.$self->_in_element('rights', $rattr.$self->_packin, 1);
}

#--- Support routines ----------------------------------------------------------
sub _init {
    my $self=shift;
#    $self->{element_tokens} = {
#            rights      => 0xc5,
#            context     => 0x46,
#            version     => 0x47,
#            uid         => 0x48,
#            agreement   => 0x49,
#            asset       => 0x4a,
#            KeyInfo     => 0x4b,
#            KeyValue    => 0x4c,
#            permission  => 0x4d,
#            play        => 0x4e,
#            display     => 0x4f,
#            execute     => 0x50,
#            print       => 0x51,
#            constraint  => 0x52,
#            count       => 0x53,
#            datetime    => 0x54,
#            start       => 0x55,
#            end         => 0x56,
#            interval    => 0x57,
#    };
    $self->{element_tokens} = {
            rights      => 0x05,
            context     => 0x06,
            version     => 0x07,
            uid         => 0x08,
            agreement   => 0x09,
            asset       => 0x0a,
            KeyInfo     => 0x0b,
            KeyValue    => 0x0c,
            permission  => 0x0d,
            play        => 0x0e,
            display     => 0x0f,
            execute     => 0x10,
            print       => 0x11,
            constraint  => 0x12,
            count       => 0x13,
            datetime    => 0x14,
            start       => 0x15,
            end         => 0x16,
            interval    => 0x17,
    };
    return 1;
}
sub _in_element {
    my ($self, $element, $content, $is_root)=@_;
    die "Unknown element token $element" unless $self->{element_tokens}{$element};
    # 01 is </element>
    my $term=''; 
    my $token=$self->{element_tokens}{$element};
    if ($content) {
        $token|=0x40;
        $term=pack("C", 01);
    }
    if ($is_root) {
        $token|=0x80;
    }
    return pack("C", $token).$content.$term;
}
sub _in_string {
    my($self,$string)=@_;
    # 03 means "Inline String Follows"
    # 00 means "End of String"
    return pack("C", 03).$string.pack("C", 00);
}
sub _in_opaque {
    my($self,$data)=@_;
    return pack("C", 0xc3).pack("C", length($data)).$data;
}
1;



__END__


=head1 SEE ALSO

OMA::Download::DRM::REL

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bgpn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Bernard Nauwelaerts.

Released under the GPL.

=cut
