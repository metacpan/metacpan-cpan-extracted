#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin;
use HTTP::Tiny;
use JSON::PP;
use Archive::Tar;
use version;
use Getopt::Long;
use File::Path;

GetOptions(blead => \my $blead);

# XXX: 5.8.8 and 5.8.9 also have debug_tokens.
my $min_version = version->parse('5.010000');

my $api_url = "https://fastapi.metacpan.org/v1/release/_search?q=distribution:perl&fields=download_url,date&size=500&sort=date:desc";

my $ua = HTTP::Tiny->new;

my @perls;
{
    my %seen;
    my $res = $ua->get($api_url);
    die "Can't get perl versions: ".encode_json($res) unless $res->{success};
    @perls =
        map {+{version => $_->[0], url => $_->[2], canon_version => $_->[3]}}
        grep {not ($seen{$_->[1]}++)}
        sort {$a->[1] <=> $b->[1] || $a->[0] cmp $b->[0]}
        grep {defined $_ && $_->[1] >= $min_version}
        map {
            my $url = $_->{fields}{download_url};
            $url =~ s/\.bz2$/\.gz/;
            my $ret;
            if (my ($version) = $url =~ /perl-(5\.\d+\.\d+(?:\-RC\d+)?)\.tar\.gz$/) {
                my $v = $version; $v =~ s/\-RC\d+$//;
                $ret = [$version, version->parse($v), $url, $v];
            }
            $ret;
        }
        @{ decode_json($res->{content})->{hits}{hits} || [] };
}

my $src_dir = "$FindBin::Bin/src";
my $dst_dir = "$FindBin::Bin/../lib/Perl/gen";

mkdir $src_dir unless -d $src_dir;
mkdir $dst_dir unless -d $dst_dir;

if ($blead) {
    my $blead_dir = "$src_dir/blead";
    rmtree($blead_dir) if -d $blead_dir;
    system('git', 'clone', 'https://github.com/perl/Perl5', '--depth', 1, $blead_dir);
    my ($version_line) = grep /^version=/, do { open my $fh, '<', "$blead_dir/Porting/config.sh" or die $!; <$fh> };
    my ($blead_version) = $version_line =~ /(5\.[0-9]+\.[0-9])/;
    push @perls, {version => 'blead', canon_version => $blead_version};
}

open my $map, '>', "$dst_dir/token_info_map.h";

