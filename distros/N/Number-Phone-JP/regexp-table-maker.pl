#!/usr/bin/env perl

use strict;
use warnings;
use Encode;
use FindBin;
use LWP::Simple;
use Regexp::Assemble::Compressed;
use Spreadsheet::ParseExcel;
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
$TABLEDIR = "$FindBin::Bin/lib/Number/Phone/JP/Table";
$TESTDIR  = "$FindBin::Bin/t";

main();

sub main {
    my %task_map = (
        Class1   => +{ function => 'class' },
        Class2   => +{ skip => 1 },
        Pager    => +{
            function    => 'fixed_pref',
            prefix      => '020',
            test_suffix => '12345',
            filename    => '000124105.xls',
        },
        Q2       => +{
            function    => 'fixed_pref',
            prefix      => '0990',
            test_suffix => '123',
            filename    => '000124118.xls',
        },
        Upt      => +{ function    => 'upt' },
        United   => +{
            function    => 'fixed_pref',
            prefix      => '0570',
            test_suffix => '123',
            filename    => '000124113.xls',
        },
        Ipphone  => +{
            function    => 'fixed_pref',
            prefix      => '050',
            filename    => '000124106.xls',
        },
        Freedial => +{
            function    => 'fixed_pref',
            prefix      => [qw(0120 0800)],
            test_suffix => +{ '0120' => '123', '0800' => '1234' },
            filename    => [qw(000124112.xls 000124114.xls)],
        },
    );

    unless (-d $STOREDIR) {
        mkpath($STOREDIR) or die $!;
    }
    opendir my $dh, $TABLEDIR or die "$TABLEDIR: $!";
    for my $file (readdir $dh) {
        next unless $file =~ /^(\w+)\.pm$/;
        my $class = $1;
        no strict 'refs';
        if (my $param = $task_map{$class}) {
            next if $param->{skip};
            my $func = delete $param->{function};
            _warn("calling $func()");
            $func->($class, $param);
        }
        else {
            my $func = lc($class);
            unless (defined $::{$func}) {
                _warn("$func() is not defined. skipping");
                next;
            }
            _warn("calling $func()");
            $func->($class);
        }
    }
}

