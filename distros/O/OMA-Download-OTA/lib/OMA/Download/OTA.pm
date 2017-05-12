package OMA::Download::OTA;
use strict;
BEGIN {
    $OMA::Download::OTA::VERSION = '1.00.06';
}
=head1 NAME

OMA::Download::OTA - Perl extension for creating download descriptor objects according to the OMA Download OTA 1.0 specification.

=head1 DESCRIPTION

Complete implementation of the Open Mobile Alliance Download Over The Air 1.0 specification.

=head1 SYNOPSIS

  use OMA::Download::OTA;
  
=head1 CONSTRUCTOR

=head2 new

  my $ota = OMA::Download::OTA->new(%properties);

=cut
sub new {
    my ($class, %arg)=@_;
    my $self={
        properties => {
            name             => $arg{name},
            vendor           => $arg{vendor},
            type             => $arg{type},
            size             => $arg{size},
            description      => $arg{description},
            objectURI        => $arg{objectURI},
            installNotifyURI => $arg{installNotifyURI},
            nextURL          => $arg{nextURL},
            DDVersion        => '1.0',
            infoURL          => $arg{infoURL},
            iconURI          => $arg{iconURI},
            installParam     => $arg{installParam},
        },
        status => {
            900    =>    'Success',
            901    =>    'Insufficient memory',
            902    =>    'User Cancelled',
            903    =>    'Loss of Service',
            905    =>    'Attribute mismatch',
            906    =>    'Invalid descriptor',
            951    =>    'Invalid DDVersion',
            952    =>    'Device Aborted',
            953    =>    'Non-Acceptable Content',
            954    =>    'Loader Error'
        }
    };
    $self=bless $self, $class;
    $self;
}
=head1 PROPERTIES

=head2 name

Get or set the download name

  print $ota->name;
  
  $ota->name('Nice download');

=cut
sub name {
    my ($self, $val)=@_;
    $self->{name} = $val if $val;
    $self->{name}
}

=head2 vendor

Get or set the download vendor name

  print $ota->vendor;
  
  $ota->vendor('My Cool Company');

=cut
sub vendor {
    my ($self, $val)=@_;
    $self->{vendor} = $val if $val;
    $self->{vendor}
}

=head2 type

Get or set the download MIME type

  print $ota->type;
  
  $ota->type('image/gif');

=cut
sub type {
    my ($self, $val)=@_;
    $self->{type} = $val if $val;
    $self->{type}
}

=head2 size

Get or set the download file size

  print $ota->size;
  
  $ota->size(65536);

=cut
sub size {
    my ($self, $val)=@_;
    $self->{size} = $val if defined $val;
    $self->{size}
}

=head2 description

Get or set the download description

  print $ota->description
  
  $ota->description('A nice picture of the Moon');

=cut
sub description {
    my ($self, $val)=@_;
    $self->{description} = $val if defined $val;
    $self->{description}
}

=head2 objectURI

Get or set the download object URI

  print $ota->objectURI;
  
  $ota->objectURI('http://example.com/image123.gif');

=cut
sub objectURI {
    my ($self, $val)=@_;
    $self->{objectURI} = $val if $val;
    $self->{objectURI}
}

=head2 installNotifyURI

Get or set the intall notificatition URI.

  print $ota->installNotifyURI;
  
  $ota->installNotifyURI('http://example.com/notify.cgi');

=cut
sub installNotifyURI {
    my ($self, $val)=@_;
    $self->{installNotifyURI} = $val if defined $val;
    $self->{installNotifyURI}
}

=head2 nextURL

Get or set the next URL 

  print $ota->nextURL;
  
  $ota->nextURL('http://example.com/complete.html');

=cut
sub nextURL {
    my ($self, $val)=@_;
    $self->{nextURL} = $val if defined $val;
    $self->{nextURL}
}

=head2 DDVersion

Get or set the download descriptor version. Defaults to 1.0.

  print $ota->DDVersion;
  
  $ota->DDVersion('1.0');

=cut
sub DDVersion {
    my ($self, $val)=@_;
    $self->{DDVersion} = $val if $val;
    $self->{DDVersion}
}

=head2 infoURL

Get or set the donwload info URL

  print $ota->infoURL;
  
  $ota->infoURL('http://example.com/moon.html');

=cut
sub infoURL {
    my ($self, $val)=@_;
    $self->{infoURL} = $val if defined $val;
    $self->{infoURL}
}

=head2 iconURI

Get or set the download icon URI

  print $ota->iconURI;
  
  $ota->iconURI('http://example.com/moon.gif');

=cut
sub iconURI {
    my ($self, $val)=@_;
    $self->{iconURI} = $val if defined $val;
    $self->{iconURI}
}

=head2 installParam

Get or set intall parameter

=cut
sub installParam {
    my ($self, $val)=@_;
    $self->{installParam} = $val if defined $val;
    $self->{installParam}
}

=head2 mime

Returns the Download Descriptor MIME type

  print $ota->mime;

=cut
sub mime {
    'application/vnd.oma.dd+xml'
}

=head1 METHODS

=head2 packit

Returns the Download Descriptor

  print $ota->packit;

=cut
sub packit {
    my ($self)=@_;
    my $res='';
    for my $p (keys %{$self->{properties}}) {
        my $c = $self->{properties}{$p};
        if ($c) {
            if (ref $c eq 'ARRAY') {
                for my $c (@$c) {
                    $res.=_in_element($p, $c);
                }
            } else {
                $res.=_in_element($p, $c);
            }
        }
    }
    return '<media xmlns="http://www.openmobilealliance.org/xmlns/dd">'."\n".$res.'</media>'
}

## Private
sub _in_element {
    my ($element, $content)=@_;
    my $res='<'.$element;
    if ($content) {
        $res.='>'.$content.'</'.$element.'>'."\n"
    } else {
        $res.='/>'
    }
    $res;
}
1;
__END__
=head1 SEE ALSO

OMA Download OTA Specifications

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bpgn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Released under the GPL. See LICENCE for details.

Copyright (C) 2006 by Bernard Nauwelaerts

=cut
