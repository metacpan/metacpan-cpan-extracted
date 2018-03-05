# -*- perl -*-
# t/007-ls-distribution.t
use strict;
use warnings;

use Perl::Download::FTP::Distribution;
use Test::More;
unless ($ENV{PERL_ALLOW_NETWORK_TESTING}) {
    plan 'skip_all' => "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests";
}
else {
    plan tests => (7 * 3);
}
use Test::RequiresInternet ('ftp.cpan.org' => 21);

my ($self, $host, $dir);
my (@allreleases, $sample);
my $default_host = 'ftp.cpan.org';
my $default_dir  = 'pub/CPAN/modules/by-module';

# Because the distribution versions available on CPAN are going to change over
# time, we cannot hard-code distribution names into our test expectations.
# So we'll be content to print out results and eyeball for plausibility.

my $basic_args = {
    host            => $default_host,
    dir             => $default_dir,
};

$sample = 'Test-Smoke';
test_ls($basic_args, $sample);

$sample = 'Text-CSV_XS';
test_ls($basic_args, $sample);

$sample = 'List-Compare';
test_ls($basic_args, $sample);

$sample = 'Mojolicious-Plugin-MultiConfig';
test_ls($basic_args, $sample);

$sample = 'File-Rsync-Mirror-Recent';
test_ls($basic_args, $sample);

$sample = 'Lingua-LO-NLP';
test_ls($basic_args, $sample);

$sample = 'File-Download';
test_ls($basic_args, $sample);


sub test_ls {
    my ($basic_args, $sample) = @_;
    my $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        %{$basic_args},
        Passive         => 1,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    my @allreleases = $self->ls();
    ok(scalar(@allreleases), "ls(): returned >0 elements for $sample");
    print STDERR "  $_\n" for @allreleases;
}
