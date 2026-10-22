#!/usr/bin/env perl
use strict;
use warnings;
use Config;
use File::Spec;
use Getopt::Long qw(GetOptions);
use Digest::SHA qw(sha256_hex);
use JSON::PP;

# Text-only inventory: do not require Rex, load Rexfiles, or evaluate VERSION code.
# @INC coderef hooks are intentionally not invoked. Candidates are not a promise
# of what a dynamically modified runtime @INC will load.
my @extra;
my $help;
GetOptions('lib=s@' => \@extra, 'help' => \$help) or exit 2;
if ($help) {
    print "Usage: perl inspect_rex.pl [--lib trusted-module-directory ...]\n";
    print "Reports candidate module paths and literal VERSION text without loading Rex.\n";
    exit 0;
}
die "Unexpected positional arguments\n" if @ARGV;
my @dirs = (@extra, grep { !ref($_) && -d $_ } @INC);
my @modules = qw(Rex Rex::LibSSH Net::LibSSH Net::SSH2 Net::OpenSSH
                 Net::SFTP::Foreign Rex::GPU Rex::Rancher);
my @records;
for my $module (@modules) {
    my $rel = $module;
    $rel =~ s{::}{/}g;
    $rel .= '.pm';
    my ($path) = grep { -f $_ } map { File::Spec->catfile($_, $rel) } @dirs;
    my %record = (module => $module, found => JSON::PP::false);
    if (defined $path) {
        $record{found} = JSON::PP::true;
        $record{path} = File::Spec->rel2abs($path);
        if (open my $fh, '<:raw', $path) {
            my $size = -s $fh;
            if (defined($size) && $size > 2 * 1024 * 1024) {
                $record{error} = 'Module exceeds text-scan limit of 2 MiB';
            } else {
                local $/;
                my $source = <$fh>;
                $source = '' unless defined $source;
                $record{sha256} = sha256_hex($source);
                if ($source =~ /\$(?:[A-Za-z_]\w*::)*VERSION\s*=\s*['"]([^'"\r\n]+)['"]/) {
                    $record{version_literal} = $1;
                } else {
                    $record{version_literal} = undef;
                }
            }
            close $fh or $record{close_warning} = "$!";
        } else {
            $record{error} = "Cannot read candidate module: $!";
        }
    }
    push @records, \%record;
}
my $result = {
    schema_version => 1,
    mode => 'text-only; no Rex code loaded; literal version scan, not runtime verification',
    perl_executable => $^X,
    perl_version => "$^V",
    controller_os => $^O,
    architecture => $Config{archname},
    ignored_inc_hooks => scalar(grep { ref($_) } @INC),
    modules => \@records,
};
print JSON::PP->new->canonical->pretty->encode($result);
