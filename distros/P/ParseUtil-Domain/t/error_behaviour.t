#!/usr/bin/env perl

use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;
use Mock::Quick;
use ParseUtil::Domain ':parse';
use namespace::autoclean;

test 'cannot find tld' => sub {
    my ($self) = @_;
    my $control = qtakeover  'ParseUtil::Domain::ConfigData';
    $control->override(tld_regex => sub { return qr/notlds/; });
    throws_ok {
        parse_domain('somedomain.com'); 
    } qr/Could\snot\sfind\stld/, 'Croaks when tld not available.';
    my $metrics = $control->metrics;
    is($metrics->{tld_regex}, 1, 'Called once.');
    $control->restore('tld_regex');
    $control = undef;
};

test 'can find tld' => sub {
    my ($self) = @_;
    my $control = qtakeover  'ParseUtil::Domain::ConfigData';
    $control->override(tld_regex => sub { return qr/test/; });
    lives_ok {
        parse_domain('somedomain.test'); 
    } 'Finds tld.';
    my $metrics = $control->metrics;
    is($metrics->{tld_regex}, 1, 'Called once.');
    $control->restore('tld_regex');
    $control = undef;
};

test 'undefined mapping croaks' => sub {
    my ($self) = @_;
    throws_ok {
        ParseUtil::Domain::_punycode_segments(['']);
    } qr/Error\sprocessing\sdomain/, 'Croaks to death if domain segment empty.';
};

test 'normal mapping does not croak' => sub {
    my ($self) = @_;
    lives_ok {
        ParseUtil::Domain::_punycode_segments(['somedomain']);
    } 'Does not crash if domain mapping normal.';
};

test 'croak if nameprep different from decoded' => sub {
    my ($self) = @_;
    my $control = qtakeover 'ParseUtil::Domain';
    $control->override(nameprep => sub {die "Error processing domain";});
    throws_ok {
        ParseUtil::Domain::_punycode_segments(['somedomain']);
    } qr/Error\sprocessing\sdomain/, 'Croaks to death if nameprep result not equal.';
    $control->restore('nameprep');
    $control = undef;
};


run_me;
done_testing;
