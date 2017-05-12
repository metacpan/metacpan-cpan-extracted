#!/usr/bin/env perl

use strict;
use warnings;
use Encode;
use FindBin;
use LWP::Simple;
use Regexp::Assemble::Compressed;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use Text::CSV_XS;
use File::Basename;
use File::Path;
use Getopt::Long;

our $DEBUG;
our $UPDATED;
our $VERSION;
our $STOREDIR;
our $TABLEDIR;
our $TESTDIR ;

GetOptions(
    'date=s' => sub { updated_on(\$UPDATED, @_) },
    verbose  => \$DEBUG,
) or die <DATA>;

$DEBUG    = defined $ENV{DEBUG} ? $ENV{DEBUG} : $DEBUG;
$UPDATED  = defined $UPDATED ? $UPDATED : today();
$VERSION  = "0." . do { (my $ymd = $UPDATED) =~ s/-//g; $ymd };
$STOREDIR = "$FindBin::Bin/share";
$TABLEDIR = "$FindBin::Bin/lib/Number/ZipCode/JP/Table";
$TESTDIR  = "$FindBin::Bin/t";

main();

sub main {
    unless (-d $STOREDIR) {
        mkpath($STOREDIR) or die $!;
    }
    opendir my $dh, $TABLEDIR or die "$TABLEDIR: $!";
    for my $file (readdir $dh) {
        next unless $file =~ /^(\w+)\.pm$/;
        my $class = $1;
        no strict 'refs';
        my $func = lc($class);
        _warn("calling $func()");
        $func->($class);
    }
}

sub make_table {
    my($class, $zip_uri, $zip_pos, $desc_pos, $exp_pos, $exp_val) = @_;
    my $lc_class = lc($class);
    my $filename = "$TABLEDIR/$class.pm";
    my %table = ();
    my @ok = ();
    my @ng = ();

    unless (ref($desc_pos) eq 'ARRAY') {
        $desc_pos = [$desc_pos];
    }

    my $stored = http_get_and_unzip($zip_uri);

    open my $fh, '<:encoding(shiftjis)', $stored or die "$stored: $!";
    my $csv = Text::CSV_XS->new ({ binary => 1 });

    my $last_pref;
    my $last_suff;

    my @all_rows = ();
    while (my $row = $csv->getline($fh)) {
        push @all_rows, $row;
    }
    @all_rows = sort { $a->[$zip_pos] <=> $b->[$zip_pos] } @all_rows;

    for my $row (@all_rows) {
        my $zip = $row->[$zip_pos];
        if ($row->[$exp_pos] == $exp_val) { # expired
            push @ng, $zip;
            next;
        }
        if (my($pref, $suff) = split_zipcode($zip)) {
            $last_pref ||= $pref;
            if ($pref != $last_pref) {
                push @ng, $last_pref . sprintf('%04d', $last_suff + 1);
                $last_pref = $pref;
            }
            $last_suff = $suff;
            my $description = join '', @{$row}[@$desc_pos];
            $description = convert_value($description);
            push @ok, [$zip, $description];
            unless (exists $table{$pref}) {
                $table{$pref} = Regexp::Assemble::Compressed->new;
            }
            $table{$pref}->add($suff);
            _warn(sprintf "%s: %s", $zip, $description);
        }
        else {
            die "malformed zipcode: $zip";
        }
    }
    $csv->eof;
    close $fh;
    open my $pm, '>', $filename or die $!;
    print $pm table_class_header($class);
    for my $pref (sort { $a cmp $b } keys %table) {
        my $re = compress($table{$pref}->re);
        printf $pm "    '%s' => '%s',\n", $pref, $re;
    }
    print $pm table_class_footer();
    close $pm;
    close $pm;
    make_test($lc_class, \@ok, \@ng);
}

sub split_zipcode {
    my $zipcode = shift;
    return $zipcode =~ /^(\d{3})(\d{4})$/;
}

sub area {
    my $class = shift;
    make_table($class, 'kogaki/zip/ken_all.zip', 2, [qw(6 7 8)], 14, 6);
}

sub company {
    my $class = shift;
    make_table($class, 'jigyosyo/zip/jigyosyo.zip', 7, 2, 12, 5);
}

sub http_get_and_unzip {
    my $file = shift;
    my $basename = basename($file);
    my $stored_zip = "$STOREDIR/$basename";
    (my $uncompressed = $stored_zip) =~ s/\.zip$/\.csv/i;
    my $url = sprintf 'http://www.post.japanpost.jp/zipcode/dl/%s', $file;
    _warn($url);
    my $res = LWP::Simple::mirror($url, $stored_zip);
    unless ($res == 200 || $res == 304) {
        _warn("fail to get new file: $basename ($res)");
        return;
    }
    unzip $stored_zip => $uncompressed or die "unzip failed: $UnzipError";
    return $uncompressed;
}

sub convert_value {
    my $cell_value = shift;
    $cell_value =~ tr/\x{3000}\x{FF01}-\x{FF5E}/\x20\x21-\x7E/;
    $cell_value =~ tr/\x{201D}\x{2019}\x{FFE5}\x{2018}\x{301C}/"'\\`~/;
    $cell_value =~ tr/\x{2010}-\x{2015}\x{2212}/\-\-\-\-\-\-\-/;
    $cell_value =~ s/'/\\'/g;
    return encode('utf-8', $cell_value);
}

sub compress { # makes regexp more compressed
    my $regexp = shift;
    $regexp =~ s/^\(\?(?:-xism|\^):/(?:/;
    $regexp =~ s&\(\?:([^\(\)]+)\)&
        my $re = $1;
        my @re = ();
        my %suffixes = ();
        my @parts = split /\|/, $re;
        for my $part (@parts) {
            unless ($part =~ m{^(\d)(\[[-\d]+\]|\\d)$}) {
                push @re, $part;
                next;
            }
            my($pref, $suff) = ($1, $2);
            $suffixes{$suff} ||= [];
            push @{$suffixes{$suff}}, $pref;
        }
        for my $suff (keys %suffixes) {
            if (@{$suffixes{$suff}} == 1) {
                push @re, $suffixes{$suff}->[0] . $suff;
                next;
            }
            my $rac = Regexp::Assemble::Compressed->new;
            for my $pref (sort @{$suffixes{$suff}}) {
                $rac->add($pref);
            }
            (my $pref_class = $rac->re) =~ s/^\(\?(?:-xism|\^):(.*?)\)/$1/;
            push @re, $pref_class . $suff;
        }
        '(?:' . join('|', @re) . ')';
    &eg;
    return $regexp;
}

sub table_class_header {
    my $name = shift;
    return sprintf <<'END', $name, $VERSION, $UPDATED;
package Number::ZipCode::JP::Table::%s;

use strict;
use warnings;

our $VERSION = '%s';

# Table last modified: %s
our %%ZIP_TABLE = (
END
    ;
}

sub table_class_footer {
    return <<'END';
);

1;
__END__
END
    ;
}

sub make_test {
    my($name, $ok, $ng) = @_;
    my $testfile = "$TESTDIR/$name.t";
    open my $t, '>', $testfile or die "$testfile: $!";
    print $t "use strict;\n";
    printf $t
        "use Test::More tests => %d;\n\n", scalar(@$ok) + scalar(@$ng) + 1;
    print $t "use_ok('Number::ZipCode::JP', '$name');\n\n";
    print $t "my \$zip = Number::ZipCode::JP->new;\n";
    for my $test (@$ok) {
        printf $t test_ok($test);
    }
    for my $test (@$ng) {
        printf $t test_ng($test);
    }
    close $t;
}

sub test_ok {
    my $ok = shift;
    return sprintf "ok(\$zip->set_number('%s')->is_valid_number, " .
                   "'%s');\n", $ok->[0], $ok->[1];
}

sub test_ng {
    my $ng = shift;
    return sprintf "ok(!\$zip->set_number('%s')->is_valid_number, " .
                   "'checking for %s');\n", $ng, $ng;
}

sub today {
    my $self = shift;
    my @lt = localtime();
    return sprintf '%d-%02d-%02d', $lt[5] + 1900, $lt[4] + 1, $lt[3];
}

sub _warn {
    return unless $DEBUG;
    warn(map { "$_\n" } @_);
}

sub updated_on {
    my($ref, $name, $value) = @_;
    unless ($value =~ /^\d{4}-\d\d-\d\d$/) {
        die qq{$name option is assumed to have the format "YYYY-MM-DD"\n};
    }
    $$ref = $value;
}

__DATA__
Usage: regexp-table-maker.pl [OPTION]...

options:
  -d, --date=YYYY-MM-DD    specifies the date of updated the tables.
                           it'll be used for $VERSION of each classes.

  -v, --verbose            verbose mode.
                           causes to print debugging messages about its
                           progress.
                           you can also turn on the feature using DEBUG
                           environment variable.

