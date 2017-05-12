package OMA::Download::DRM::REL::XML;
use strict;
BEGIN {
    use MIME::Base64;
	use OMA::Download::DRM::REL;
	push @OMA::Download::DRM::REL::XML::ISA, 'OMA::Download::DRM::REL';
}
=head1 NAME

OMA::Download::DRM::REL::XML - XML representation of the OMA DRM REL 1.0

=head1 DESCRIPTION

XML representation of the Open Mobile Alliance Digital Rights Management Rights Expression Language 1.0

=head1 SYNOPSIS

  use OMA::Download::DRM::REL::XML;

=head1 CONSTRUCTOR

  my $rel=OMA::Download::DRM::REL::XML->new(%args);

=head1 PROPERTIES

=head2 mime

Returns the XML rights object MIME type

  print $rel->mime;

=cut
sub mime      { 'application/vnd.oma.drm.rights+xml' }


=head2 extension

Returns the XML rights object extension

  print $rel->extension;

=cut
sub extension { '.dr' }

### Class init -----------------------------------------------------------------


=head1 METHODS


=head2 packit

Packs data using XML format

  print $rel->packit;

=cut
sub packit {
    my ($self)=@_;
    my $res='';
    $res.='<?xml version="1.0" encoding="utf-8"?>'."\n";   # WBXML Version Number (1.3)
    $res.='<!DOCTYPE o-ex:rights PUBLIC "-//OMA//DTD REL 1.0//EN" "http://www.oma.org/dtd/dr">'."\n";  # Public Identifier (~//OMA//DTD REL 1.0//EN)
    return $res.'<o-ex:rights xmlns:o-ex="http://odrl.net/1.1/ODRL-EX" xmlns:o-dd="http://odrl.net/1.1/ODRL-DD" xmlns:ds="http://www.w3.org/2000/09/xmldsig#/">'."\n".$self->_packin."\n".'</o-ex:rights>';
}

#--- Support routines ----------------------------------------------------------
sub _init {
    my ($self)=@_;
    $self->{'element_tokens'} = {
        'rights'      => 'o-ex:rights',
        'context'     => 'o-ex:context',
        'version'     => 'o-dd:version',
        'uid'         => 'o-dd:uid',
        'agreement'   => 'o-ex:agreement',
        'asset'       => 'o-ex:asset',
        'KeyInfo'     => 'ds:KeyInfo',
        'KeyValue'    => 'ds:KeyValue',
        'permission'  => 'o-ex:permission',
        'play'        => 'o-dd:play',
        'display'     => 'o-dd:display',
        'execute'     => 'o-dd:execute',
        'print'       => 'o-dd:print',
        'constraint'  => 'o-ex:constraint',
        'count'       => 'o-dd:count',
        'datetime'    => 'o-dd:datetime',
        'start'       => 'o-dd:start',
        'end'         => 'o-dd:end',
        'interval'    => 'o-dd:interval'
    };
    if ($self->{key}) {
		$self->{key}=encode_base64($self->{key}); $self->{key}=~s/[\r\n]//g;
	}
    return 1;
}
sub _in_element {
    my ($self, $element, $content, $is_root)=@_;
    die "Unknown element token $element" unless $self->{element_tokens}{$element};
    my $res='<'.$self->{element_tokens}{$element};
    if ($content) {
        $res.='>'.$content.'</'.$self->{element_tokens}{$element}.'>'
    } else {
        $res.='/>'
    }
    return $res;
}
sub _in_string {
    return $_[1];
}
sub _in_opaque {
    return $_[1];
}
1;
__END__
=head1 SEE ALSO

OMA::Download::DRM::REL

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bpgn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Bernard Nauwelaerts.

Released under the GPL.

=cut