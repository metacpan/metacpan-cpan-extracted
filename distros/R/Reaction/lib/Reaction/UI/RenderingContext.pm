package Reaction::UI::RenderingContext;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
sub render {
  confess "abstract method";
};

__PACKAGE__->meta->make_immutable;


1;
