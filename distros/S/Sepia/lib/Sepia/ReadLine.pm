package Sepia::ReadLine;
use Term::ReadLine;
use Sepia;
require Exporter;
@ISA='Exporter';
@EXPORT='repl';

sub rl_complete
{
    my ($text, $line, $start) = @_;
    my @xs;
    if (substr($line, 0, $start) =~ /^\s*$/ && $text =~ /^,(\S*)$/) {
        my $x = qr/^\Q$1\E/;
        @xs = map ",$_", grep /$x/, keys %Sepia::REPL;
    } else {
        my ($type, $str) = (substr $line, $start ?(($start-1), length($text)+1)
                                : ($start, length($text)))
            =~ /^([\$\@\%\&]?)(.*)/;
        my %h = qw(@ ARRAY % HASH & CODE * IO $ VARIABLE);
        @xs = Sepia::completions $h{$type||'&'}, $str;
    }
    @xs;
}

sub repl
{
    { package main; do $_ for @ARGV }
    $TERM = new Term::ReadLine $0;
    my $rl = Term::ReadLine->ReadLine;
    if ($rl =~ /Gnu/) {
        my $attr = $TERM->Attribs;
        $attr->{completion_function} = \&rl_complete;
    } elsif ($rl =~ /Perl/) {
        $readline::rl_completion_function = \&rl_complete;
        $readline::var_TcshCompleteMode = 1;
    # XXX: probably helpful...
    # } elsif (grep -x "$_/rlwrap", split ':', $ENV{PATH}) {
    #     warn "Sepia::ReadLine: Falling back to rlwrap.\n";
    } else {
        warn "Sepia::ReadLine: No completion with $rl.\n";
    }
    $Sepia::READLINE = sub { $TERM->readline(Sepia::prompt()) };
    goto &Sepia::repl;
}

1;
