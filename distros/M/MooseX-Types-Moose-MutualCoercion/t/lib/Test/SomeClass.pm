package Test::SomeClass;

use Moose;

use namespace::clean -except => [qw(meta)];

__PACKAGE__->meta->make_immutable;

1;
__END__
