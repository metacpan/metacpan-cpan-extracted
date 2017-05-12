#!/usr/bin/perl

package thing;

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    return $self;
}

sub method
{
   my $self = shift;
   join ':', @_;
}

package main;

use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $template_file = 'multiple-attributes.xml';
my $template      = new Petal ($template_file);

sub joinme {join ':', @_}
my $object = new thing;
my %hash = ( foo => 'bar' );

my $string        = $template->process (object => $object, coderef => \&joinme, hash => \%hash);

like ($string, '/harpo:chico/');
like ($string, '/groucho:zeppo/');

__END__
