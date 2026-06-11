package Test2AndUtils;
use v5.26;
use warnings;
use FindBin;
use Test2::V0 '!subtest';
use Test2::Tools::Subtest 'subtest_streamed';
use experimental qw( signatures );
use parent 'Test2::V0';
use File::Temp ();
use IO::Handle;
our @CARP_NOT= qw( File::Temp );
# Log::Any output merged into TAP stream is nice, but not required
BEGIN {
   eval q{use Log::Any::Adapter 'TAP'; 1}
   or eval q{use Log::Any::Adapter 'Stderr', log_level => 'warn'; 1}
}

our @EXPORT= (
   @Test2::V0::EXPORT,
   qw( explain mkfile slurp escape_nonprintable hexdump tmpfile tmpdir )
);

# Test2 runs async by default, which messes up the relation between warnings and the test
# that generated them.  Streamed generates output sequentially.
*subtest= \&subtest_streamed;

# Use Data::Printer if available, but fall back to Data::Dumper
eval q{
   use Data::Printer;
   sub explain { Data::Printer::np(@_) }
   1
} or eval q{
   use Data::Dumper;
   sub explain { Data::Dumper->new(\@_)->Terse(1)->Indent(1)->Sortkeys(1)->Dump }
   1
} or die $@;

sub tmpfile(%opts) {
   $opts{TMPDIR}= 1;
   # The rand seed has been set identical in every unit test, so to prevent collisions,
   # prefix with test name.  Also generally helpful for debugging.
   $opts{TEMPLATE} //= 'XXXXXX';
   $opts{TEMPLATE}= ($FindBin::Script =~ s/\.t\z/-/r) . $opts{TEMPLATE};
   my ($script_num)= ($FindBin::Script =~ /^(\d+)/);
   $opts{UNLINK}= !$ENV{"DEBUG_$script_num"};
   my $tmp= File::Temp->new(%opts);
   diag "Leaving temp files at $tmp" unless $opts{UNLINK};
   $tmp;
}

sub tmpdir(%opts) {
   $opts{TMPDIR}= 1;
   # The rand seed has been set identical in every unit test, so to prevent collisions,
   # prefix with test name.  Also generally helpful for debugging.
   $opts{TEMPLATE} //= 'XXXXXX';
   $opts{TEMPLATE}= ($FindBin::Script =~ s/\.t\z/-/r) . $opts{TEMPLATE};
   my ($script_num)= ($FindBin::Script =~ /^(\d+)/);
   $opts{CLEANUP}= !$ENV{"DEBUG_$script_num"};
   my $tmp= File::Temp->newdir(%opts);
   diag "Leaving temp files at $tmp/*" unless $opts{CLEANUP};
   $tmp;
}

# Convert data strings to and from C / Perl backslash notation.
# Not exhaustive, just hit the most common cases and hex-escape the rest.

my %escape_to_char = ( "\\" => "\\", r => "\r", n => "\n", t => "\t" );
my %char_to_escape = reverse %escape_to_char;

sub escape_nonprintable($str) {
   $str =~ s/([^\x21-\x7E])/ defined $char_to_escape{$1}? "\\".$char_to_escape{$1} : sprintf("\\x%02X", ord $1) /ge;
   return $str;
}

sub unescape_nonprintable($str) {
   $str =~ s/\\(x([0-9A-F]{2})|.)/ defined $2? chr hex $2 : $escape_to_char{$1} /ge;
   return $str;
}

sub mkfile($name, $data, $mode=undef) {
   open my $fh, '>:raw', $name or die "open(>$name): $!";
   $fh->print($data) or die "write($name): $!";
   $fh->close or die "close($name): $!";
   chmod $mode, $name or die "chmod($name, $mode): $!"
      if defined $mode;
   1;
}

sub slurp($name) {
   open my $fh, '<:raw', $name or die "open(<$name): $!";
   local $/;
   my $ret= scalar <$fh>;
   close $fh or die "close($name): $!";
   $ret;
}

# Equivalent of unix command 'hexdump -C'
# https://www.perlmonks.org/?node_id=11166492
sub hexdump($data) {
   $data =~ s/\G(.{1,16})(\1+)?/
      sprintf "%08x  %-50s|%s|\n%s", $-[0], "@{[unpack q{(H2)8a0(H2)8},$1]}",
         $1 =~ y{ -~}{.}cr, "*\n"x!!$+[2]
   /segr . sprintf "%08x", $+[0]
}

1;

