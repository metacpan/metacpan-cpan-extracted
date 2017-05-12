use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;

my $testml = join('', <DATA>);
my $debug = 0;
my $tree = 0;

if (@ARGV) {
    $testml =~ s/^/# /gm;
    $testml =~ s/^# //m for 1..5;
    my $markup = 0;
    for (@ARGV) {
        if (/^(byte|html|pod|markdown)$/) {
            $testml =~ s/^# (Label.*\n)# (.*\*$_)$/$1$2/m;
            $markup = 1;
        }
        elsif (/^diff$/) {
            $testml =~ s/^#(Diff )/$1/m;
        }
        elsif (/^debug$/) {
            $debug = 1;
        }
        elsif (/^tree$/) {
            $tree = 1;
        }
        else {
            s/\.tml$//;
            s/.*test\///;
            $testml =~ s/^# (%Include $_\.tml)$/$1/m;
        }
    }
    $testml =~ s/^# (Label.*\n)# (.*)$/$1$2/gm unless $markup;
}


TestML->new(
    testml => $testml,
    bridge => 'main',
)->run;

use base 'TestML::Bridge';
use TestML::Util;
use Swim::Grammar;
use Swim::Byte;
use Swim::HTML;
use Swim::Markdown;
use Swim::Pod;

sub parse {
    my ($self, $swim, $emitter) = @_;
    $swim = $swim->{value};
    $emitter = $emitter->{value};
    my $parser = Pegex::Parser->new(
        grammar => 'Swim::Grammar'->new,
        receiver => "Swim::$emitter"->new,
        debug => $debug,
    );
    eval 'use XXX; XXX($parser->grammar->tree)'
      if $tree;
    str $parser->parse($swim);
}

__DATA__
%TestML 0.1.0

Diff = 1

Label = 'Swim to ByteCode - $BlockLabel'
*swim.parse('Byte') == *byte
Label = 'Swim to HTML - $BlockLabel'
*swim.parse('HTML') == *html
Label = 'Swim to Markdown - $BlockLabel'
*swim.parse('Markdown') == *markdown
Label = 'Swim to Pod - $BlockLabel'
*swim.parse('Pod') == *pod

%Include block.tml
%Include bugs.tml
%Include comment.tml
%Include edge.tml
%Include head.tml
%Include hyper.tml
%Include link.tml
%Include list-data.tml
%Include list.tml
%Include meta.tml
%Include para.tml
%Include phrase-func.tml
%Include phrase.tml
%Include pre.tml
