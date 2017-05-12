#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
use strict;

use Test::More tests => 68;

BEGIN { use_ok('POE::Component::Enc::Flac') };

use POE;
use File::Copy;

my $TEST_MISSING      = 't/missing.wav';
my $TEST_INPUT        = 't/test.wav';
my $TEST_INPUT_COPY   = 't/test2.wav';
my $TEST_OUTPUT       = 't/test.flac';
my $TEST_OUTPUT_COPY  = 't/test_2.flac';

unlink $TEST_OUTPUT;

#########################

my ($encoder1, $encoder2, $encoder3, $encoder4, $encoder5);

#########################
# Check construction with defaults
my %defaults = (
    parent      => 'main',
    priority    => 0,
    compression => 5,
    status      => 'status',
    error       => 'error',
    done        => 'done',
    warning     => 'warning',
    );

$encoder1 = POE::Component::Enc::Flac->new();
ok ( $encoder1->isa('POE::Component::Enc::Flac'), 'it\'s an encoder' );
can_ok( $encoder1, qw(enc) );

diag("Check parameter defaults");
foreach (keys %defaults) {
    is ( $encoder1->{$_}, $defaults{$_}, $_ . ' default' );
    }

#########################
# Check construction with arguments
my %params = (
    parent      => 'mySession',
    priority    => 1,
    compression => 3,
    status      => 'cb_status',
    error       => 'cb_error',
    done        => 'cb_done',
    warning     => 'cb_warning',
    );
my %params2 = (
    parent      => 'mySession',
    priority    => 10,
    compression => 1,
    status      => 'cb_status',
    error       => 'cb_error',
    done        => 'cb_done',
    warning     => 'cb_warning',
    delete      => 1,
    output      => $TEST_OUTPUT_COPY,
    );

$encoder2 = POE::Component::Enc::Flac->new(%params);
isa_ok ( $encoder2, 'POE::Component::Enc::Flac');

diag("Check parameters");
foreach (keys %params) {
    is ( $encoder2->{$_}, $params{$_}, '# ' . $_ . ' parameter' );
    }

$encoder3 = POE::Component::Enc::Flac->new(%params);
isa_ok ( $encoder3, 'POE::Component::Enc::Flac');
$encoder4 = POE::Component::Enc::Flac->new(%params);
isa_ok ( $encoder4, 'POE::Component::Enc::Flac');
$encoder5 = POE::Component::Enc::Flac->new(%params2);
isa_ok ( $encoder5, 'POE::Component::Enc::Flac');


my $main = POE::Session->create
  ( inline_states =>
      { _start           => \&main_start,
        _stop            => \&main_stop,
        $params{status}  => \&handle_status,
        $params{error}   => \&handle_error,
        $params{done}    => \&handle_done,
        $params{warning} => \&handle_warning,
      }
  );


POE::Kernel->run();

my %expect;

sub main_start
  {
  my ($heap, $kernel) = @_[HEAP, KERNEL];

  POE::Kernel->alias_set($params{parent});

  SKIP :
    {
    skip "Need the executable 'flac'", 40 unless have_encoder();

    diag "Start encoder 4 with no input\n";
    is(eval {$encoder4->enc()}, undef);
    like ($@, qr/No input file specified/);

    diag "Start encoder 2 with missing input $TEST_MISSING\n";
    push @{$expect{$encoder2}}, (
      'error:256;can\'t open input file',
      'error:256;can\'t open input file'
    );
    $encoder2->enc( input=>$TEST_MISSING );

    diag "Start encoder 3 with $TEST_INPUT\n";
    push @{$expect{$encoder3}}, (
      "status:$TEST_INPUT;$TEST_OUTPUT;[0-9]+;[0-9]\.[0-9]:+",
      "done:$TEST_INPUT;$TEST_OUTPUT:",
    );
    $encoder3->enc( input=>$TEST_INPUT );

    copy($TEST_INPUT, $TEST_INPUT_COPY);

    diag "Start encoder 5\n";
    push @{$expect{$encoder5}}, (
      "status:$TEST_INPUT_COPY;$TEST_OUTPUT_COPY;[0-9]+;[0-9]\.[0-9]:+",
      "done:$TEST_INPUT_COPY;$TEST_OUTPUT_COPY:",
    );
    $encoder5->enc( input   => $TEST_INPUT_COPY,
                    comment => [
                                'artist=An Artist',
                                'tag1=Tag 1',
                                'tag2=Tag 2',
                                'title=A Title',
                               ],
                  );
    }

  }

