package OMA::Download::DRM;
use strict;
BEGIN {
    $OMA::Download::DRM::VERSION = '1.00.07';  
}
=head1 NAME

OMA::Download::DRM - Perl extension for packing DRM objects according to the OMA DRM 1.0 specification

=head1 DESCRIPTION

This module encodes data objects according to the Open Mobile Alliance Digital Rights Management 1.0 specification in order to control how the end user uses these objects.

=head1 SYNOPSIS

  use OMA::Download::DRM;

=head1 CONSTRUCTOR

=head2 new

  my $drm = OMA::Download::DRM->new(%args);

=cut

sub new {
    my ($class, %arg)=@_;
    my $self={
        'content-type' => $arg{'content-type'},
        data           => $arg{data},
        key            => $arg{key},
        uid            => $arg{'uid'} || rand(999999999),
        domain         => $arg{domain} || 'example.com',
        #method         => $arg{method},
        boundary       => undef,
		mime		   => undef
    };
    $self=bless $self, $class;
    $self->{boundary} = 'mime-boundary/'.$self->{uid}.'/'.time;
	
    $self;
}
=head1 PROPERTIES

=head2 uid

Returns download object uid

  print $drm->uid;

=cut
sub uid {
	return $_[0]->{uid};
}

=head2 mime

Returns the MIME type

  print $drm->mime;

=cut
sub mime {
    $_[0]->{mime};
}

=head1 METHODS

=head2 fw_lock

Forward-lock delivery

  my $drm = OMA::Download::DRM->new(
      'content-type' => 'image/gif',                            # Content MIME type
      'data'         => \$data,                                 # GIF image binary data reference
  );
  print "Content-type: ".$drm->mime."\n\n";                     # Appropriate MIME type
  print $drm->fw_lock();                                        # Forward lock
  
=cut
sub fw_lock {
    my ($self)=@_;
    my $res='';
    $res.='--'.$self->{boundary}."\r\n";
    $res.= 'Content-Type: '.$self->{'content-type'}."\r\n";
    $res.= 'Content-Transfer-Encoding: binary'."\r\n\r\n";    
    $res.= ${$self->{data}};
    $res.= "\r\n";
    $res.='--'.$self->{boundary}."--";
	$self->{mime}='application/vnd.oma.drm.message; boundary='.$self->{boundary};
    return $res;
}

=head2 combined

Combined delivery

  my $drm = OMA::Download::DRM->new(
      'content-type' => 'image/gif',                            # Content MIME type
      'data'         => \$data,                                 # GIF image binary data reference
      'domain'       => 'example.com'
  );
  print "Content-type: ".$drm->mime."\n\n";                     # Appropriate MIME type
  print $drm->combined($permission, %constraint);               # Combined delivery. See OMA::Download::DRM::REL.

=cut
sub combined {
    my ($self, $permission, %constraint)=@_;
    my $res='';
    $res.='--'.$self->{boundary}."\r\n";
	use OMA::Download::DRM::REL::XML;
    my $rel = OMA::Download::DRM::REL::XML->new( 
       'permission'           => $permission,
        'uid'                 => 'cid:'.$self->{uid}.'@'.$self->{domain},
        %constraint || ()
    );
    $res.= 'Content-Type: '.$rel->mime."\r\n";
    $res.= 'Content-Transfer-Encoding: binary'."\r\n\r\n";
    $res.= $rel->packit;
    $res.= "\r\n\r\n";
    $res.='--'.$self->{boundary}."\r\n";

    $res.= 'Content-Type: '.$self->{'content-type'}."\r\n";
    $res.= 'Content-ID: <'.$self->{uid}.'@'.$self->{domain}.">\r\n";
    $res.= 'Content-Transfer-Encoding: binary'."\r\n\r\n";    
    $res.= ${$self->{data}};
    $res.= "\r\n";
    $res.='--'.$self->{boundary}."--";
	$self->{mime}='application/vnd.oma.drm.message; boundary='.$self->{boundary};
    return $res;
}


=head2 separate_content

Separate delivery. Content encryption and packing.

  my $drm = OMA::Download::DRM->new(
      'content-type' => 'image/gif',                            # Content MIME type
      'data'         => \$data,                                 # GIF image binary data reference
      'domain'       => 'example.com',
      'key'          => '128bit ascii key'
  );
  print "Content-type: ".$drm->mime."\n";                       # Appropriate MIME type
  print "X-Oma-Drm-Separate-Delivery: 12\n";                    # The terminal expects WAP push 12 seconds later
  print $drm->separate_content($rights_issuer, $content_name);  # Encrypted content

You then need to send the rights object separately

=cut
sub separate_content {
    my ($self, $rights_issuer, $content_name)=@_;
	die "Need $rights_issuer" unless $rights_issuer;
	die "Need $content_name"  unless $content_name;
    use OMA::Download::DRM::CF;
    my $cf = OMA::Download::DRM::CF->new(
        ### Mandatory
        'key'                 => $self->{'key'},
        'data'                => $self->{data},
        'content-type'        => $self->{'content-type'},
        'content-uri'         => 'cid:'.$self->{uid}.'@'.$self->{domain},
        'Rights-Issuer'       => $rights_issuer,
        'Content-Name'        => $content_name,
    );
	$self->{mime}=$cf->mime;
    return $cf->packit;
}


=head2 separate_rights

Separate delivery. Rights object packing.

  my $rights = $drm->separate_rights($permission, %constraint)  # you have to send this rights object via WAP Push.

=cut
sub separate_rights {
    my ($self, $permission, %constraint)=@_;
    use OMA::Download::DRM::REL::WBXML;
	my $rel = OMA::Download::DRM::REL::WBXML->new( 
       'key'                  => $self->{'key'},
       'permission'           => $permission,
        'uid'                 => 'cid:'.$self->{uid}.'@'.$self->{domain},
        %constraint
    );
	$self->{mime}=$rel->mime;
    return $rel->packit;
}
1;
__END__

=head1 SEE ALSO

OMA::Download::DRM::REL

OMA::Download::DRM::CF

=head1 REVISION INFORMATION

1.00.07		Various improvements

1.00.04		First public release

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bpgn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Bernard Nauwelaerts, IT Development Belgium

Released under the GPL.

=cut
