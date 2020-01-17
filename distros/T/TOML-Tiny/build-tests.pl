#-------------------------------------------------------------------------------
# Generates perl unit tests from the toml/json files in BurntSush/toml-test
# without having to add special casing to TOML::Tiny to conform to their
# annotated JSON format.
#-------------------------------------------------------------------------------
use strict;
use warnings;
no warnings 'experimental';
use v5.18;

use Data::Dumper;
use JSON::PP;

# We want to read unicde as characters from toml-test source files. That makes
# things simpler for us when we parse them and generate perl source in the
# generated test file.
binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

sub slurp{
  open my $fh, '<', $_[0] or die $!;
  local $/;
  <$fh>;
}

# Removes type annotations from BurntSushi/toml-test JSON files and returns the
# cleaned up data structure to which the associated TOML file should be parsed.
sub deturd_json{
  state $json = JSON::PP->new->utf8(1);
  my $annotated = $json->decode(slurp(shift));
  my $cleanish = deannotate($annotated);

  local $Data::Dumper::Varname = 'expected';
  local $Data::Dumper::Deparse = 1;
  return Dumper($cleanish);
}

# Recursively deannotates and inflates values from toml-test JSON data
# structures into a format more in line with TOML::Tiny's parser outout. For
# integer and float values, a Test2::Tools::Compare validator is generated to
# compare using Math::Big(Int|Float)->beq, since TOML's float and int types are
# 64 bits. Datetimes are converted to a common, normalized string format.
sub deannotate{
  my $data = shift;

  for (ref $data) {
    when ('HASH') {
      if (exists $data->{type} && exists $data->{value} && keys(%$data) == 2) {
        for ($data->{type}) {
          return $data->{value} eq 'true' ? 1 : 0             when /bool/;
          return [ map{ deannotate($_) } @{$data->{value}} ]  when /array/;

          when (/datetime/) {
            my $src = qq{
              use Test2::Tools::Compare qw(validator);
              validator(sub{
                use DateTime;
                use DateTime::Format::RFC3339;
                my \$exp = DateTime::Format::RFC3339->parse_datetime("$data->{value}");
                my \$got = DateTime::Format::RFC3339->parse_datetime(\$_);
                \$exp->set_time_zone('UTC');
                \$got->set_time_zone('UTC');
                return DateTime->compare(\$got, \$exp) == 0;
              });
            };

            my $result = eval $src;
            $@ && die $@;

            return $result;
          }

          when (/integer/) {
            my $src = qq{
              use Test2::Tools::Compare qw(validator);
              validator(sub{
                require Math::BigInt;
                Math::BigInt->new("$data->{value}")->beq(\$_);
              });
            };

            my $result = eval $src;
            $@ && die $@;

            return $result;
          }

          when (/float/) {
            my $src = qq{
              use Test2::Tools::Compare qw(validator);
              validator(sub{
                require Math::BigFloat;
                Math::BigFloat->new("$data->{value}")->beq(\$_);
              });
            };

            my $result = eval $src;
            $@ && die $@;

            return $result;
          }

          default{ return $data->{value} }
        }
      }

      my %object;
      $object{$_} = deannotate($data->{$_}) for keys %$data;
      return \%object;
    }

    when ('ARRAY') {
      return [ map{ deannotate($_) } @$data ];
    }

    default{
      return $data;
    }
  }
}

sub build_pospath_test_files{
  my $src  = shift;
  my $dest = shift;

  $src = "$src/tests/valid";
  $dest = "$dest/t/toml-test/valid";

  print "Generating positive path tests from $src\n";

  unless (-d $dest) {
    system('mkdir', '-p', $dest) == 0 || die $?;
  }

  my %TOML;
  my %JSON;

  opendir my $dh, $src or die $!;

  while (my $file = readdir $dh) {
    my $path = "$src/$file";
    my ($test, $ext) = $file =~ /^(.*)\.([^\.]+)$/;

    for ($ext) {
      next unless defined;
      $TOML{$test} = $path when /toml/;
      $JSON{$test} = $path when /json/;
    }
  }

  closedir $dh;

  for (sort keys %TOML) {
    my $data = deturd_json($JSON{$_});

    my $toml = slurp($TOML{$_});
    $toml =~ s/\\/\\\\/g;

    open my $fh, '>', "$dest/$_.t" or die $!;

    print $fh qq{# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $data

my \$actual = from_toml(q{$toml});

is(\$actual, \$expected1, '$_ - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper(\$expected1);

  diag 'ACTUAL:';
  diag Dumper(\$actual);
};

is(eval{ from_toml(to_toml(\$actual)) }, \$actual, '$_ - to_toml') or do{
  diag 'INPUT:';
  diag Dumper(\$actual);

  diag 'TOML OUTPUT:';
  diag to_toml(\$actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml(\$actual)));
};

done_testing;};

    close $fh;
  }
}

sub build_negpath_test_files{
  my $src  = shift;
  my $dest = shift;

  $src = "$src/tests/invalid";
  $dest = "$dest/t/toml-test/invalid";

  print "Generating negative path tests from $src\n";

  unless (-d $dest) {
    system('mkdir', '-p', $dest) == 0 || die $?;
  }

  my %TOML;

  opendir my $dh, $src or die $!;

  while (my $file = readdir $dh) {
    my $path = "$src/$file";
    my ($test, $ext) = $file =~ /^(.*)\.([^\.]+)$/;

    if ($ext && $ext eq 'toml') {
      $TOML{$test} = $path;
    }
  }

  closedir $dh;

  for (sort keys %TOML) {
    my $toml = slurp($TOML{$_});
    $toml =~ s/\\/\\\\/g;

    open my $fh, '>', "$dest/$_.t" or die $!;

    print $fh qq{# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

ok dies(sub{
  from_toml(q{
$toml
  }, strict_arrays => 1);
}), 'strict_mode dies on $_';

done_testing;};

    close $fh;
  }
}

my $usage = "usage: build-tests \$toml-test-repo-path \$toml-tiny-repo-path\n";
my $toml_test_path = shift @ARGV || die $usage;
my $toml_tiny_path = shift @ARGV || die $usage;

-d $toml_test_path          || die "invalid path to BurntSush/toml-test: $toml_test_path\n";
-d "$toml_test_path/tests"  || die "invalid path to BurntSush/toml-test: $toml_test_path\n";
-d $toml_tiny_path          || die "invalid path to TOML::Tiny repo: $toml_tiny_path\n";
-d "$toml_tiny_path/t"      || die "invalid path to TOML::Tiny repo: $toml_tiny_path\n";

build_pospath_test_files($toml_test_path, $toml_tiny_path);
build_negpath_test_files($toml_test_path, $toml_tiny_path);
