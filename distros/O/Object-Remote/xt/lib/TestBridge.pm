package TestBridge;
use Moo;

use TestClass;
use Object::Remote;

has object => (is => 'lazy');

sub _build_object { TestClass->new::on('-') }

sub result { (shift)->object->result }

1;
