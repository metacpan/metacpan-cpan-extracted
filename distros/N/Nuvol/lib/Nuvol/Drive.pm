package Nuvol::Drive;
use Mojo::Base -base, -signatures;

# constructor

sub new ($class, $connector, $params) {

  # check params
  Carp::croak 'Parameter metadata, id or path required!'
    unless $params->{metadata} || $params->{id} || $params->{path};

  my $self = bless {connector => $connector}, $class;

  my $service = $connector->SERVICE;
  $self->with_roles("Nuvol::${service}::Drive");

  $self->with_roles('Nuvol::Role::Metadata');
  $self->_parse_parameters($params);

  return $self;
}

# methods

sub connector ($self) { return $self->{connector}; }

sub item ($self, $path) {
  require Nuvol::Item;
  my $type = $path =~ m|/$| ? 'Folder' : 'File';
  return Nuvol::Item->new($self, {path => $path, type => $type});
}

1;

=encoding utf8

=head1 NAME

Nuvol::Drive - Container for cloud drives

=head1 SYNOPSIS

    use Nuvol;
    my $connector = Nuvol::connect($configfile);
    my $drive     = $connector->drive($path);

    use Nuvol::Drive;
    my $drive = Nuvol::Drive->new($connector, $params);
 
    $drive->connector;
    $drive->item;

    # metadata
    $drive->description;
    $drive->id;
    $drive->metadata;
    $drive->name;

=head1 DESCRIPTION

L<Nuvol::Drive> is a container for cloud drives. The constructor automatically activated the
appropriate service, which is one of L<Nuvol::Dummy::Drive>, L<Nuvol::Office365::Drive>.

=head1 CONSTRUCTOR

=head2 via Nuvol

    use Nuvol;
    $connector = Nuvol::connect($configfile);

    $drive = $connector->drive($path);
    $drive = $connector->drives->first;

In daily use a L<Nuvol::Drive> is created with L<Nuvol::Connector/drive> or
L<Nuvol::Connector/drives>.

=head2 new

    $drive = Nuvol::Drive->new($connector, {id       => $id});
    $drive = Nuvol::Drive->new($connector, {metadata => $metadata});
    $drive = Nuvol::Drive->new($connector, {path     => $path});

The constructor is called internally and can be used when the C<metadata> or C<id> of the drive are
known.

=head1 METHODS

L<Nuvol::Connector> inherits the following methods from L<Nuvol::Role::Metadata>:

=over

=item L<description|Nuvol::Role::Metadata/description>

=item L<id|Nuvol::Role::Metadata/id>

=item L<metadata|Nuvol::Role::Metadata/metadata>

=item L<name|Nuvol::Role::Metadata/name>

=item L<url|Nuvol::Role::Metadata/url>

=back

=head2 connector

    $connector = $drive->connector;

Getter for the connector. Returns a L<Nuvol::Connector>.

=head2 item

    $item = $drive->item($path);
  
Getter for an item with the specified C<path>. Returns a L<Nuvol::Item>.

    $file   = $drive->item('/path/to/file');
    $folder = $drive->item('/path/to/folder/');

Paths must be absolute (starting with a slash). Paths with trailing slash are interpreted as
L<folders|Nuvol::Role::Folder>, without slash as L<files|Nuvol::Role::File>.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Item>, L<Nuvol::Role::File>, L<Nuvol::Role::Folder>.

=cut
