package Perl6ish::Syntax::state;
use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Devel::Caller qw(called_with caller_cv);

use Devel::Declare;
use Data::Bind;

our ($Declarator, $Offset);

sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

my %stash = ();

sub handle_state {
    my $line = Devel::Declare::get_linestr;
    $Offset = Devel::Declare::get_linestr_offset;

    if (my ($statement, $sigil, $name, $val) = $line =~ /(\bstate\s+([\$\@\%])(\w+)\s*=\s*(.+);)/) {
        skip_declarator;
        my $var = "$sigil$name";

        substr( $line, $Offset, length($statement) ) = "(my $var, $val);";
        Devel::Declare::set_linestr($line);
    }
}

sub state(\$$) {
    my ($varref, $varval) = @_;
    my $varname = (called_with(0, 1))[0];
    my $caller_addr = refaddr( caller_cv(1) );
    my $k = "$caller_addr $varname";
    $$varref = $stash{ $k } ||= $varval;

    bind_op2( $varref, \$stash{$k} );
}

sub import {
    my $caller = caller;
    no strict;
    *{"$caller\::state"} = \&state;

    Devel::Declare->setup_for(
        $caller => { state => { const => \&handle_state } }
    );
}

1;
