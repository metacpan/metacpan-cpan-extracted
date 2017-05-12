#===============================================================================
#
#  DESCRIPTION:  Test I<> implementation
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::X;

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';

sub x0000_process_index_string : Test(4) {
    my $t   = shift;
    my $str = "hash";
    my @r1  = &Perl6::Pod::FormattingCode::X::process_index( undef, $str );
    is_deeply \@r1, [ 'hash', ['hash'] ], 'X<hash>';
    $str = "scalar|variables";
    my @r2 = &Perl6::Pod::FormattingCode::X::process_index( undef, $str );
    is_deeply \@r2, [ 'scalar', ['variables'] ], "X<$str>";
    $str = "scalar|variables, definition of";
    my @r3 = &Perl6::Pod::FormattingCode::X::process_index( undef, $str );
    is_deeply \@r3, [ 'scalar', ['variables, definition of'] ], "X<$str>";

    $str = "hash|hashes, definition of; associative arrays";
    my @r4 = &Perl6::Pod::FormattingCode::X::process_index( undef, $str );
    is_deeply \@r4,
      [ 'hash', [ 'hashes, definition of', 'associative arrays' ] ], "X<$str>";
}

sub x001_xml : Test {
    my $t = shift;
    my $x = $t->parse_to_xml( <<T);
=begin pod
test X< variable >
test X< scalar | variable >
test X< scalar | variable , define of; array>
test X< | variable , define of; array>
=end pod
T
    $t->is_deeply_xml(
        $x,
q%<pod pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><para pod:type='block'>test <X pod:index_text='variable' pod:type='code' pod:index_entry='variable'>variable</X>test <X pod:index_text='scalar' pod:type='code' pod:index_entry='variable'>scalar</X>test <X pod:index_text='scalar' pod:type='code' pod:index_entry='variable , define of; array'>scalar</X>test <X pod:index_text='' pod:type='code' pod:index_entry='variable , define of; array' /></para></pod>
%
    );
}

sub x002_xhml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=begin pod
test X< variable >
test X< scalar | variable >
test X< scalar | variable , define of; array>
=end pod
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>test variable
 test scalar
 test scalar
 </p></xhtml>#
    );
}

sub x003_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=begin pod
test X< variable >
test X< scalar | variable >
test X< scalar | variable , define of; array>
test1 X<| variable , define of; array>
=end pod
T
    $t->is_deeply_xml( $x,
q#<chapter><para>test variable<indexterm><primary>variable</primary></indexterm>
test scalar<indexterm><primary>variable</primary></indexterm>
test scalar<indexterm><primary>variable</primary><secondary>define of</secondary></indexterm><indexterm><primary>array</primary></indexterm>
test1 <indexterm><primary>variable</primary><secondary>define of</secondary></indexterm><indexterm><primary>array</primary></indexterm>
</para></chapter>#

    );
}

1;

