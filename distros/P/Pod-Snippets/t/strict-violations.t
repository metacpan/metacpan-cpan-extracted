#!/usr/bin/perl -w

use strict;

=head1 NAME

strict-violations.t - Tests that Pod::Snippets catches unsound POD
markup (but only when so instructed)

=head1 DESCRIPTION

=cut

use Test::More no_plan => 1;
use Pod::Snippets;

my $examples = Pod::Snippets->load($INC{"Pod/Snippets.pm"},
                                -markup => "metatests",
                                -named_snippets => "strict");

my %examples =
    ( (map { ($_ => $examples-> named("named_snippets $_ error")->as_data) }
       qw(impure multiple)),
      "overlap" => <<"OVERLAP_ERROR",

=for test "first" begin

 eennie();

=for test "second" begin

 minnie();

=for test "second" end

 moe();

=for test "first" end

OVERLAP_ERROR
        "bad_pairing" => <<"PAIRING_ERROR",

=for test "not closed" begin

  I can has contents?

PAIRING_ERROR
    );

=pod

First we have a go at testing general error management: by default
only C<bad_pairing> errors are warned (in a non-fatal way) and under
C<< -named_snippets => "strict" >> all of them cause a fatal error
(that is, the parser refuses to return snippets afterwards).

=cut

sub there_should_not_be_any_incidents { diag join(" ", @_); fail; }

foreach my $construct (qw(impure multiple overlap)) {
    my $example = $examples{$construct};
    my $snips = Pod::Snippets->parse
        ($example, -markup => "test",
         -report_errors => \&there_should_not_be_any_incidents);
    $snips = Pod::Snippets->parse
        ($example, -markup => "test",
         -named_snippets => "strict",
         -report_errors => sub {});
    cmp_ok($snips->errors, ">", 0, "Found errors in $construct");
    is($snips->warnings, 0, "No warnings in $construct");
}

{
    my $snips = Pod::Snippets->parse
        ($examples{bad_pairing}, -markup => "test",
         -report_errors => sub {});
    is($snips->warnings, 1, "warnings on by default for bad pairing");
    like($snips->named("not closed")->as_data,
         qr/I can has/, "parse warnings don't block retrieval of data");

    $snips = Pod::Snippets->parse
        ($examples{bad_pairing}, -markup => "test",
         -named_snippets => "strict",
         -report_errors => sub {});
    eval {
        $snips->named("not closed");
        fail("should have thrown");
        1;
    } or pass("exception when trying to fetch from a Pod::Snippets "
              . "with errors");
}

=pod

Then we test the detailed behavior of all the available
C<-named_snippets> switches.

=cut

my %snips;
foreach my $construct (qw(impure multiple overlap bad_pairing)) {
    my $example = $examples{$construct};
    my $snips = Pod::Snippets->parse
        ($example, -markup => "test",
         -named_snippets => "strict",
         -named_snippets => "ignore_$construct",
         -report_errors => \&there_should_not_be_any_incidents);
    is($snips->errors, 0, "Parsing $construct OK with lax settings");
    is($snips->warnings, 0, "No warnings in $construct with lax settings");
    $snips{$construct} = $snips;

    my %incidents;
    foreach my $mode (qw(warn error)) {
        %incidents = ( "ERROR" => 0, "WARNING" => 0);
        my $parsemode = "${mode}_${construct}";
        $snips = Pod::Snippets->parse
            ($example, -markup => "test",
             -named_snippets => $parsemode,
             -report_errors => sub { $incidents{$_[0]}++; });
        my $incidentcat = ($mode eq "warn") ? "WARNING" : "ERROR";
        my $othercat = ($mode eq "warn") ? "ERROR" : "WARNING";
        cmp_ok($incidents{$incidentcat}, ">", 0,
               "found " . lc($incidentcat) . "s in $construct" .
               " under $parsemode");
        is($incidents{$othercat}, 0,
               "found no " . lc($othercat) . "s in $construct" .
           " under $parsemode");
        is($snips->errors, $incidents{"ERROR"}, "Errors counted OK");
        is($snips->warnings, $incidents{"WARNING"}, "Warnings counted OK");
        if ($mode eq "warn") {
            is(scalar($snips->as_data),
               scalar($snips{$construct}->as_data),
               "warnings don't prevent one from getting the stuff back");
        }
    }
}

like($snips{multiple}->named("foobar")->as_data, qr/foobar\(\)/,
     "snippets with name used multiple times are joined together 1/2");
like($snips{multiple}->named("foobar")->as_data, qr/quux_some_more\(\)/,
     "snippets with name used multiple times are joined together 2/2");

like($snips{overlap}->named("second")->as_data, qr/minnie/,
     "nested snippets 1/3");
unlike($snips{overlap}->named("second")->as_data, qr/moe/,
     "nested snippets 2/3");
like($snips{overlap}->named("first")->as_data, qr/moe/,
     "nested snippets 3/3");


