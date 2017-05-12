use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # MAKAROW/ARSObject-0.57/lib/ARSObject.pm
sub cgitfrm {   # table form layot
        # -form =>{form attrs}, -table=>{table attrs}, -tr=>{tr attrs}, -td=>{}, -th=>{}
 my ($s, %a) =$_[0];
 my $i =1;
 while (ref($_[$i]) ne 'ARRAY') {$a{$_[$i]} =$_[$i+1]; $i +=2};
 $s->cgi->start_form(-method=>'POST',-action=>'', $a{-form} ? %{$a{-form}} : ())
    # ,-name=>'test'
 .$s->{-cgi}->table($a{-table} ? $a{-table} : (), "\n"
 .join(''
    , map { my $r =$_;
        $s->{-cgi}->Tr($a{-tr} ? $a{-tr} : (), "\n"
        .join(''
            , map { ($_ =~/^</
                ? $s->{-cgi}->td($a{-td} || {-align=>'left', -valign=>'top'}, $_)
                : $s->{-cgi}->th($a{-th} || $a{-td} || {-align=>'left', -valign=>'top'}, $_)
                ) ."\n"
                } @$r)
        ) ."\n"
        } @_[$i..$#_])) ."\n"
 .$s->cgi->end_form()
}
TEST

test(<<'TEST'); # BRICAS/Games-NES-Emulator-0.03/lib/CPU/Emulator/6502/Op/DEY.pm
sub dey {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ y } = ( $reg->{ y } - 1 ) & 0xff;
    $self->set_nz( $reg->{ y } );
}
TEST

test(<<'TEST'); # ANNO/Vi-QuickFix-1.134/lib/Vi/QuickFix.pm
unless ( caller ) {
    # process <> if called as an executable
    exec_mode(1); # signal fact ( to END processing)
    require Getopt::Std;
    Getopt::Std::getopts( 'q:f:v', \ my %opt);
    print "$0 version $VERSION\n" and exit 0 if $opt{ v};
    err_open( $opt{ q} || $opt{ f});
    print && err_out( $_) while <>;
    exit;
}
TEST

done_testing;
