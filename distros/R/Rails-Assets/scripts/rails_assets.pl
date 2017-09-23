#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

my $VERBOSE = $ENV{VERBOSE} // 0;
my $OUTPUT = $ENV{OUTPUT} // 0;

use Rails::Assets;
use Rails::Assets::Base qw(prepare_extensions_refs);
use Rails::Assets::Output;

if ($OUTPUT) {
  use YAML::Dumper;
}

my $rails_root = shift // '.';
say "Processing $rails_root..." if $VERBOSE;
chdir $rails_root or die "Channot chdir to $rails_root: $!";

my $assets = Rails::Assets->new();
$assets->analyse();

tell_output($assets) if ($VERBOSE);

my $output = prepare_extensions_refs($assets->assets_ext());
foreach my $key (sort keys %{$assets->assets_hash()}) {
  foreach my $elem (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->assets_hash()->{$key}}){
    $elem->{referrals} = [()];
    push  @{$elem->{referrals}}, $_->{full_path} foreach (
      grep {
        my $check = $_->{name};
        $check =~ s/#\{.*\}/\.\*/;
        $elem->{name} =~ m/$check/;
      } @{$assets->template_hash()->{$key}}
    );
    push  @{$elem->{referrals}}, $_->{referral} foreach (grep { $elem->{name} =~ $_->{name} } @{$assets->scss_hash()->{$key}});
    $elem->{refs_count} = scalar @{$elem->{referrals}};
    push @{$output->{$key}}, $elem;
  };
}

my $assets_status = {
  used => [()],
  unused => [()],
  dubious => [()],
};

foreach my $key (sort keys %{$assets->assets_hash()}) {
  push @{$assets_status->{used}}, $_ foreach (grep { $_->{refs_count} > 0 } @{$assets->assets_hash()->{$key}});
  push @{$assets_status->{unused}}, $_ foreach (grep { $_->{refs_count} == 0 } @{$assets->assets_hash()->{$key}});
}

foreach my $key (sort keys %{$assets->template_hash()}) {
  my @assets_paths_by_type = map {$_->{name}} @{$assets->assets_hash()->{$key}};
  my $referrals = [uniq( flatten(map {$_->{referrals}} @{$assets->assets_hash()->{$key}}) )];
  my %referred = map {($_, 1)} @$referrals;
  foreach my $elem (grep { !$referred{$_->{name}} } @{$assets->template_hash()->{$key}}) {
    my $check = $elem->{name};
    $check =~ s/#\{.*\}/\.\*/;
    my @matched = grep { $_ =~ /$check/ } @assets_paths_by_type;
    push @{$assets_status->{dubious}}, $elem unless scalar @matched;
  }
}

if ($OUTPUT){
  my $dumper = YAML::Dumper->new();
  open OUT, '>assets_status.yml';
  print OUT $dumper->dump($assets_status);
  close OUT;
}

sub uniq {
  my %seen;
  grep { !$seen{$_}++ } @_;
}
sub flatten {
  return sort map {@$_} @_;
}
