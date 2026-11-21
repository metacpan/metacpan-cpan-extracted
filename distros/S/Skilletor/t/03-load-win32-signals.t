#!/usr/bin/env perl
# Every module loads where POSIX has only the signal macros Windows has (k261). Strawberry Perl's
# POSIX defines those of the C runtime – SIGABRT SIGFPE SIGILL SIGINT SIGSEGV SIGTERM, SIGBREAK,
# SIG_DFL SIG_ERR SIG_IGN – and dies on any other the moment it is evaluated: "Your vendor has not
# defined POSIX macro SIGHUP, used at lib/Skilletor/State.pm line 344" failed the require of
# Skilletor::State, and with it of the whole CLI (k251's stop numbers built at file scope).
#
# This perl's POSIX is made to die on the others the way Windows' does before a module of the
# dist is loaded, then every module under lib/ is loaded. A second check reads lib/ and script/:
# their code names none of those macros – as POSIX::<name> or imported from POSIX – save the
# allowed ones below, so a path that runs on Windows cannot reach one either. A signal's number
# is looked up by name where it is needed (POSIX->can), a signal sent or caught by name (kill,
# %SIG), which perl knows on Windows too.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find ();
use File::Spec ();
use POSIX ();

# POSIX fills %EXPORT_TAGS on its first import: here, into a package of its own.
{ package SkilletorTest::SignalH; POSIX->import(':signal_h') }

my %c_runtime = map { $_ => 1 } qw( SIGABRT SIGFPE SIGILL SIGINT SIGSEGV SIGTERM SIGBREAK SIG_DFL SIG_ERR SIG_IGN );
my @lacking = sort grep { /\A(?:SIG|SA_)\w+\z/ && !$c_runtime{$_} } @{ $POSIX::EXPORT_TAGS{signal_h} };
cmp_ok( scalar @lacking, '>', 30, 'POSIX names the signal macros Windows lacks' );
ok( ( grep { $_ eq 'SIGHUP' } @lacking ), 'SIGHUP among them' );

# Named in code that never runs on Windows, with the reason.
my %allowed = (
  'lib/Skilletor/State.pm' => { SIG_UNBLOCK => '_stopped: with_lock installs no stop handler on Windows' },
);

{
  no strict 'refs';
  no warnings qw( redefine prototype );
  for my $name (@lacking) {
    *{"POSIX::$name"} = sub () { die sprintf "Your vendor has not defined POSIX macro %s, used at %s line %d\n", $name, ( caller(0) )[ 1, 2 ] };
  }
}
# Looked up at run time: this file's own POSIX::SIGHUP() was inlined as it was compiled.
ok( !eval { POSIX->can('SIGHUP')->(); 1 } && $@ =~ /\AYour vendor has not defined POSIX macro SIGHUP, used at /,
  'POSIX::SIGHUP() dies as on Windows' ) or diag $@;
is( eval { POSIX->can('SIGTERM')->() }, 15, 'POSIX::SIGTERM() keeps its number' );

my $dist = File::Spec->catdir( $FindBin::Bin, File::Spec->updir );
my @pm;
File::Find::find( { no_chdir => 1, wanted => sub { push @pm, $_ if /\.pm\z/ && -f $_ } }, File::Spec->catdir( $dist, 'lib' ) );
my @modules = sort map { File::Spec->abs2rel( $_, File::Spec->catdir( $dist, 'lib' ) ) =~ s{\\}{/}gr } @pm;
cmp_ok( scalar @modules, '>', 50, 'lib/ has the modules' );

subtest 'every module of lib/ loads' => sub {
  for my $file (@modules) {
    ( my $module = $file ) =~ s{\.pm\z}{};
    $module =~ s{/}{::}g;
    ok( eval { require $file; 1 }, "$module loads" ) or diag $@;
  }
};

subtest 'lib/ and script/ name no POSIX signal macro Windows lacks' => sub {
  my %lacking = map { $_ => 1 } @lacking;
  opendir( my $dh, File::Spec->catdir( $dist, 'script' ) ) or die "script/: $!";
  my @files = ( ( map { "lib/$_" } @modules ), map { "script/$_" } sort grep { !/\A\./ } readdir $dh );
  closedir $dh;
  my @hits;
  for my $file (@files) {
    open( my $fh, '<', File::Spec->catfile( $dist, $file ) ) or die "$file: $!";
    my $pod = 0;
    while ( my $line = <$fh> ) {
      last if $line =~ /\A__(?:END|DATA)__\b/;
      if ( $line =~ /\A=(\w+)/ ) { $pod = $1 ne 'cut'; next }
      next if $pod;
      $line =~ s/(?:\A|(?<=\s))#.*//s;    # a comment
      my @found = grep { $lacking{$_} } $line =~ /\bPOSIX::(\w+)/g;
      if ( $line =~ /\buse\s+POSIX\b(.*)/ ) {    # an import: none, or none of them
        my $list = $1;
        push @found,
            $list =~ /\A\s*;/         ? 'use POSIX; (the default imports)'
          : $list =~ /:signal_h\b/    ? 'use POSIX :signal_h'
          :                             grep { $lacking{$_} } $list =~ /\b(\w+)/g;
      }
      push @hits, map { "$file line $.: $_" } grep { !$allowed{$file}{$_} } @found;
    }
    close $fh;
  }
  is_deeply( \@hits, [], 'none named (a number by name: POSIX->can("SIG$name"))' ) or diag join "\n", @hits;
};

done_testing;
