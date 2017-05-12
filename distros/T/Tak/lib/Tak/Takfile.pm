package Tak::Takfile;

use strictures 1;
use warnings::illegalproto ();

sub import {
  strictures->import;
  warnings::illegalproto->unimport;
}

1;
