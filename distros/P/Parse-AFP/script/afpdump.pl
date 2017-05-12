#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Parse-Binary/lib";

# XXX - use encoding 'utf8' cannot be used as it interferes with code parsing
#       resulting in inconsistent utf8 flag on all of the @ARGV!
#use encoding 'utf8';
#utf8::upgrade($_) for @ARGV; # XXX black, black voodoo magic

use File::Basename;
use Parse::AFP;
use Encode::IBM;
use Encode::Guess;
use Getopt::Std;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

$Encode::Guess::NoUTFAutoGuess = 1;
use vars qw/$opt_e/; getopts('e:');
Encode::Guess->set_suspects(split(/\s*,\s*/, ($opt_e || 'cp500,ibm-835')));

=head1 NAME

adpdump.pl - Dump IBM AFP data to HTML

=head1 SYNOPSIS

    # Defaults to "cp500, ibm-835" encoding
    % afpdump.pl input.afp > output.html

    # For Big5-encoded AFPs
    % afpdump -e cp437,ibm-947 big5.afp > output.html

=cut

my %desc;
foreach my $type qw( Record Triplet PTX/ControlSequence ) {
    require "Parse/AFP/$type.pm";
    open my $fh, $INC{"Parse/AFP/$type.pm"} or die $!;
    while (<$fh>) {
	/'([A-Z][:\w]+)',\s+#\s?(.+)/ or next;
	$desc{$1} = $2;
    }
}

sub Header ();
sub Parse::AFP::PTX::TRN::ENCODING () { 'Guess' };

die "Usage: $0 [ -e codepage1,codepage2... ] file.afp > file.html\n"
  unless @ARGV;

$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };
$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };

my $input = shift;
my $afp = Parse::AFP->new($input, { lazy => 1 });
$input = basename($input);

print Header();
print "<h1>$input</h1><ol class='top'>\n";
dump_members($afp);
print "</ol></body></html>\n";

sub dump_afp {
    my $obj = shift;
    my $struct = $obj->struct;
    print "<table border=0 summary='$obj'>";

    my @keys = sort grep !/^_|^(?:Data|EscapeSequence|ControlCode|Length|CC|(?:Sub)?Type|FlagByte)$/, keys %$struct;
    push @keys, 'Data' if exists $struct->{Data};
    foreach my $key (@keys) {
	next if ref $struct->{$key};
	length($x = $struct->{$key}) or next;

	if ($obj->ENCODING and grep { $key eq $_ } $obj->ENCODED_FIELDS) {
	    $x = $obj->$key;
	    $x = qq("$x");
	}
	elsif ($x =~ /[^\w\s]/) {
	    $x = '<span class="hex">'.uc(join(' ',
		(length($x) <= 80) 
		    ? unpack('(H2)*', $x)
		    : (unpack('(H2)*', substr($x, 0, 80)), '...')
	    )).'</span>';
	}
	if ($key eq 'Data') {
	    print "<tr><td colspan='2' class='item'>$x</td></tr>\n";
	}
	else {
	    print "<tr><td class='label'>$key</td><td class='item'>$x</td></tr>\n";
	}
    }

    print "</table>";
    if ($obj->has_members) {
	print "<ol>";
	dump_members($obj);
	print "</ol>";
    }
}

sub dump_members {
    my $obj = shift;
    while (my $rec = $obj->next_member) {
	my $type = substr(ref($rec), 12);
	print "<li><div><strong>$type</strong>";
	print " &ndash; $desc{$type}" if exists $desc{$type};
	print "</div>";
	dump_afp($rec);
	print "</li>";
    }
}

use constant Header => << '.';
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><style type='text/css'><!--
body { background: #e0e0e0; font-family: times new roman, times; margin-left: 20px }
h1 { font-family: times }
span.hex { font-family: andale mono, courier }
ol { border-left: 1px dotted black }
ol.top { border-left: none }
table { font-size: small; border-left: 1px dotted black; padding-left: 6pt; width: 100% }
td.label { background: #d0d0d0; font-family: arial unicode ms, helvetica }
td.item { background: white; width: 100%; font-family: arial unicode ms, helvetica }
div { text-decoration: underline; background: #e0e0ff; font-family: arial unicode ms, helvetica }
--></style><title>AFP Dump</title></head><body>
.

1;

no warnings 'redefine';
package Encode::Guess;
sub guess {
    my $class = shift;
    my $obj   = ref($class) ? $class : $Encode::Encoding{$Canon};
    my $octet = shift;

    # sanity check
    return unless defined $octet and length $octet;

    # cheat 0: utf8 flag;
    if ( Encode::is_utf8($octet) ) {
	return find_encoding('utf8') unless $NoUTFAutoGuess;
	Encode::_utf8_off($octet);
    }
    # cheat 1: BOM
    use Encode::Unicode;
    unless ($NoUTFAutoGuess) {
	my $BOM = unpack('n', $octet);
	return find_encoding('UTF-16')
	    if (defined $BOM and ($BOM == 0xFeFF or $BOM == 0xFFFe));
	$BOM = unpack('N', $octet);
	return find_encoding('UTF-32')
	    if (defined $BOM and ($BOM == 0xFeFF or $BOM == 0xFFFe0000));
	if ($octet =~ /\x00/o){ # if \x00 found, we assume UTF-(16|32)(BE|LE)
	    my $utf;
	    my ($be, $le) = (0, 0);
	    if ($octet =~ /\x00\x00/o){ # UTF-32(BE|LE) assumed
		$utf = "UTF-32";
		for my $char (unpack('N*', $octet)){
		    $char & 0x0000ffff and $be++;
		    $char & 0xffff0000 and $le++;
		}
	    }else{ # UTF-16(BE|LE) assumed
		$utf = "UTF-16";
		for my $char (unpack('n*', $octet)){
		    $char & 0x00ff and $be++;
		    $char & 0xff00 and $le++;
		}
	    }
	    DEBUG and warn "$utf, be == $be, le == $le";
	    $be == $le 
		and return
		    "Encodings ambiguous between $utf BE and LE ($be, $le)";
	    $utf .= ($be > $le) ? 'BE' : 'LE';
	    return find_encoding($utf);
	}
    }
    my %try =  %{$obj->{Suspects}};
    for my $c (@_){
	my $e = find_encoding($c) or die "Unknown encoding: $c";
	$try{$e->name} = $e;
	DEBUG and warn "Added: ", $e->name;
    }
    my $nline = 1;
    for my $line (split /\r\n?|\n/, $octet){
	# cheat 2 -- \e in the string
	if ($line =~ /\e/o){
	    my @keys = keys %try;
	    delete @try{qw/utf8 ascii/};
	    for my $k (@keys){
		ref($try{$k}) eq 'Encode::XS' and delete $try{$k};
	    }
	}
	my %ok = %try;
	# warn join(",", keys %try);
	for my $k (keys %try){
	    my $scratch = $line;
	    $try{$k}->decode($scratch, FB_QUIET);
	    if ($scratch eq ''){
		DEBUG and warn sprintf("%4d:%-24s ok\n", $nline, $k);
	    }else{
		use bytes ();
		DEBUG and 
		    warn sprintf("%4d:%-24s not ok; %d bytes left\n", 
				 $nline, $k, bytes::length($scratch));
		delete $ok{$k};
	    }
	}
	%ok or return "No appropriate encodings found!";
	if (scalar(keys(%ok)) >= 1){
	    my ($retval) = sort values(%ok);
	    return $retval;
	}
	%try = %ok; $nline++;
    }
    $try{ascii} or 
	return  "Encodings too ambiguous: ", join(" or ", keys %try);
    return $try{ascii};
}

