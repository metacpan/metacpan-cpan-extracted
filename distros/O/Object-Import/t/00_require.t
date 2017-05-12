use Test::More tests => 2;

require_ok("Object::Import");
cmp_ok(1.001, "<=", $Object::Import::VERSION, "Object::Import::VERSION defined");

__END__
