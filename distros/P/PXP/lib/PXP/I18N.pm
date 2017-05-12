package PXP::I18N;

use POSIX qw(locale_h);
use I18N::LangTags qw(super_languages locale2language_tag);
use PXP::Config;

sub getPropertyFile {
  my $id = shift;

  my $locale = setlocale(LC_ALL);
  my $lang = locale2language_tag($locale);
  # try to find a name that matches the locale

  foreach ($lang, super_languages($lang)) {
    next if not $_;
    my $file = $id . '_' . $_ . '.properties';
    return $file if (-e $file);
  }

  return $id . '.properties';
}

sub loadNLocalize {
  my $rscfh = shift;
  my $pptfh = shift;

  if (not $pptfh) {
    local $/;
    return <$rscfh>;
  }

  # load property file into hash
  my $properties = {};
  load($properties, $pptfh);
  %props = %{$properties->{_props}};
  # use Data::Dumper;
  # print "\%props = " . Dumper(\%props);

  my $file = undef;
  while (my $line = <$rscfh>) {
    $line =~ s/%([\w.]+)/$props{$1}/eg;
    $file .= $line;
  }
  return $file;
}

# taken verbatim from Data::Properties by Brian Moseley, bcm@maz.org
sub load {
  my ($self, $in) = @_;
  return undef unless $in;

  my ($key, $val, $is_continuation, $is_continued);
  local $_;
  while (defined($_ = <$in>)) {
    next if /^[#!]/;		# leading # or ! signifies comment
    next if /^\s+$/;		# all-whitespace

    chomp;

    if ($is_continuation) {
      # don't attempt to parse a key on a continuation line
      s/^\s*//;
      undef $key;
    } else {
      # regular line - parse out the key
      s/^\s*([^=\s]+)\s*[=\s]\s*//;
      $key = $1;
    }

    $is_continued = s/\\$// ? 1 : undef;
    $val = $_;

    if ($is_continuation) {
      # append the continuation value to the value of the
      # last key
      $self->{_props}->{$self->{_lastkey}} .= $val;
    } elsif ($key) {
      $self->{_props}->{$key} = $val;
    } else {
      warn "Malformed property line: $_\n";
    }

    if ($is_continued) {
      $is_continuation = 1;
      # allow for continuation lines being continued
      $self->{_lastkey} = $key if defined $key;
    } else {
      undef $is_continuation;
      undef $self->{_lastkey};
    }
  }

  return 1;
}

1;
