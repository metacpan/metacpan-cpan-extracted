#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple qw(mirror);
use RDF::NS;
use File::Temp;
use Text::Wrap;
$Text::Wrap::unexpand = 0;    # don't insert tabs

my $source = $ARGV[0] || do {
    print "Usage: $0 http://prefix.cc/popular/all.file.txt  # from url\n";
    print "Usage: $0 all.txt                                #  from file\n";
    exit;
};

# make sure, git repository is clean
my $dirty = `git status --porcelain`;
die "git repository is dirty\n" if $dirty;

# get current version distribution
my $dist        = do { local ( @ARGV, $/ ) = 'lib/RDF/NS.pm'; <> };
my $cur_version = $1 if $dist =~ /^our \$VERSION\s*=\s*'([^']+)'/m;
$cur_version or die 'current version not found in lib/RDF/NS.pm';

# get current prefixes
my $cur = RDF::NS->LOAD( "share/prefix.cc", warn => 1 );
die "share/prefix.cc is empty" unless %$cur;

# get new current datestamp
my @t           = gmtime;
my $new_version = sprintf '%4d%02d%02d',    $t[5] + 1900, $t[4] + 1, $t[3];
my $new_date    = sprintf '%4d-%02d%-%02d', $t[5] + 1900, $t[4] + 1, $t[3];
die "$new_version is not new" if $new_version eq $cur_version;

if ( $source =~ /^https?:/ ) {
    my $url = $source;
    $source = File::Temp->new->filename;
    mirror( $url, $source ) or die "Failed to load $url";
}
my $new = RDF::NS->LOAD( $source, warn => 1 );

# lock all prefixes pointing to example.* TLD URLs
for ( grep { $new->{$_} =~ qr{^https?://example.\w} } keys %$new ) {
    delete $new->{$_} if $new->{$_} ne $cur->{$_};
}

my $diff = $new->UPDATE( "share/prefix.cc", $new_version );

foreach my $change (qw(create delete update)) {
    my $prefixes = $diff->{$change} or next;
    foreach my $prefix (@$prefixes) {
        if ( $change eq 'create' ) {
            printf "+ $prefix %s\n", $new->URI($prefix);
        }
        elsif ( $change eq 'delete' ) {
            printf "- $prefix %s\n", $cur->URI($prefix);
        }
        else {
            printf "- $prefix %s\n", $cur->URI($prefix);
            printf "+ $prefix %s\n", $new->URI($prefix);
        }
    }
}

my (@log) = ( '{{$NEXT}}', ' - ' . $new->COUNT . " prefixes" );

sub prefix_list {
    my ( $label, $list ) = @_;
    return wrap( " - $label ", " " x 12, join ' ', @$list );
}

push @log, prefix_list( "added:  ", $diff->{create} ) if @{ $diff->{create} };
push @log, prefix_list( "removed:", $diff->{delete} ) if @{ $diff->{delete} };
push @log, prefix_list( "changed:", $diff->{update} ) if @{ $diff->{update} };

my @files = qw(
  lib/App/rdfns.pm
  lib/RDF/NS.pm
  lib/RDF/NS/Trine.pm
  lib/RDF/NS/URIS.pm
  lib/RDF/SN.pm
  README.md
);

foreach my $file (@files) {
    print "$cur_version => $new_version in $file\n";
    local ( $^I, @ARGV ) = ( '.bak', $file );
    while (<>) {
        s/$cur_version/$new_version/ig;
        print;
    }
}

my $msg = `git log --pretty=format:" - %s" $cur_version..`;

do {
    print "prepend modifications to Changes\n";
    local ( $^I, @ARGV ) = ( '.bak', 'Changes' );
    my $line = 0;
    while (<>) {
        if ( !$line++ ) {    # prepend
            print join '', map { "$_\n" } @log;
            print "\n$msg" if $msg;
            print "\n\n";
        }
        print;
    }
};

print `git add -u`;
print `git commit -m "update to $new_version"`;

1;
