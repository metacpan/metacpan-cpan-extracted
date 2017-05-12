#!/usr/bin/perl
# Dummy SVN::Notify class for testing purposes
package SVN::Notify::Dummy;
use base qw/SVN::Notify/;
use YAML;

use strict;
use vars qw ($VERSION);
$VERSION = 0.001;

sub execute {
    my ($self) = @_;
    print YAML->Dump($self);
}
