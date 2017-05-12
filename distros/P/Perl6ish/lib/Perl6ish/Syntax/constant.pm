package Perl6ish::Syntax::constant;
use strict;
use Devel::Declare;
use Readonly;

our ($Declarator, $Offset);

sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

sub handle_constant {
    my $line = Devel::Declare::get_linestr;
    $Offset = Devel::Declare::get_linestr_offset;

    if (my ($statement, $sigil, $name, $val) = $line =~ /(\bconstant\s+([\$\@\%])(\w+)\s*=\s*(.+);)/) {
        skip_declarator;
        my $var = "$sigil$name";

        substr( $line, $Offset, length($statement) ) = "(my $var, $val);";
        Devel::Declare::set_linestr($line);

        print "emit: $line\n" if $sigil eq '@';
    }    
}

sub constant(\[$@%]@) {
    my $ref = shift;

    if (ref($ref) eq 'SCALAR') {
        my $val = shift;
        Readonly::Scalar $$ref, $val;
    }
    elsif (ref($ref) eq 'ARRAY') {
        Readonly::Array @$ref, @_;
    }
    elsif (ref($ref) eq 'HASH') {
        my %val = (@_);
        Readonly::Hash %$ref, %val;
    }

}

sub import {
    my $caller = caller;
    no strict;
    *{"$caller\::constant"} = \&constant;

    Devel::Declare->setup_for(
        $caller => { constant => { const => \&handle_constant } }
    );
    1;
}


1;