sub fixed_pref {
    my($class, $param) = @_;
    my $lc_class = lc($class);
    my $filename = "$TABLEDIR/$class.pm";
    my @files = ();
    if ($param->{filename}) {
        @files = ref($param->{filename}) eq 'ARRAY' ? 
            @{$param->{filename}} : ($param->{filename});
    }
    else {
        @files = ("$lc_class.xls");
    }
    my @prefixes = ref($param->{prefix}) eq 'ARRAY' ?
        @{$param->{prefix}} : ($param->{prefix});
    my %regexp_table =
        map { $_ => Regexp::Assemble::Compressed->new } @prefixes;
    my $prefix_re;
    if (@prefixes == 1) {
        $prefix_re = $prefixes[0];
    }
    else {
        my $re = Regexp::Assemble::Compressed->new;
        for my $prefix (@prefixes) {
            $re->add($prefix);
        }
        ($prefix_re = $re->re) =~ s/^\(\?(?:-xism|\^):/(?:/;
    }
    my @rows_list = ();
    my @cols_list = ();
    my @column_values_list = ();
    for my $file (@files) {
        _warn($file);
        $file = "$STOREDIR/$file";
        http_get_file($file) or die "HTTP failed";
        my($rows, $cols, $column_values) = parse_excel($file);
        push @rows_list, $rows;
        push @cols_list, $cols;
        push @column_values_list, $column_values;
    }
    open my $fh, '>', $filename or die "$filename: $!";
    print $fh table_class_header($class);

    my @ok = ();
    my @ng = ();

    my $re = Regexp::Assemble::Compressed->new;
    for my $i (0 .. $#rows_list) {
        my $rows = $rows_list[$i];
        my $cols = $cols_list[$i];
        my $column_values = $column_values_list[$i];
        for my $row (sort { $a <=> $b } keys %$rows) {
            for my $col (sort { $a <=> $b } keys %$cols) {
                my $number = sprintf '%s%s', $rows->{$row}, $cols->{$col};
                my $value = $column_values->{$row}{$col};
                my $orig_number = $number;
                $number =~ s/^($prefix_re)//;
                my $prefix = $1;
                my $test_suffix =
                    ref($param->{test_suffix}) eq 'HASH' ?
                        $param->{test_suffix}{$prefix} :
                            ($param->{test_suffix} || '1234');
                my $regexp_suffix = '\d{' . length($test_suffix) . '}';
                _warn($orig_number . ("x" x (length $test_suffix)));
                if (!defined $value || $value =~ /^(\s|-)*$/) {
                    push @ng, "$prefix ${number}${test_suffix}";
                    next;
                }
                else {
                    push @ok, "$prefix ${number}${test_suffix}";
                }
                my $re = $regexp_table{$prefix};
                $re->add($number . $regexp_suffix);
            }
        }
    }
    for my $prefix (@prefixes) {
        my $re = $regexp_table{$prefix};
        (my $regexp = $re->re) =~ s/^\(\?(?:-xism|\^):/(?:/;
        (my $table_prefix = $prefix) =~ s/^0//;
        printf $fh "    $table_prefix => '%s',\n", compress($regexp);
    }
    printf $fh table_class_footer();
    close $fh;

    make_test($lc_class, \@ok, \@ng);
}

sub mobile {
    my @files = (qw/000200622.xls 000124110.xls 000124111.xls/);
    my @prefixes = qw(070 080 090);
    my %regexp_table =
        map { $_ => Regexp::Assemble::Compressed->new } @prefixes;
    my $re = Regexp::Assemble::Compressed->new;
    for my $prefix (@prefixes) {
        $re->add($prefix);
    }
    (my $prefix_re = $re->re) =~ s/^\(\?(?:-xism|\^):/(?:/;
    my @rows_list = ();
    my @cols_list = ();
    my @column_values_list = ();
    for my $file (@files) {
        _warn($file);
        $file = "$STOREDIR/$file";
        http_get_file($file) or die "HTTP failed";
        my($rows, $cols, $column_values) = parse_excel($file);
        push @rows_list, $rows;
        push @cols_list, $cols;
        push @column_values_list, $column_values;
    }
    my $filename = "$TABLEDIR/Mobile.pm";
    open my $fh, '>', $filename or die "$filename: $!";
    print $fh table_class_header('Mobile');

    my @ok = ();
    my @ng = ();

    for my $i (0 .. $#rows_list) {
        my $rows = $rows_list[$i];
        my $cols = $cols_list[$i];
        my $column_values = $column_values_list[$i];
        for my $row (sort { $a <=> $b } keys %$rows) {
            for my $col (sort { $a <=> $b } keys %$cols) {
                my $number = sprintf '%s%s', $rows->{$row}, $cols->{$col};
                my $value = $column_values->{$row}{$col};
                my $orig_number = $number;
                $number =~ s/^($prefix_re)//;
                my $prefix = $1;
                my $test_suffix = '12345';
                my $regexp_suffix = '\d{' . length($test_suffix) . '}';
                _warn($orig_number . ("x" x (length $test_suffix)));
                if (!defined $value || $value =~ /^(\s|-)*$/) {
                    push @ng, "$prefix ${number}${test_suffix}";
                    next;
                }
                else {
                    push @ok, "$prefix ${number}${test_suffix}";
                }
                my $re = $regexp_table{$prefix};
                $re->add($number . $regexp_suffix);
            }
        }
    }
    for my $prefix (@prefixes) {
        my $re = $regexp_table{$prefix};
        (my $regexp = $re->re) =~ s/^\(\?(?:-xism|\^):/(?:/;
        (my $table_prefix = $prefix) =~ s/^0//;
        printf $fh "    $table_prefix => '%s',\n", compress($regexp);
    }
    printf $fh table_class_footer();
    close $fh;

    make_test('mobile', \@ok, \@ng);
    make_test('phs', \@ok, \@ng);
}

sub phs {
    my $filename = "$TABLEDIR/Phs.pm";
    open my $fh, '>', $filename or die "$filename: $!";
    print $fh inherit_class('Phs', 'Mobile');
    close $fh;
}

sub home {
    my $class = shift;
    my $lc_class = lc($class);
    my $filename = "$TABLEDIR/$class.pm";
    my %table = ();
    my @ok = ();
    my @ng = ();
    my $modified;

    no warnings 'uninitialized';
    for my $num (1 .. 9) {
        my $file = sprintf '00012407%d.xls', $num - 1;
        _warn($file);
        $file = "$STOREDIR/$file";
        http_get_file($file) or die "HTTP failed";
        $modified = 1;
        my $parser = Spreadsheet::ParseExcel->new;
        my $workbook = $parser->parse($file);
        my $sheet = ($workbook->worksheets)[0];
        my @row_range = $sheet->row_range;
        for my $row ($row_range[0] .. $row_range[1]) {
            my $cell = $sheet->get_cell($row, 3);
            next unless defined $cell;
            my $pref = $cell->value;
            next unless defined $pref && $pref =~ s/^0//;
            my $local_pref = $sheet->get_cell($row, 4)->value;
            my $status = encode('utf-8', $sheet->get_cell($row, 6)->value);
            unless ($status =~ /(?:使用中|使用予定)/) {
                push @ng, sprintf '0%s %s1234', $pref, $local_pref;
                next;
            }
            push @ok, sprintf '0%s %s1234', $pref, $local_pref;
            unless (exists $table{$pref}) {
                $table{$pref} = Regexp::Assemble::Compressed->new;
            }
            $table{$pref}->add("$local_pref\\d{4}");
            _warn(sprintf "%s-%s: %s", $pref, $local_pref, $status);
        }
    }
    return unless $modified;

    open my $fh, '>', $filename or die "$filename: $!";
    print $fh table_class_header($class);
    for my $pref (sort { $a cmp $b } keys %table) {
        (my $re = $table{$pref}->re) =~ s/^\(\?(?:-xism|\^):/(?:/;
        printf $fh "    %-4d => '%s',\n", $pref, compress($re);
    }
    print $fh table_class_footer();
    close $fh;

    make_test($lc_class, \@ok, \@ng);
}

sub class {
    my $file = '000124104.xls';
    _warn($file);
    $file = "$STOREDIR/$file";
    http_get_file($file) or die "HTTP failed";

    my($rows, $cols, $column_values) = parse_excel($file);

    my @ok = ();
    my @ng = ();

    my @rows1 = ();
    my @rows2 = ();
    my $start_class2 = 0;
    for my $row (sort { $a <=> $b } keys %$rows) {
        if ($start_class2) {
            push @rows2, $row;
        }
        else {
            if ($rows->{$row} !~ /^\d+$/) {
                $start_class2 = 1;
                next;
            }
            push @rows1, $row;
        }
    }

    my $filename = "$TABLEDIR/Class1.pm";

    open my $fh, '>', $filename or die "$filename: $!";
    print $fh table_class_header('Class1');
    for my $row (@rows1) {
        for my $col (sort { $a <=> $b } keys %$cols) {
            next unless length $rows->{$row};
            # fixing illegal cell formats
            $rows->{$row} =~ s/^0+/00/ unless $rows->{$row} =~ /^00/;
            my $prefix = sprintf '%s%s', $rows->{$row}, $cols->{$col};
            _warn("${prefix}xxxxxxxx");
            my $value = $column_values->{$row}{$col};
            if ($value =~ /^(\s|-)*$/) {
                push @ng, "$prefix 12345678";
                next;
            }
            else {
                push @ok, "$prefix 12345678";
            }
            $prefix =~ s/^0//;
            printf $fh
                "    %-7s => '%s', # %s\n", "'" . $prefix . "'", '\d+', $value;
        }
    }
    print $fh table_class_footer();
    close $fh;

    make_test('class1', \@ok, \@ng);

    @ok = ();
    @ng = ();

    $filename = "$TABLEDIR/Class2.pm";

    open $fh, '>', $filename or die "$filename: $!";
    print $fh table_class_header('Class2');
    for my $row (@rows2) {
        for my $col (sort { $a <=> $b } keys %$cols) {
            next unless $rows->{$row};
            # fixing illegal cell formats
            $rows->{$row} =~ s/^0+/00/ unless $rows->{$row} =~ /^00/;
            my $prefix = sprintf '%s%s', $rows->{$row}, $cols->{$col};
            _warn("${prefix}xxxxxxxx");
            my $value = $column_values->{$row}{$col};
            if ($value =~ /^(\s|-)*$/) {
                push @ng, "$prefix 12345678";
                next;
            }
            else {
                push @ok, "$prefix 12345678";
            }
            $prefix =~ s/^0//;
            printf $fh
                "    %-8s => '%s', # %s\n", "'" . $prefix . "'", '\d+', $value;
        }
    }
    print $fh table_class_footer();
    close $fh;

    make_test('class2', \@ok, \@ng);
}

sub upt {
    my $filename = "$TABLEDIR/Upt.pm";
    open my $fh, '>', $filename or die "$filename: $!";
    print $fh inherit_class('Upt', 'Fmc');
    close $fh;
    make_test('upt', [], []);
}

sub parse_excel {
    my $file = shift;
    my $parser = Spreadsheet::ParseExcel->new;
    my $workbook = $parser->parse($file);
    my $sheet = ($workbook->worksheets)[0];
    my($row_from, $row_to) = $sheet->row_range;
    my($col_from, $col_to) = $sheet->col_range;
    my %rows = ();
    my %cols = ();
    my %column_values = ();
    my $start_reading = 0;
    for my $row ($row_from .. $row_to) {
        my $read_header = 0;
        for my $col ($col_from .. $col_to) {
            if ($col == 0) {
                my $cell = $sheet->get_cell($row, $col);
                my $value = $cell ? convert_value($cell->value) : '';
                if ($start_reading) {
                    next unless length $value;
                    $rows{$row} = $value =~ /^0/ ? $value : '0' . $value;
                }
                else {
                    if ($value eq '番号') {
                        $read_header   = 1;
                        $start_reading = 1;
                        next;
                    }
                }
                next;
            }
            last unless $start_reading;
            my $cell = $sheet->get_cell($row, $col);
            my $value = $cell ? convert_value($cell->value) : '';
            $column_values{$row}{$col} = $value;
            if ($read_header) {
                if ($value =~ /^\d$/) {
                    $cols{$col} = $value;
                }
                next;
            }
        }
    }
    return (\%rows, \%cols, \%column_values);
}

sub http_get_file {
    my $file = shift;
    my $uri = basename($file);
    #my($ext) = $uri =~ /\.([^\.]+)$/;
    my $url = sprintf 'http://www.soumu.go.jp/main_content/%s', $uri;
    _warn($url);
    my $res = LWP::Simple::mirror($url, $file);
    return 1 if $res == 200 || $res == 304;
    _warn("fail to get new file: $file ($res)");
    return;
}

sub compress { # makes regexp more compressed
    my $regexp = shift;
    $regexp =~ s{((?:\\d(?!\{)){2,})}{
        my $len = length($1) / 2;
        sprintf("\\d{%d}", $len);
    }eg;
    $regexp =~ s{((?:\\d)*)((?:\\d\{\d+\})+)((?:\\d(?!\{))*)}{
        my($prefix, $match_times, $postfix) = ($1, $2, $3);
        my $total = 0;
        my @times = $match_times =~ m{\\d\{(\d+)\}}g;
        $total += $_ for @times;
        $total += length($prefix)  / 2 if $prefix;
        $total += length($postfix) / 2 if $postfix;
        sprintf("\\d{%d}", $total);
    }eg;
    return $regexp;
}

sub convert_value {
    my $cell_value = shift;
    $cell_value =~ tr/\x{3000}\x{FF01}-\x{FF5E}/\x20\x21-\x7E/;
    $cell_value =~ tr/\x{201D}\x{2019}\x{FFE5}\x{2018}\x{301C}/"'\\`~/;
    $cell_value =~ tr/\x{2010}-\x{2015}\x{2212}/\-\-\-\-\-\-\-/;
    return encode('utf-8', $cell_value);
}

sub table_class_header {
    my $name = shift;
    my $desc_pref   = $name eq 'Home' ? 'Area-Pref'        : 'Pref';
    my $desc_regexp = $name eq 'Home' ? 'Local-Pref-Regex' : 'Assoc-Pref-Regex';
    return sprintf <<'END', $name, $VERSION, $UPDATED, $desc_pref, $desc_regexp;
package Number::Phone::JP::Table::%s;

use strict;
use warnings;

our $VERSION = '%s';

# Table last modified: %s
our %%TEL_TABLE = (
    # %s => q<%s>,
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

sub inherit_class {
    my($name, $parent) = @_;
    return sprintf <<'END', $name, $parent, $VERSION, $parent;
package Number::Phone::JP::Table::%s;

use strict;
use warnings;
require Number::Phone::JP::Table::%s;

our $VERSION = '%s';

no warnings 'once';
our %%TEL_TABLE = %%Number::Phone::JP::Table::%s::TEL_TABLE;

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
    print $t "use_ok('Number::Phone::JP', '$name');\n\n";
    print $t "my \$tel = Number::Phone::JP->new;\n";
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
    return sprintf "ok(\$tel->set_number('%s')->is_valid_number, " .
                   "'checking for %s');\n", $ok, $ok;
}

sub test_ng {
    my $ng = shift;
    return sprintf "ok(!\$tel->set_number('%s')->is_valid_number, " .
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

