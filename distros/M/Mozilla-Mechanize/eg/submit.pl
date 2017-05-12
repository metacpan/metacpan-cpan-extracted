#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Data::Dumper;
use lib '../lib';
use Mozilla::Mechanize;


my $moz = Mozilla::Mechanize->new;

my $dir = getcwd;
$moz->get("file://$dir/form.html");

print_status($moz);

my ($form) = $moz->forms;

my @input = $form->inputs;
print_inputs(\@input);

my $textfield = $form->find_input('name');
$textfield->value('slanning');

print_inputs(\@input);

$form->submit;

print_status($moz);

sub print_status {
    my $moz = shift;

    print "URL: ".$moz->uri."\n";
    print "HTML:\n".$moz->content;
    print "\n";
}

sub print_inputs {
    my $inputs = shift;

    foreach my $input (@$inputs) {
        printf("Input -- Name: %s, Type: %s, Value: %s\n",
               $input->name,
               $input->type,
               $input->value,
           );
    }

}

__END__

I do an form submit (either via $form->submit() oder $input->click())
and the request goes to the server (I have Catalyst in debug mode)
but the result page is not shown.

The attached example script shows what I mean - the page result.html
is never shown.
