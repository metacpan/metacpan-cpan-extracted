#! perl

{
  package MyApp::Plugin;
  use Moose;
  with 'MooseX::Role::Pluggable::Plugin';
  sub common { return "Common" }
}

{
  package MyApp::OtherPlugin::Bar;
  use Moose;
  with 'MooseX::Role::Pluggable::Plugin';
  sub bar { return "Bar" }
}

{
  package MyApp::Plugin::Baz;
  use Moose;
  extends 'MyApp::Plugin';
  sub baz { return "Baz" }
}

{
  package MyApp::Plugin::Foo;
  use Moose;
  extends 'MyApp::Plugin';
  has 'attr1' => ( is => 'rw' );
  sub foo { return "Foo" }
}

{
  package MyApp;
  use Moose;
  use namespace::autoclean;
  with 'MooseX::Role::Pluggable';
}

