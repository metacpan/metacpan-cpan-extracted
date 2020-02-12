package Nuvol::Item;
use Mojo::Base -base, -signatures;

# constructor

sub new ($class, $drive, $params) {

  # check params
  Carp::croak 'Parameter metadata, id or path required!'
    unless $params->{metadata} || $params->{id} || $params->{path};

  my $self = bless {drive => $drive}, $class;

  my $service = $drive->SERVICE;
  $self->with_roles("Nuvol::${service}::Item");
  $self->{type} = $self->_get_type($params) or Carp::croak 'Unable to detect type!';

  $self->with_roles('Nuvol::Role::Metadata');
  $self->_parse_parameters($params);
  if ($self->{type} ne 'Unknown') {
    $self->with_roles("Nuvol::${service}::$self->{type}", "Nuvol::Role::$self->{type}");
  }

  return $self;
}

# methods

sub drive ($self)  { return $self->{drive}; }
sub exists ($self) { return $self->_check_existence; }
sub file ($self)   { return $self->{type} eq 'File'; }
sub folder ($self) { return $self->{type} eq 'Folder'; }
sub type ($self)   { return $self->{type}; }

# internal methods

# disables Nuvol::Role::Metadata::_load
sub _load ($self) {
  unless ($self->{metadata}) {
    $self->_set_metadata($self->_load_metadata);
    $self->{type} = $self->_get_type;
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Item - Item in a drive

=head1 SYNOPSIS

    use Nuvol;
    my $drive = Nuvol::connect($configfile)->drive($drive_path);
    my $item  = $drive->item($path);

    $item->drive;
    $item->exists;
    $item->file;
    $item->folder;
    $item->type;

    # files
    $item->copy_from;
    $item->copy_to;
    $item->spurt;
    $item->slurp;
    $item->download_url;
    $item->remove;

    # folders
    $item->make_path;
    $item->remove_tree;

    # metadata
    $item->description;
    $item->id;
    $item->metadata;
    $item->name;

=head1 DESCRIPTION

L<Nuvol::Item> is an item in a drive. It can be either a L<file|Nuvol::Role::File> or a
L<folder|Nuvol::Role::Folder>.

=head1 CONSTRUCTOR

=head2 via Nuvol::Drive

    use Nuvol;
    $drive = Nuvol::Connector->new($configfile)->drive(%drive_path);

    $file   = $connector->item('path/to/file');
    $folder = $connector->item('path/to/folder/');

In daily use a L<Nuvol::Item> is created with L<Nuvol::Drive/item>. Paths with trailing slash are
interpreted as L<folders|Nuvol::Role::Folder>, without slash as L<files|Nuvol::Role::File>.

=head2 new

    $item = Nuvol::Item->new($drive, {id       => $id});
    $item = Nuvol::Item->new($drive, {metadata => $metadata});
    $item = Nuvol::Item->new($drive, {path     => $path});

The internal constructor can be used if the C<id> or C<metadata> of the item are known.

=head1 METHODS

If a L<Nuvol::Item> is a file it inherits the following methods from L<Nuvol::Role::File>:

=over

=item L<copy_from|Nuvol::Role::File/copy_from>

=item L<copy_to|Nuvol::Role::File/copy_to>

=item L<spurt|Nuvol::Role::File/spurt>

=item L<slurp|Nuvol::Role::File/slurp>

=item L<download_url|Nuvol::Role::File/download_url>

=item L<remove|Nuvol::Role::File/remove>

=back

A folder inherits the following methods from L<Nuvol::Role::Folder>:

=over

=item L<make_path|Nuvol::Role::Folder/make_path>

=item L<remove_tree|Nuvol::Role::Folder/remove_tree>

=back

All item types inherit the following methods from L<Nuvol::Role::Metadata>:

=over

=item L<description|Nuvol::Role::Metadata/description>

=item L<id|Nuvol::Role::Metadata/id>

=item L<metadata|Nuvol::Role::Metadata/metadata>

=item L<name|Nuvol::Role::Metadata/name>

=item L<url|Nuvol::Role::Metadata/url>

=back

=head2 drive

    $drive = $item->drive;

Getter for the drive. Returns a L<Nuvol::Drive>.

=head2 exists

    $bool = $item->exists;

Checks if the item exists.

=head2 file

    $bool = $item->file;

Returns a true value if the L</type> of the item is C<File>.

=head2 folder

    $bool = $item->folder;

Returns a true value if the L</type> of the item is C<Folder>.

=head2 type

    $type = $item->type;

Getter for the type, can be C<File> or C<Folder>.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Role::File>, L<Nuvol::Role::Folder>.

=cut
