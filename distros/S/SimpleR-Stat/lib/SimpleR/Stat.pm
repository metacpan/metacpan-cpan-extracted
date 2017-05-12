# ABSTRACT: Simple Stat on arrayref, like sum, mean, calc rate, etc
package SimpleR::Stat;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  calc_rate format_percent calc_compare_rate

  uniq_arrayref uniq_arrayref_cnt
  sum_arrayref mean_arrayref median_arrayref
  calc_rate_arrayref calc_percent_arrayref
  map_arrayref
  sort_by_other_arrayref

  transpose_arrayref
  conv_arrayref_to_hash
);

use strict;
use warnings;

use Tie::Autotie 'Tie::IxHash';


our $VERSION     = 0.07;
our $DEFAULT_SEP = ',';

sub transpose_arrayref {    #二层数组的行列转置
    my ($array_ref) = @_;

    my @row_num_list = sort { $b <=> $a } map { $#$_ } @$array_ref;
    my $row_num = $row_num_list[0];

    my $col_num = $#$array_ref;

    my @data;
    for my $r ( 0 .. $row_num ) {
        my @temp = map { $array_ref->[$_][$r] } ( 0 .. $col_num );
        push @data, \@temp;
    }
    return \@data;
} 

sub conv_arrayref_to_hash {
    #注意:重复的cut_fields会被覆盖掉
    my ( $data, $cut_fields, $v_field , %opt) = @_;
    my $finish_cut = pop @$cut_fields;

    tie my (%result), 'Tie::IxHash' if($opt{remember_key_order});

    for my $row (@$data) {
        my $s = \%result;

        for my $cut (@$cut_fields) {
            my $c = calc_arrayref_cell( $row, $cut );
            $s->{$c} ||= {};
            $s = $s->{$c};
        }

        my $fin_c = calc_arrayref_cell( $row, $finish_cut );
        my $v     = calc_arrayref_cell( $row, $v_field );
        $s->{$fin_c} = $v;
    }

    return \%result;
} ## end sub conv_ref_to_hash

sub calc_arrayref_cell {
    my ( $row, $calc ) = @_;

    #calc => sub , [ .. ], row->[$i]

    my $t = ref($calc);
    my $v =
        ( $t eq 'CODE' ) ? $calc->($row)
      : ( $t eq 'ARRAY' ) ? join( $DEFAULT_SEP, @{$row}[@$calc] )
      :                     $row->[$calc];

    return $v;
}

#-----
sub sort_by_other_arrayref {
    my ($arr, $other, $map_sub, $sort_sub) = @_;
    $sort_sub ||= sub { my ($x, $y) = @_; return $x <=> $y; };

    my @sort = (! $map_sub)?
        sort { $sort_sub->($other->[$a] , $other->[$b]) } (0 .. $#$other) :
        sort { $sort_sub->($map_sub->($other->[$a]) , $map_sub->($other->[$b])) } (0 .. $#$other) ;

    return wantarray ? ([ @{$arr}[@sort] ], [ @{$other}[@sort] ]) : [ @{$arr}[@sort] ];
}

sub map_arrayref {
    my ( $r, $calc_sub, %opt ) = @_;
    my @data = $opt{keep_source} ? @$r : ();

    my $col = $opt{calc_col} || [ 0 .. $#$r ];
    my $res = $calc_sub->( [ @{$r}[@$col] ] );
    push @data, ref($res) eq 'ARRAY' ? @$res : $res;

    return $opt{return_arrayref} ? \@data : @data;
}

sub calc_percent_arrayref {
    my ( $r, $format ) = @_;
    my $rate = calc_rate_arrayref($r);
    my @percent = map { format_percent( $_, $format ) } @$rate;

    my @pn = map { s/\%// } @percent;
    my $ps = sum_arrayref(\@pn);
    if($ps>100){
        $pn[-1] = 100 - ($ps - $pn[-1]);
        @percent = map { "$_%" } @pn;
    }

    return \@percent;
}

sub calc_rate_arrayref {
    my ($r) = @_;
    $_ ||= 0 for @$r;

    my $s = sum_arrayref($r);

    my @rate;
    for my $n (@$r) {
        my $x = $s == 0 ? 0 : calc_rate( $n, $s );
        push @rate, $x;
    }

    return \@rate;
}

sub sum_arrayref {
    my ($r) = @_;
    my $num = 0;
    $num += $_ || 0 for @$r;
    return $num;
}

sub mean_arrayref {
    my ($r) = @_;
    my $n = scalar(@$r);
    return calc_rate( sum_arrayref($r), $n );
}

sub median_arrayref {
    my ($r) = @_;
    $_ ||= 0 for @$r;

    my $n = $#$r;

    my @d = sort { $a <=> $b } @$r;

    return $d[ $n / 2 ] if ( $n % 2 == 0 );

    my $m = ( $n - 1 ) / 2;
    return ( $d[$m] + $d[ $m + 1 ] ) / 2;
}

sub uniq_arrayref {
    my ($r, %opt) = @_;

    tie my (%d), 'Tie::IxHash' if($opt{remember_key_order});
    %d = map { $_ => 1 } @$r;

    my @sort = keys(%d);
    @sort = sort @sort unless($opt{remember_key_order});
    return \@sort;
}

sub uniq_arrayref_cnt {
    my ($r) = @_;
    my %d = map { $_ => 1 } @$r;
    my $c = scalar( keys(%d) );
    return $c;
}

#----
sub calc_compare_rate {
    my ( $old, $new ) = @_;
    $old ||= 0;
    $new ||= 0;
    my $diff = $new - $old;

    my $rate =
        ( $old == $new ) ? 0
      : ( $new == 0 )    ? -1
      : ( $old == 0 )    ? 1
      :                    $diff / $old;
    return wantarray ? ( $rate, $diff ) : $rate;
} ## end sub calc_compare_rate

sub format_percent {
    my ( $rate, $format ) = @_;
    $format ||= "%.2f%%";
    $format = "%d%%" if ( $rate == 0 || $rate == 1 );
    return sprintf( $format, 100 * $rate );
}

sub calc_rate {
    my ( $val, $sum ) = @_;
    return 0 unless ( $sum and $sum > 0 );
    $val ||= 0;

    my $rate = $val / $sum;
    return $rate;
} ## end sub calc_rate

#sub conv_hash_to_arrayref {
    #my ($hash) = @_;
    #my @data;
    #while ( my ( $k, $v ) = each %$hash ) {
        #my @temp = ($k);
        #while ( ref($v) eq 'HASH' ) {
            #while ( my ( $kt, $vt ) = each %$v ) {
                #push @temp, $kt;
            #}
            #$v = $vt;
        #}
        #push @temp, $v;
        #push @data, \@temp;
    #}
    #return \@data;
#} ## end sub conv_hash_to_ref

#sub get_compare_prefix {
    #my ($vary) = @_;
    #return ( $vary > 0 ? '+' : '' );
#} ## 
    
1;