my %seen;
my %prev;
for my $perl (@perls) {
    my $version = $perl->{version};
    my $canon_version = $perl->{canon_version};
    next if $seen{$version}++;
    say "processing $version...";
    if ($version ne 'blead') {
        my $file = "$src_dir/perl-$version.tar.gz";
        if (!-f $file) {
            say "downloading $version...";
            my $res = $ua->mirror($perl->{url}, $file);
            unless ($res->{success}) {
                warn "Can't download $version";
                next;
            }
        }
        my $tar = Archive::Tar->new($file, 1);

        for my $name (qw/perly.h toke.c/) {
            (my $vname = $name) =~ s/\./-$canon_version./;
            unlink "$src_dir/$vname" if -f "$src_dir/$vname";
            $tar->extract_file("perl-$version/$name", "$src_dir/$vname");
        }
    } else {
        for my $name (qw/perly.h toke.c/) {
            (my $vname = $name) =~ s/\./-$canon_version./;
            rename "$src_dir/blead/$name" => "$src_dir/$vname";
        }
    }

    my $perly = '';
    my %yytokentype;
    {
        my $src = "$src_dir/perly-$canon_version.h";
        my $dst = "$dst_dir/perly-$canon_version.h";
        open my $in, '<', $src or die $!;
        open my $out, '>', $dst;
        my $in_yytokentype;
        while(<$in>) {
            next if /PERL_CORE|PERL_IN_TOKE_C/;
            s!(YYEMPTY = -2,)!/* $1 */!;
            print $out $_;
            $perly .= $_;
            if (/enum yytokentype/) {
                $in_yytokentype = 1;
                next;
            }
            if ($in_yytokentype) {
                if (/\}/) {
                    $in_yytokentype = 0;
                    next;
                }
                if (/\s+([A-Z0-9_]+)\s*=\s*(\d+)/) {
                    my ($token, $value) = ($1, $2);
                    $yytokentype{$token} = $value;
                }
            }
        }
        $perly =~ s!/\* Generated from:.+? \*/!!s;
        close $in;
        close $out;
    }

    my $token_info = '';
    {
        my $src = "$src_dir/toke-$canon_version.c";
        my $dst = "$dst_dir/token_info-$canon_version.h";
        open my $in, '<', $src;
        open my $out, '>', $dst;
        say $out qq{#include "perly-$canon_version.h"};
        my $flag;
        while(<$in>) {
            if (/^(?:enum token_type|static struct debug_token)/) {
                $flag = 1;
            }
            if ($flag) {
                if (/\s*\{\s*([A-Z0-9_]+),/) {
                    my $token = $1;
                    $yytokentype{$token} = 0 if exists $yytokentype{$token};
                }
                if (/\s*\{\s*0,/) {
                    # add undeclared tokens
                    $token_info .= "    /* added by Perl::Lexer */\n";
                    for my $token (sort {$yytokentype{$a} <=> $yytokentype{$b}} grep {$yytokentype{$_}} keys %yytokentype) {
                        $token_info .= qq/    { $token, TOKENTYPE_OPNUM, "$token" },\n/;
                        # print "added $token to token_info\n";
                    }
                }
                if (/DEBUG_TOKEN\s*\((\w+),\s*(\w+)\)\s*,/) {
                    my ($type, $name) = ($1, $2);
                    $_ = qq/    { $name, TOKENTYPE_$type, "$name" },\n/;
                }
                $token_info .= $_;
                $flag = 0 if /^\s*$/;
            }
        }
        print $out $token_info;
    }

    my ($revision, $major, $minor) = split /\./, $canon_version;

    my $if = keys %seen > 1 ? "elif" : "if";

    my $include_version = $canon_version;
    if ($prev{perly} && $prev{perly} eq $perly &&
        $prev{token_info} && $prev{token_info} eq $token_info &&
        $minor  # should always keep 5.x.0 for clarity
    ) {
        unlink "$dst_dir/perly-$canon_version.h";
        unlink "$dst_dir/token_info-$canon_version.h";
        $include_version = $prev{version};
    } else {
        # token_info for the stable perls should be the same
        # (fallback for maint releases)
        if ($major % 2 && !$minor) {
            print $map <<"MAP";
#$if PERL_VERSION == @{[$major - 1]}
#include "token_info-$prev{version}.h"
MAP
        }

        $prev{perly} = $perly;
        $prev{token_info} = $token_info;
        $prev{version} = $canon_version;
    }

    print $map <<"MAP";
#$if PERL_VERSION == $major && PERL_SUBVERSION == $minor
#include "token_info-$include_version.h"
MAP
}

# fallback to the latest (so that we don't always need to rush everytime a new version of perl is released)
if ($prev{perly} && $prev{token_info} && $prev{version}) {
    {
        open my $out, '>', "$dst_dir/perly-latest.h";
        print $out $prev{perly};
    }
    {
        open my $out, '>', "$dst_dir/token_info-latest.h";
        say $out qq{#include "perly-latest.h"};
        print $out $prev{token_info};
    }
    my ($revision, $major, $minor) = split /\./, $perls[-1]->{canon_version};
    print $map <<"MAP";
#elif PERL_VERSION > $major || (PERL_VERSION == $major && PERL_SUBVERSION > $minor)
#include "token_info-latest.h"
MAP
}

print $map <<"MAP";
#else
#error "No support for this perl version"
#endif
MAP
