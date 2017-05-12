class Bar {
  our $VERSION = 2;
  class ::Foo { 

    use vars qw/$VERSION/;
    # Nested version!
    our $VERSION = 3;
  }
}

class Baz { };

