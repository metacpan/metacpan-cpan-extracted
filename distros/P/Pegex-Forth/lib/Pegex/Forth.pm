package Pegex::Forth;
our $VERSION = '0.15';

use Pegex::Base;
use Pegex::Parser;

has 'args' => [];

sub command {
    my ($self) = @_;
    my $args = $self->args;
    my $input;
    if (@$args) {
        if (-f $args->[0]) {
            open my $fh, $args->[0] or die;
            $input = do { local $/; <$fh> };
        }
        else {
            die "Unknown args";
        }
    }
    else {
        $input = do { local $/; <> };
    }
    $self->run($input);
}

sub run {
    my ($self, $input) = @_;
    my $exec = Pegex::Forth::Exec->new;
    my $parser = Pegex::Parser->new(
        grammar => Pegex::Forth::Grammar->new,
        receiver => $exec,
        # debug => 1,
    );
    $parser->parse($input);
    my $values = $exec->runtime->stack;
    return unless @$values;
    wantarray ? @$values : $values->[-1];
}

#------------------------------------------------------------------------------
package Pegex::Forth::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';
use constant text => <<'...';
forth: - token*

token:
  | number
  | comment
  | word

number: /( DASH? DIGIT+ ) +/
comment: /'(' + ALL*? ')' +/
word: /( NS+ ) +/

ws: / (: WS | EOS ) /
...

#------------------------------------------------------------------------------
package Pegex::Forth::Exec;
use Pegex::Base;
extends 'Pegex::Tree';

use Pegex::Forth::Runtime;

has runtime => sub { Pegex::Forth::Runtime->new };

sub got_number {
    my ($self, $number) = @_;
    $self->runtime->push($number);
}

sub got_word {
    my ($self, $word) = @_;
    $self->runtime->call($word);
}

1;
