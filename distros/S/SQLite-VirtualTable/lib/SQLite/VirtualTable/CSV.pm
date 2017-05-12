package SQLite::VirtualTable::CSV;

use Data::Dumper;
use Text::CSV_XS;
use IO::Handle;

use SQLite::VirtualTable::Util qw(unescape);

use base 'SQLite::VirtualTable';

sub CREATE {
    my ($class, $mod, $db, $table, $fn, @opts) = @_;
    defined $fn or die "file name missing\n";
    open my $fh, '<', unescape $fn
        or die "unable to open $fn: $!\n";
    my %opts;
    for (@opts) {
        $_ = unescape $_;
        /^(\w+)\s*=\s*(.*)$/
            or die "invalid option '$_'";
        $opts{$1} = $2;
    }

    my @cols;
    my $cols = delete $opts{columns};
    my $csv = Text::CSV_XS->new(\%opts);

    if (defined $cols) {
        @cols = split(/\s*,\s*/, $cols)
    }
    else {
        while (<$fh>) {
            next if /^\s*$/;
            if (s/^\s*#+//) {
                if ($csv->parse($_)) {
                    @cols = $csv->fields;
                    last;
                }
            }
            if (my $cols = $csv->getline($fh)) {
                @cols = map { "COL$_" } 0..$#$cols;
                last;
            }
            else {
                die "unable to read CSV file header";
            }
        }
    }
    my $self = bless { fh => $fh, fn => $fn,
                       table => $table, columns => \@cols,
                       csv => $csv }, $class;
    return $self;
}

*CONNECT = \&CREATE;

sub DECLARE_SQL {
    my $self = shift;
    my $desc = join(', ', @{$self->{columns}});
    my $decl = "CREATE TABLE $self->{table} ($desc)";
    # warn "decl: $decl\n";
    $decl;
}

sub BEST_INDEX {
    # warn "BEST_INDEX";
    return (0, "", undef, 0)
}

sub OPEN {
    # warn "OPEN";
    return [0];
}

sub FILTER {
    # warn "FILTER";
    my ($self, $cur) = @_;
    @$cur = (0, 0, 0, undef);
}

sub EOF {
    # warn "EOF";
    my ($self, $cur) = @_;
    seek($self->{fh}, $cur->[1], 0);
    my $eof = eof($self->{fh});
    # print "eof: $eof\n";
    $eof;
}

sub populate {
    my ($self, $cur) = @_;
    unless ($cur->[3]) {
        my $fh = $self->{fh};
        seek $fh, $cur->[1], 0;
        my $data = $self->{csv}->getline($fh);
        $cur->[2] = tell($fh);
        $cur->[3] = $data;
    }
}

sub NEXT {
    # warn "NEXT";
    my ($self, $cur) = @_;
    $self->populate($cur);
    $cur->[0]++;
    $cur->[1] = $cur->[2];
    $cur->[2] = undef;
    $cur->[3] = undef;
}

sub COLUMN {
    # warn "COLUMN";
    my ($self, $cur, $n) = @_;
    $self->populate($cur);
    my $data = $cur->[3] || [];
    my $col = $data->[$n];
    $col = int($col) if $col =~ /^[+-]?\d+(?:\.\d+)?$/;
    # print "col = $col\n";
    return $col;
}

sub ROWID {
    my ($self, $cur) = @_;
    warn "ROWID [cur: @$cur]";

    $cur->[0];
}

sub CLOSE {
    # warn "CLOSE";
    my ($self, $cur) = @_;
    @$cur = ();
}

sub DISCONNECT {}

*DESTROY = \&DISCONNECT;

1;
