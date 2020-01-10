use strict; use warnings;

package TestMLBridge;
use base 'TestML::Bridge';

use Pegex::Parser;
use Swim::Grammar;
use Swim::Byte;
use Swim::HTML;
use Swim::Markdown;
use Swim::Pod;

sub parse {
    my ($self, $swim, $emitter, $style) = @_;

    $style ||= '';

    my $receiver = "Swim::$emitter"->new;

    if ($style eq 'wrap') {
        $receiver->option->{wrap} = 1;
    }

    my $parser = Pegex::Parser->new(
        grammar => 'Swim::Grammar'->new,
        receiver => $receiver,
        debug => $ENV{SWIM_PEGEX_DEBUG},
    );

    eval 'use XXX; XXX($parser->grammar->tree)'
      if $ENV{SWIM_PEGEX_TREE};

    $parser->parse($swim);
}

1;
