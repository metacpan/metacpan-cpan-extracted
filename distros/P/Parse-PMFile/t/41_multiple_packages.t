use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

my $pmfile = "$tmpdir/Test.pm";
my @package = (qw/Parse PMFile Test/);
my @subpackages = (qw/Location Blah Thing/);

my $parser = Parse::PMFile->new;
subtest 'arisdottle' => sub {
  _generate_package(q{::});
  my $info = $parser->parse($pmfile);
  _check_packages($info);
};

subtest 'quote' => sub {
  _generate_package(q{'});
  my $info = $parser->parse($pmfile);
  _check_packages($info);
};

done_testing;

sub _generate_package {
  my ($sep) = @_;
  my $version = 1;

  open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
  print $fh 'package ' . join($sep, @package) . ";\n";
  print $fh q{our $VERSION = '1.0} . $version++ . "';\n1;\n";
  for my $subpackage (@subpackages) {
    print $fh 'package ' . join($sep, @package, $subpackage) . ";\n";
    print $fh q{our $VERSION = '1.0} . $version++ . "';\n1;\n";
  }
  close $fh;
}

sub _check_packages {
	my ($info) = @_;

	my $package = join(q{::}, @package);
	ok exists $info->{$package}, q{found base package};

	for my $subpackage (@subpackages) {
		ok exists $info->{$package . q{::} . $subpackage}, qq{found sub package $subpackage};
	}
}
