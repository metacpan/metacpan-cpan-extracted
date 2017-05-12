package Table::Readable;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/read_table write_table/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.02';
use Carp;


sub read_file
{
    my ($file) = @_;
    my @rv;
    open my $in, "<:encoding(utf8)", $file or die "Error opening '$file': $!";
    while (<$in>) {
	push @rv, $_;
    }
    close $in or die $!;
    return @rv;
}

sub open_file
{
    my ($list_file) = @_;
    croak "$list_file not found" unless -f $list_file;
    open my $list, "<:encoding(utf8)", $list_file or die $!;
    return $list;
}

sub read_table
{
    my ($list_file, %options) = @_;
    my @table;
    my $row = {};
    push @table, $row;
    my $mode = "single-line";
    my $mkey;

    my @lines;
    if ($options{scalar}) {
        @lines = split /\n/, $list_file;
	for (@lines) {
	    $_ .= "\n";
	}
	$lines[-1] =~ s/\n$//;
    }
    else {
        @lines = read_file ($list_file);
    }
    my $count = 0;
    for (@lines) {

        $count++;

        # Detect the first line of a cell of the table whose
        # information spans several lines of the input file.

        if (/^%%\s*([^:]+):\s*$/) {
            $mode = "multi-line";
            $mkey = $1;
            next;
        }

        # Continue to process a table cell whose information spans
        # several lines of the input file.

        if ($mode eq "multi-line") {
            if (/^%%\s*$/) {
                $mode = "single-line";
		if ($row->{$mkey}) {
		    # Strip leading and trailing whitespace
		    $row->{$mkey} =~ s/^\s+|\s+$//g;
		}
                $mkey = undef;
            }
            else {
                $row->{$mkey} .= $_;
            }
            next;
        }
        if (/^\s*#.*/) {

            # Skip comments.

            next;
        }
        elsif (/([^:]+):\s*(.*?)\s*$/) {

            # Key / value pair on a single line.

            my $key = $1;
            my $value = $2;

            # If there are any spaces in the key, substitute them with
            # underscores.

            $key =~ s/\s/_/g;
            if ($row->{$key}) {
                croak "$list_file:$count: duplicate for key $key\n";
            }
            $row->{$key} = $value;
        }
        elsif (/^\s*$/) {

            # A blank line signifies the end of a row.

            if (keys %$row > 0) {
                $row = {};
                push @table, $row;
            }
            next;
        }
        else {
	    my $file_line = "$list_file:$count:";
	    if ($options{scalar}) {
		$file_line = "$count:";
	    }
            warn "$file_line unmatched line '$_'\n";
        }
    }
    # Deal with the case of whitespace at the end of the file.
    my $last_row = $table[-1];
    if (keys %$last_row == 0) {
        pop @table;
    }
    croak "read_table returns an array" unless wantarray ();
    return @table;
}

# Maximum length of a single-line entry.

our $maxlen = 75;

sub write_table
{
    my ($list, $file) = @_;
    if (ref $list ne 'ARRAY') {
	carp "First argument to 'write_table' must be array reference";
	return;
    }
    my $n = 0;
    for my $i (@$list) {
	if (ref $i ne 'HASH') {
	    carp "Elements of first argument to 'write_table' must be hash references";
	    return;
	}
	for my $k (keys %$i) {
	    if (ref $i->{$k}) {
		carp "Non-scalar value in key $k of element $n";
		return;
	    }
	}
	$n++;
    }
    my $text = '';
    for (@$list) {
	for my $k (sort keys %$_) {
	    my $v = $_->{$k};
	    if (length ($v) + length ($k) > $maxlen ||
		$v =~ /\n/) {
		$text .=  "%%$k:\n$v\n%%\n";
	    }
	    else {
		$text .=  "$k: $v\n";
	    }
	}
	$text .=  "\n";
    } 
    if ($file) {
	open my $out, ">:encoding(utf8)", $file or croak "Can't open $file for writing: $!";
	print $out $text;
	close $out or die $!;
    }
    elsif (defined (wantarray ())) {
	return $text;
    }
    else {
	print $text;
    }
}

1;
