# An exception class used as a way to convey that some thrown errors are benign.
# This is a hack for the purpose of https://harmonica-tabs-creator.com

package Music::Harmonica::TabsCreator::Warning;

use 5.036;
use strict;
use warnings;
use utf8;

use overload '""' => 'as_string';

our $VERSION = '0.01';

sub new ($class, $message) {
  my $self = bless {message => $message,}, $class;
  return $self;
}

sub as_string ($self, $, $) {
  return $self->{message}."\n";
}

1;
