#!perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec::Functions qw/catfile/;
use Template::Flute;
use Data::Dumper;

my @testfiles = (qw/admin
                    checkout-giftinfo
                    checkout-payment
                    product
                    registration
                   /);

plan tests => scalar(@testfiles) * 4;

foreach my $file (@testfiles) {
    my $flute = Template::Flute->new(
                                     template_file => get_good_template($file),
                                     specification_file => get_good_spec($file),
                                    );
    ok($flute->process, "HTML produced");
    my @errors = $flute->specification->dangling;
    is_deeply(\@errors, [], "No errors found");
    $flute = Template::Flute->new(
                                  template_file => get_bad_template($file),
                                  specification_file => get_bad_spec($file),
                                 );
    ok($flute->process, "HTML produced");
    @errors = $flute->specification->dangling;
    # diag Dumper(\@errors);
    ok(@errors, "Consistency check fails");
}

sub get_good_template {
    my $f = shift;
    return getfile($f, 'good', '.html');
}

sub get_good_spec {
    my $f = shift;
    return getfile($f, 'good', '.xml');
}

sub get_bad_template {
    my $f = shift;
    return getfile($f, 'bad', '.html');
}

sub get_bad_spec {
    my $f = shift;
    return getfile($f, 'bad', '.xml');
}

sub getfile {
    my ($f, $dir, $ext) = @_;
    my $file = catfile(t => testfiles => $dir, $f . $ext);
    die "$file not found!" unless (-f $file);
    return $file;
}
