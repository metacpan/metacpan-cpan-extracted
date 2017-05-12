#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::JobControl::Helper::AuditLog;
$Rex::JobControl::Helper::AuditLog::VERSION = '0.18.0';
use base 'Mojo::Log';
use Mojo::JSON;
use DateTime;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  $self->{json} = Mojo::JSON->new;

  return $self;
}

sub audit {
  my ( $self, $data ) = @_;
  my ( $package, $filename, $line ) = caller;

  my $dt = DateTime->now;
  $data->{package} = $package;

  $self->info( $self->json->encode($data) );
}

sub json { (shift)->{json} }

1;
