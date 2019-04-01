{ $c->detach; }

{
    print "hi!";
    $c->detach;
}

{
    $c->detach if 1;
    print "hi!";
}

{
    $c->detach;
    sub foo { }
}

{
  package Foo::Controller::Root;
  print "hi!";
  $self->foo_and_detach;
}

{
  package Bar::Cooontroller::Root;
  $self->foo_and_detach;
  print "hi!";
}
