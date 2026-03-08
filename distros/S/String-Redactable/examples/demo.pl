#!/usr/bin/perl
use v5.20;
use utf8;

$|++;

=encoding

=pod

The

=cut

use String::Redactable;


{
use warnings qw(String::Redactable);

my $secret = 'A_12345';
my $redactable = String::Redactable->new($secret);
say "The secret is " . $redactable->to_str_unsafe;

say "The password is $redactable"; # warning here
say "The secret is " . $redactable->to_str_unsafe;

no warnings qw(String::Redactable);
say "The password is $redactable";
say "The secret is " . $redactable->to_str_unsafe;
}

{
no warnings qw(String::Redactable);

my $secret = 'B_12345';

my $redactable = String::Redactable->new($secret);
say "The secret is " . $redactable->to_str_unsafe;

say "The password is $redactable";
say "The secret is " . $redactable->to_str_unsafe;

say "The password is $redactable";
}


=head1 Part 2: Tie

=cut

use Tie::String::Redactable;

{


}


{



}
