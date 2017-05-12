package Nagios::Passive::BulkResult;
use Moo;
use MooX::late;
use IO::File;
use Carp qw/croak/;
use File::Temp;
use Scalar::Util qw/blessed/;

has 'checkresults_dir' => ( is => 'ro', isa => 'Str', required => 1);
has rpobjects => (
  is => 'rw',
  isa => 'ArrayRef[Nagios::Passive::ResultPath]',
  traits => ['Array'],
  default => sub { [] },
  handles => {
    add => 'push',
  },
);

with 'Nagios::Passive::Role::Tempfile';

sub submit {
  my $self = shift;

  # nothing to do if empty
  return unless @{$self->rpobjects};

  my $fh = $self->tempfile;

  print $fh "### Active Check Result File ###\n";
  print $fh sprintf("file_time=%d\n\n",time);

  for my $rp (@{ $self->rpobjects }) {
    my $output = $rp->_to_string . "\n";
    $fh->print($output) or croak($!);
  }

  $self->_touch_file;

  return $fh->filename;
}

1;
__END__

=head1 NAME

Nagios::Passive::BulkResult - submit passive check results to nagios' checkresult_dir in one file

=head1 SYNOPSIS

  my $bulk = Nagios::Passive::BulkResult->new(
    checkresults_dir => '/var/lib/nagios/checkresults',
  );
  for my $check (@checkresults) {
    my $nw = Nagios::Passive->create(
        checkresults_dir => undef, # the checkresults_dir key is required here
        service_description => $check->{service_description},
        check_name => $check_name,
        host_name  => $check->{hostname},
        return_code => $check->{code},
        output => 'looks (good|bad|horrible) | performancedata'
    );
    $bulk->add($nw);
  }
  $bulk->submit;

=head1 DESCRIPTION

Submitting a huge amount of results with L<Nagios::Passive::ResultPath> has some
limits. Typically a checkresult has a size of 200 bytes or so. But the blocksize
of most filesystems is about 4K. Therefore a file takes at least 4K of disk space.

Well, disk space is cheap and nagios deletes the file again after it has
processed it, but most of the time the checkresults_dir is a memory filesystem.
And suddenly you waste a lot of RAM. Also reading one large file is faster than
reading thousands of small files.

Nagios can handle multiple check results within one file. This is what this
module provides. You just create Nagios::Passive objects with an undefined
checkresults_dir and add these to the BulkResult container. When you
are done, just call C<-E<gt>submit> on the container and one big file is created.
