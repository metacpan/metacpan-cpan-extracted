use strict;
use warnings;
use Carp;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use POSIX::Run::Capture qw(:std);
use POSIX ":sys_wait_h";

our $catbin;
our $input;
our $content;

BEGIN {
    my $dir = dirname(dirname(abs_path(__FILE__)));
    $catbin = $dir . '/runcap/t/genout';
    $input = $dir . '/runcap/t/INPUT';
    
    local $/ = undef;
    open(my $fd, $input) or die "couldn't open \"$input\": $!";
    binmode($fd);
    $content = <$fd>;
    close($fd);
}

sub mismatch {
    my ($what, $exp, $got) = @_;
    diag("$what mismatch: $exp <=> $got");
}

sub test_stream {
    my ($cap, $kw, $fd) = @_;
    
    if (exists($kw->{length}) && $kw->{length} != $cap->length($fd)) {
	mismatch("stdout length", $kw->{length}, $cap->length($fd));
	return 0;
    }
    if (exists($kw->{nlines}) && $kw->{nlines} != $cap->nlines($fd)) {
	mismatch("number of stdout lines", $kw->{nlines}, $cap->nlines($fd));
	return 0;
    }
    if (exists($kw->{content})) {
	my $lines = $cap->get_lines($fd);
	my $content = join('',@$lines);
	if ($kw->{content} ne $content) {
	    diag("stdout content mismatch");
	    return 0;
	}
    }
    return 1;
}
    
sub TestCapture {
    my ($argv, %kw) = @_;

    $kw{result} = 1 unless exists $kw{result};
    $kw{code}   = 0 unless exists $kw{code};

    my $cap;
    if (ref($argv) eq 'ARRAY') {
	$cap = new POSIX::Run::Capture $argv;
    } elsif (ref($argv) eq 'HASH') {
	$cap = new POSIX::Run::Capture %$argv;
    } else {
	croak "bad argv type";
    }
    
    return 0 unless $cap;

    my $res = $cap->run;

    unless ($kw{result} == $res) {
	mismatch("result code", $res, $kw{result});
	return 0;
    }

    unless (WIFEXITED($cap->status)) {
	diag("unexpected termination status: ".$cap->status);
	return 0;
    }

    unless (WEXITSTATUS($cap->status) == $kw{code}) {
	mismatch("exit code", WEXITSTATUS($cap->status), $kw{code});
	return 0;
    }

    if (exists($kw{stdout}) && !test_stream($cap, $kw{stdout}, SD_STDOUT)) {
	return 0;
    }

    if (exists($kw{stderr}) && !test_stream($cap, $kw{stderr}, SD_STDERR)) {
	return 0;
    }
    
    return 1;
}
1;
