package Setup::Project::Functions;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT = qw/
    sharedir
    scriptdir
    equal_style
    flavor_info
    date
/;

use File::Spec::Functions ();
use File::ShareDir ();
use Carp ();
use File::Basename ();
use Time::Piece;

sub date {
    sprintf "%s", (localtime)->datetime;
}

sub flavor_info {
    my $pkg = caller(0);
    my $version = eval { $pkg->version };
    $version ||= '';
    sprintf "%s@%s", $pkg, $version;
}

sub sharedir {
    my ($package, @dir) = @_;
    $package =~ s|::|-|;
    File::Spec::Functions::catfile(File::ShareDir::dist_dir($package), @dir);
}

sub scriptdir {
    my (@dir) = @_;
    File::Spec::Functions::catfile(File::Basename::dirname(File::Spec::Functions::rel2abs($0)), @dir);
}

# name=1 author=hixi
sub equal_style {
    my $argv = shift;
    my %hash;
    for my $var (@$argv) {
        my ($key, $value) = map { trim($_) } split /=/, $var;
        die "deplicated key: $key" if defined $hash{$key};
        $hash{$key} = $value;
    }
    return %hash;
}

sub trim {
    s/^\s*(.*?)\s*$/$1/;
    $_;
}

1;