sub have_encoder
    {
    1 if (-x '/usr/bin/flac' || -x '/usr/local/bin/flac')
      or diag "Did not find executable /usr/bin/flac or /usr/local/bin/flac";
    }

sub have_metaflac
    {
    1 if (-x '/usr/bin/metaflac' || -x '/usr/local/bin/metaflac')
      or diag "Did not find executable /usr/bin/metaflac or /usr/local/bin/metaflac";
    }

sub main_stop
  {
  SKIP :
    {
    skip "'flac' is not an executable", 3 unless have_encoder();

    ok( (-f $TEST_OUTPUT), 'output file created');
    ok( (-f $TEST_OUTPUT_COPY), 'output file created');
    ok( (!-f $TEST_INPUT_COPY), 'input file deleted');
    }

  SKIP :
    {
    skip "Need the executable 'metaflac'", 4 unless have_metaflac();

    my $artist = `metaflac --show-vc-field=artist $TEST_OUTPUT_COPY`
        or die "Cannot run metaflac $TEST_OUTPUT_COPY: $!";
    my $title = `metaflac --show-vc-field=title $TEST_OUTPUT_COPY`
        or die "Cannot run metaflac $TEST_OUTPUT_COPY: $!";
    my $tag1 = `metaflac --show-vc-field=tag1 $TEST_OUTPUT_COPY`
        or die "Cannot run metaflac $TEST_OUTPUT_COPY: $!";
    my $tag2 = `metaflac --show-vc-field=tag2 $TEST_OUTPUT_COPY`
        or die "Cannot run metaflac $TEST_OUTPUT_COPY: $!";

    chomp $artist; chomp $title; chomp $tag1; chomp $tag2;

    cmp_ok($artist, 'eq', 'artist=An Artist');
    cmp_ok($title, 'eq', 'title=A Title');
    cmp_ok($tag1, 'eq', 'tag1=Tag 1');
    cmp_ok($tag2, 'eq', 'tag2=Tag 2');
    }

  unlink $TEST_OUTPUT;
  unlink $TEST_OUTPUT_COPY;
  }

sub ok_expecting
  {
  my ($from, $sent, $arg) = @_;
  my $expected  = shift @{$expect{$from}} || 'nothing';
  my $expected2 = shift @{$expect{$from}} || 'nothing';

  my @exp=split /:/,$expected;  my ($exp,  $exparg,  $expmany)  = @exp;
     @exp=split /:/,$expected2; my ($exp2, $exparg2, $expmany2) = @exp;

  #diag "got $sent(" . ($arg||'') . ") from $from; expecting $expected or $expected2\n";

  like ($sent, qr/$exp|$exp2/);
  $exparg2 |= '';
  like ($arg, qr/$exparg|$exparg2/i) if ($exparg);

  unshift @{$expect{$from}}, $expected2 unless ($expected2 eq 'nothing');
  if ($expmany) { unshift @{$expect{$from}}, $expected; }
  }

sub handle_error {
  ok_expecting($_[ARG0], 'error', join ';', $_[ARG3], $_[ARG4]);
  }

sub handle_status {
  cmp_ok($_[ARG1], 'ne', undef, 'status handler ARG1 is defined');
  cmp_ok($_[ARG2], 'ne', undef, 'status handler ARG2 is defined');
  ok_expecting($_[ARG0], 'status', join ';',$_[ARG1],$_[ARG2],$_[ARG3],$_[ARG4]);
}

sub handle_done {
  cmp_ok($_[ARG1], 'ne', undef, 'done handler ARG1 is defined');
  cmp_ok($_[ARG2], 'ne', undef, 'done handler ARG2 is defined');
  ok_expecting($_[ARG0], 'done', join ';',$_[ARG1],$_[ARG2]);
}

sub handle_warning {
  cmp_ok($_[ARG1], 'ne', undef, 'warning handler ARG1 is defined');
  cmp_ok($_[ARG2], 'ne', undef, 'warning handler ARG2 is defined');
  ok_expecting($_[ARG0], 'warning', $_[ARG3]);
}
