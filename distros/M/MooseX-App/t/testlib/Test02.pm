package Test02;

use Moose;
use MooseX::App (qw(BashCompletion Version Man), ($ENV{HARNESS_ACTIVE} ? ():qw(ConfigHome Color Typo Term) ));

our $VERSION = 1.01;

app_namespace "Test02::Command","Test02::MoreCommands";
#app_fuzzy;

sub run {
    print "RAN";
}

1;

=encoding utf8

=head1 NAME

Test02 - Test 02

=head1 SYNOPSIS

do something

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=cut