package Protocol::Tus::Response;
{ our $VERSION = '0.004' }
use Moo;
use v5.24;
use warnings;
use experimental qw< signatures >;
use Protocol::Tus::Util qw< as_ouch >;
use namespace::clean;

has _status => (is => 'ro', init_arg => 'status', default => undef);
has headers => (is => 'ro', default => sub { return {} });
has body => (is => 'ro', default => '');
has exception => (is => 'ro', default => undef);
has upload => (is => 'ro', default => undef);

sub status ($self, @new) {
   return $self->_status($new[0]) if @new;
   if (defined(my $retval = $self->_status)) {
      return $retval;
   }
   return 204 if length($self->body // '') == 0;
   return 200;
}

sub new_from_exception ($package, $exception, %args) {
   $exception = as_ouch($exception);
   my $response = $package->new(
      %args,
      status => $exception->code,
      body   => $exception->message,
      exception => $exception,
   );
   my $data = $exception->data;
   $response->{headers} = $data->{headers}
      if ref($data) eq 'HASH' && exists($data->{headers});
   return $response;
}

sub as_hash ($self) {
   return {
      status => $self->status,
      headers => $self->headers // {},
      body => $self->body // '',
   };
}

sub more_headers ($self, $headers) {
   my $current = $self->headers;
   $current->{$_} = $headers->{$_} for keys($headers->%*);
   return $self;
}

sub id ($self) {
   my $upload = $self->upload or return;
   return $upload->id;
}

sub is_error ($self) {
   return $self->status >= 400;
}

1;
