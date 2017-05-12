#!/usr/bin/perl

use SWF::Builder::ActionScript::Compiler;

use Getopt::Std;
use Pod::Usage;

my %opts;
getopts('ath?e:V:W:O:T:', \%opts);

pod2usage() if $opts{h} or $opts{'?'};

my $text = $opts{e};
unless (defined $text) {
    local $/;
    $text = <>;
}

$a = SWF::Builder::ActionScript::Compiler->new($text, Version=>$opts{V}, Warning =>$opts{W}, Optimize => $opts{O}, Trace => $opts{T});

if ($opts{t}) {
    $a->compile('tree');
} elsif ($opts{a}) {
    $a->compile('text');
} else {
    $a->compile('dump');
}

__END__

=head1 NAME

asc.plx - SWF ActionScript compiler script.

=head1 SYNOPSIS

 perl asc.plx [ -V[5/6] -Wx -Ox -Tsss -t -a ] [ file.as / -e 'script' ] 

=head2 Options

=over 4

=item -V

SWF version. 5 or 6. Default is 6.

=item -W

Warning level.

=item -O

Optimizarion control flags.

=item -T

How to compile trace action. none/eval/lcwin/trace.

=item -t

Output a parsed syntax tree instead of compiled action records.

=item -a

Output an 'assembly' action tag list instead of compiled action records.

=item -e

Compile given script text instead of a file.

=item -h/-?

Show this message.

=back

=cut
