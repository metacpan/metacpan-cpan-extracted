use strict;
use warnings;
use vars qw( $SILENT );

use constant SEPTOR    => q{[AGENT]};
use constant RE_SEPTOR => qr{ \Q[AGENT]\E }xms;

use Carp qw( croak );
use File::Spec;
use File::Basename;
use IO::File;
use Test::More;
use File::Find qw( find  );

my $COMMENT = q{Parse::HTTP::UserAgent test file};
my @todo;

END {
    if ( @todo && ! $SILENT ) {
        diag( 'Tests marked as TODO are listed below' );
        diag("$_->[0]: '$_->[1]'") for @todo;
    }
}

sub database {
    my $opt = shift || {};
    my @buf;
    my $tests = merge_files();
    my $id    = 0;
    foreach my $test ( split RE_SEPTOR, $tests ) {
        next if ! $test;
        my $raw = trim( strip_comments( $test ) ) || next;
        my($string, $frozen) = split m{ \n }xms, $raw, 2;
        push @buf, {
            string => $string,
            struct => $frozen && $opt->{thaw} ? { thaw( $frozen ) } : $frozen,
            id     => ++$id,
        };
    }
    return @buf;
}

sub merge_files {
    my $base = 't/data';
    local *DIR;
    opendir DIR, $base or die "Can't opendir($base): $!";
    my %base_file;
    while ( my $file = readdir DIR ) {
        my $exact = join q{/}, $base, $file;
        next if $file eq '.' || $file eq '..' || -d $exact;
        $base_file{ $exact } = 1;
    }
    closedir DIR;
    my @files;
    my $probe = sub {
        return if -d;
        return if basename( $_ ) =~ m{ \A [.] }xms;
        return if $base_file{ $_ };
        push @files, $_;
    };
    find {
        no_chdir => 1,
        wanted   => $probe,
    }, $base;

    my $raw = q{};
    foreach my $file ( @files ) {
        my @raw = split RE_SEPTOR, slurp( $file );
        $raw .= join SEPTOR, map { qq{\n\n#$COMMENT $file\n\n$_} } @raw;
    }

    return $raw;
}

sub thaw {
    my $s = shift || die "Frozen?\n";
    my %rv;
    my $eok = eval "\%rv = (\n $s \n);";
    die "Can not restore data: $@\n\t>> $s <<" if $@ || ! $eok;
    return %rv;
}

sub trim {
    my $s = shift;
    return $s if ! $s;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}

sub strip_comments {
    my $s = shift;
    return $s if ! $s;
    my $buf = q{};
    my $file;
    foreach my $line ( split m{ \n }xms, $s ) {
        chomp $line;
        next if ! $line;
        if ( my @m = $line =~ m{ \A [#] (.+?)? \z }xms ) {
            next if ! $m[0]; # line only had a hash and nothing else
            if ( my @f = $m[0] =~ m{ \A \Q$COMMENT\E (.+?) \z }xms ) {
                $file = trim( $f[0] );
            }
            if ( my @n = $m[0] =~ m{ \A TODO: \s? (.+?) \z }xms ) {
                push @todo, [ $file, $n[0] ];
            }
            next;
        }
        $buf .= $line . "\n";
    }

    return $buf;
}

sub slurp {
    my $file = shift;
    my $FH = IO::File->new;
    $FH->open( $file, 'r')
        or croak sprintf 'Can not open DB @ %s: %s', $file, $!;
    my $rv = do { local $/; my $s = <$FH>; $s };
    $FH->close;
    return $rv;
}

1;

__END__
