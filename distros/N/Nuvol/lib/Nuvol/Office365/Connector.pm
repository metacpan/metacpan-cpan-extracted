package Nuvol::Office365::Connector;
use Mojo::Base -role, -signatures;

use constant {
  AUTH_URL => 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
  API_URL  => 'https://graph.microsoft.com/v1.0',
  DEFAULTS => {
    app_id        => '6bdc6780-1c1c-4f59-83f8-1b931306f556',
    redirect_uri  => 'https://login.microsoftonline.com/common/oauth2/nativeclient',
    response_type => 'code',
    scope         => 'Files.ReadWrite Files.ReadWrite.All User.Read offline_access',
  },
  INFO_URL  => 'https://graph.microsoft.com/v1.0/me',
  NAME      => 'Nuvol Office 365 Connector',
  TOKEN_URL => 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
  SERVICE   => 'Office365',
};

# internal methods

sub _build_url ($self, @path) {
  my $url = Mojo::URL->new($self->API_URL);
  push $url->path->@*, @path if @path;

  return $url;
}

sub _do_disconnect ($self) {}

sub _get_name ($self) {
  return $self->metadata->{displayName};
}

sub _get_description ($self) {
  my $metadata = $self->metadata;
  return $self->SERVICE . " $metadata->{displayName} <$metadata->{mail}>";
}

sub _load_drivelist ($self) {
  my @drives;

  # user's own drive
  my $onedrive   = $self->_ua_get($self->url('me/drive'))->json;
  my $drive_type = $onedrive->{driveType};

  # Office 365 Business
  if ($onedrive->{driveType} eq 'business') {

    # OneDrive for Business
    push @drives,
      {
      id       => $onedrive->{id},
      metadata => $onedrive,
      };

    # SharePoint
    my $teamwebsite = $self->_ua_get($self->url('sites/root/drive'))->json;
    push @drives,
      {
      id       => $teamwebsite->{id},
      metadata => $teamwebsite,
      };
  }

  # Office 365 Personal
  else {
    # OneDrive Personal
    push @drives,
      {
      id       => $onedrive->{id},
      metadata => $onedrive,
      };

    # shared drives
    my $shared = $self->_ua_get($self->url('me/drive/sharedWithMe'))->json;
    for my $remote ($shared->{value}->@*) {
      next if $remote->{remoteItem}->{file};

      push @drives,
        {
        id       => $remote->{id},
        metadata => $remote,
        };
    }
  }

  return @drives;
}

sub _load_metadata ($self) {
  my $res = $self->_ua_get($self->url('me'));
  Carp::confess $res->message if $res->is_error;

  return $res->json;
}

sub _update_token ($self, $config) {
  return $self->_update_oauth_token($config);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Office365::Connector - Internal methods for Office 365 connectors

=head1 DESCRIPTION

L<Nuvol::Office365::Connector> provides internal methods for Office 365 connectors.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Office365>.

=cut
