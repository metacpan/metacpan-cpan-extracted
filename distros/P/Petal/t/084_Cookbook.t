#!/usr/bin/perl

#
# Tests for Petal::Cookbook recipes
#
# To view output, use DEBUG environment setting.
#   DEBUG=1 perl t/084_Cookbook.t
# the output can be piped to w3m
#   DEBUG=1 perl t/084_Cookbook.t | w3m -T text/html
# or redirected to a file for viewing with a browser
#   DEBUG=1 perl t/084_Cookbook.t > output.html

use warnings;
use strict;
use lib ('lib');
use Test::More;
BEGIN {
    eval "use CGI";
    plan skip_all => "CGI required" if $@;
    plan 'no_plan';
}
use Petal;
use Data::Dumper;

my $template_file = 'cookbook.html';
$Petal::BASE_DIR = './t/data/';

# Fixup path for taint support
$ENV{PATH} = "/bin:/usr/bin";

# Setup Petal environment
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::INPUT = "XHTML";
$Petal::OUTPUT = "XHTML";

# Create object
my $template = new Petal($template_file);


# Basic - Passing a hashreference to Petal::process
my $hash = { string => 'Three', 'number' => 3 };
$hash->{'foo'} = "bar";
$hash->{'arrayref'} = [ {foo => 'Craig'}, {foo => 'Jim'} ];
$hash->{'arrayref'}->[2] = {'foo' => 'William'};


# Advanced - Invoking methods on objects
{
  package MyApplication::Record::Rater;
  use strict;
  use warnings;
  use CGI;
  use Carp;

  sub is_current_id {
    my $self = shift;
    return $self->{id} == 2;
    # Alternative way to evaluate current_id
    #my $cgi  = CGI->new;
    #my $id = $cgi->param('rater.id');
    #return unless (defined $id and $id and $id =~ /^\d+$/);
    #return $id == $self->{id};
  }
  1;
}
package main;
#use MyApplication::Record::Rater;
# Raters (id, first_name, last_name, relation, phone, email)
my @records = (
{
id => 1,
first_name => 'George',
last_name => 'Jetson',
relation => 'father',
phone => '411-232-3333',
email => 'george@spacely.com',
},
{
id => 2,
first_name => 'Judy',
last_name => 'Jetson',
relation => 'mother',
phone => '411-232-3333',
email => 'judy@spacely.com',
},
{
id => 3,
first_name => 'Jane',
last_name => 'Jetson',
relation => 'daughter',
phone => '411-232-3333',
email => 'jane@spacely.com',
},
);
bless $_, "MyApplication::Record::Rater" for (@records);
$hash->{'records'} = \@records;


# Advanced - Using CGI.pm to generate forms
use CGI qw(-compile [:all]);
$hash->{'query'} = new CGI;
$hash->{'choices'} = [1, 2, 3, 4];


my $out;
eval {
$out = $template->process($hash);
};
is($@, '', 'No errors during processing');
ok($out, 'Output was received');

print $out if $ENV{'DEBUG'};

1;


__END__
