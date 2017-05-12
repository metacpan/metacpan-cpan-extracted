package Default::RequiredException {
  use Pony::Object;
  use Pony::Object::Throwable;

  sub do : Public {
    my $this = shift;
    
    try {
      throw Pony::Object::Throwable;
    } catch {
      # all fine
    };
    
    return "done";
  }
}

1;
