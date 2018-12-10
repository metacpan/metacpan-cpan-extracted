package QBit::Validator::PathManager;
$QBit::Validator::PathManager::VERSION = '0.012';
use qbit;

use base qw(QBit::Class);

use Exception::Validator::PathManager;

sub root {'/'}

sub delimiter {'/'}

sub concatenate {"$_[1]$_[3]$_[2]"}

sub hash_path {$_[1]}

sub array_path {$_[1]}

sub get_absolute_path {
    my ($self, $path, $root_path) = @_;

    my $root = $self->root;

    return $path if $path =~ /^\Q$root\E/;

    my $delimiter = $self->delimiter;

    $root_path //= $root;

    return $self->concatenate($root_path, $delimiter, $path);
}

sub get_path_part {
    my ($self, $type, $value) = @_;

    if ($type eq 'hash') {
        $value =~ s/%/%%/g;

        return $self->hash_path($value);
    } elsif ($type eq 'array') {
        return $self->array_path($value);
    } else {
        throw Exception::Validator::PathManager gettext('Unknown method: %s', $type);
    }
}

sub set_dynamic_part {push(@{$_[0]->{'__DYNAMIC__'}}, $_[1])}

sub reset_dynamic_part {pop(@{$_[0]->{'__DYNAMIC__'}})}

sub get_current_node_path {
    sprintf($_[1], map {$$_} @{$_[0]->{'__DYNAMIC__'}});
}

sub get_data_by_path {
    my ($self, $path, $data) = @_;

    my $root = $self->root;
    $path =~ s/^\Q$root\E//;

    $path =~ s/(?<!\.)\.(?!\.)\/?//g;
    while ($path =~ s/[0-9a-zA-Z_]+\/\.\.\/?//) { }

    my @parts = split($self->delimiter, $path);

    my $current = $data;
    foreach (@parts) {
        if (ref($current) eq 'HASH') {
            $current = $current->{$_};
        } elsif (ref($current) eq 'ARRAY') {
            $current = $current->[$_];
        } else {
            return $current;
        }
    }

    return $current;
}

TRUE;

=encoding utf8

=head1 Name

QBit::Validator::PathManager - path manager. It's works with simple hash keys only.

  $key =~ /^[0-9a-zA-Z_]+\z/

=head1 Package methods

=head2 new

create object QBit::Validator::PathManager

B<Example:>

  my $path_manager = QBit::Validator::PathManager->new();

=head2 root

returns root symbol (default: '/')

B<Example:>

  my $root = $path_manager->root();

=head2 delimiter

return delimiter (default: '/')

B<Example:>

  my $delimiter = $path_manager->delimiter();

=head2 concatenate

concatenate root path, delimiter and path part

B<Example:>

  my $root_path = '/key';

  my $path = $path_manager->concatenate($root_path, $path_manager->delimiter, 'key2');
  # /key/key2

=head2 hash_path

returns path for hash key (default: as it is). You can use this method for escape a hash key if needed.

B<Example:>

  my $hash_path = $path_manager->hash_path('field');
  # 'field'

=head2 array_path

returns path for array index (default: as it is). You can use this method for escape a array index if needed.

B<Example:>

  my $array_path = $path_manager->array_path(0);
  # 0

=head2 get_data_by_path

returns data by path. No difference between hash key and array index in path. Hash key must satisfy regex

  /^[0-9a-zA-Z_]+\z/.

Path consists of:

=over

=item

B<root symbol> - '/'

=item

B<delimiter> - '/'

=item

B<current element> - '.'

=item

B<parent> - '..'

=back

B<Example:>

  my $data = {
      key  => 1,
      key2 => [
        2,
        3,
      ],
  };

  $path_manager->get_data_by_path('/', $data);            # $data
  $path_manager->get_data_by_path('/key', $data);         # 1
  $path_manager->get_data_by_path('/key/.', $data);       # 1
  $path_manager->get_data_by_path('/key2', $data);        # [2, 3]
  $path_manager->get_data_by_path('/key2/0', $data);      # 2
  $path_manager->get_data_by_path('/key2/../key', $data); # 1

=head1 Your path manager

You can write path manager for your favoriet data manager (Data::DPath, JSON::Pointer, JSON::Path, etc)

B<Example:>

  package QBit::Validator::PathManager::Data::DPath;

  use base qw(QBit::Validator::PathManager);

  use Data::DPath qw(dpath);
  use String::Escape qw(qqbackslash);

  sub hash_path {qqbackslash($_[1])}

  sub array_path {'[$_[1]]'}

  sub get_data_by_path {my @result = dpath($_[1])->match($_[2]); return $result[0];}

  1;
