package Object::HasMethod::Class;
use Pony::Object qw/Object::HasMethod::Base/;

  has __true_write_log => sub {
    return "too lazy";
  };

1;