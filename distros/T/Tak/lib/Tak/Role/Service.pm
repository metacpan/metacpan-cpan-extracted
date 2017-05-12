package Tak::Role::Service;

use Moo::Role;

sub start_request {
  my ($self, $req, $type, @payload) = @_;
  unless ($type) {
    $req->mistake(request_type => "No request type given");
    return;
  }
  if (my $meth = $self->can("handle_${type}")) {
    my @result;
    if (eval { @result = $self->$meth(@payload); 1 }) {
      $req->success(@result);
    } else {
      if (ref($@) eq 'ARRAY') {
        $req->result(@{$@});
      } else {
        $req->failure(exception => $@);
      }
    }
  } elsif ($meth = $self->can("start_${type}_request")) {
    $self->$meth($req => @payload);
  } else {
    $req->mistake(request_type => "Unknown request type ${type}");
  }
}

sub receive {
  my ($self, $type, @payload) = @_;
  if (my $meth = $self->can("receive_${type}")) {
    $self->$meth(@payload);
  }
}

# This assumes that by default either services are not stateful
# or do want to have persistent state. It's notably overriden by Router.

sub clone_or_self { $_[0] }

1;
