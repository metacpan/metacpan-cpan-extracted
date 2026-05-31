package Protocol::Tus::LocalDir;
{ our $VERSION = '0.003' }
use Moo;
use v5.24;
use warnings;
use experimental qw< signatures >;

use English;
use JSON::PP qw< decode_json encode_json >;
use Ouch qw< :trytiny_var >;
use Path::Tiny qw< path >;
use Try::Catch;

use constant COMPLETE_FILE => 'complete';
use constant DATA_FILE     => 'data';
use constant INFO_FILE     => 'info.json';

sub to_real_dir ($path) {
   $path = path($path);
   $path->mkdir;
   return $path;
}

use namespace::clean;

extends 'Protocol::Tus::AbstractModel';

has root => (is => 'ro', required => 1, coerce => \&to_real_dir);

sub cleanup ($self, $id) {
   if (defined($id)) {
      my $path = $self->resolve_path($id);
      $path->remove_tree({ safe => 0 }) if $path->exists;
   }
   return $self;
}

sub create_upload ($self, $length, $metadata) {
   my $path = $self->root->tempdir(template => ('X' x 11), CLEANUP => 0);
   $path->child(DATA_FILE)->touch;
   $self->update_info($path,
      {
         length => $length,
         metadata => $metadata,
      }
   );
   return $self->upload_for($path->basename);
}

sub extensions ($self) {
   return qw<
      creation
      creation-defer-length
      creation-with-upload
      checksum
      termination
   >;
}

sub finalize ($self, $id) {
   my $dir = $self->resolve_path($id, must_exist => 1);
   $dir->child(COMPLETE_FILE)->touch;
   return $self;
}

sub get_info ($self, $id) {
   my $path = $self->resolve_path($id, must_exist => 1);
   my $info = decode_json($path->child(INFO_FILE)->slurp_raw);
   $info->{offset} = $path->child(DATA_FILE)->size;
   $info->{complete} = $path->child(COMPLETE_FILE)->exists;
   return $info;
}

sub save_chunk ($self, $id, $offset, $dref) {
   try {
      my $dir = $self->resolve_path($id, must_exist => 1);
      my $path = $dir->child(DATA_FILE);
      open my $fh, '+<', $path
         or die "open('$path'): $OS_ERROR";
      seek($fh, $offset, 0)
         or die "seek('$path', $offset, 0): $OS_ERROR\n";
      print {$fh} $$dref
         or die "print('$path'): $OS_ERROR\n";
      close($fh)
         or die "close('$path'): $OS_ERROR\n";
   }
   catch { ouch 500, 'error saving data', $_ };
   return;
}

sub set_length ($self, $id, $length) {
   my $path = $self->resolve_path($id, must_exist => 1);
   $self->update_info($path, { length => $length });
   return $self;
}

sub resolve_path ($self, $id, %opts) {
   ouch 400, 'Invalid identifier' if $id =~ m{[^\w]}mxs;
   my $path = $self->root->child($id);
   $path->mkdir if delete($opts{ensure});
   ouch 404, 'Not Found' if delete($opts{must_exist}) && ! $path->exists;
   return $path unless scalar(keys(%opts));
   my $keys = join ', ', sort { $a cmp $b } keys(%opts);
   ouch 500, 'Internal Server Error', "resolve_path: unsupported: $keys";
}

sub update_info ($self, $dirpath, $stuff) {
   my $path = $dirpath->child(INFO_FILE);
   my $info = $path->exists ? decode_json($path->slurp_raw) : {};
   $info->{$_} = $stuff->{$_} for keys($stuff->%*);
   $path->spew_raw(encode_json($info));
   return $self;
}

1;
