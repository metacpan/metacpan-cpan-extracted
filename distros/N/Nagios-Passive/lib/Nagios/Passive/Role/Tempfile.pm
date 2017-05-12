package Nagios::Passive::Role::Tempfile;

use Moo::Role;
use MooX::late;
use File::Temp;
use Fcntl qw/:DEFAULT :flock/;

requires 'checkresults_dir';

has 'tempfile' => ( is => 'ro', isa => 'File::Temp', lazy_build => 1);

sub _build_tempfile {
  my $self = shift;
  my $fh = File::Temp->new(
    TEMPLATE => "cXXXXXX",
    DIR => $self->checkresults_dir,
  );
  $fh->unlink_on_destroy(0);
  return $fh;
}

sub _touch_file {
  my $self = shift;
  my $fh = $self->tempfile;
  my $file = $fh->filename.".ok";
  sysopen my $t,$file,O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY
    or croak("Can't create $file : $!");
  close $t or croak("Can't close $file : $!");
  return;
}

1;

__END__
