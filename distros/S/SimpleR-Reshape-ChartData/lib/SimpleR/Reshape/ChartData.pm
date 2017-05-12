# ABSTRACT: conv data for chart 
package SimpleR::Reshape::ChartData;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
read_chart_data_dim2
read_chart_data_dim3
read_chart_data_dim3_horizon
read_chart_data_dim3_scatter
);

our $VERSION = 0.05;

use SimpleR::Reshape qw/read_table melt/;
use SimpleR::Stat qw/uniq_arrayref conv_arrayref_to_hash sort_by_other_arrayref transpose_arrayref/;

sub make_chart_data {
    my ($h, $legend, $label) = @_;

    my @chart_data = map { [ @{ $h->{$_} }{@$label} ] } @$legend;
    return \@chart_data;
}

sub make_chart_data_scatter {
    my ($h, $legend, $label) = @_;

    my @chart_data = map { 
    my $r = $h->{$_};
    my @k=keys %$r;
    my @d = map { $r->{$_} } @k;
    [ \@k, \@d ] 
    } 
    @$legend;
    return \@chart_data;
}

sub read_chart_data_dim3_scatter {
    my ( $d, %opt ) = @_;
    $opt{chart_data_sub} ||= \&make_chart_data_scatter;
    read_chart_data_dim3($d, %opt);
}

sub read_chart_data_dim3_horizon {
    my ( $d, %opt ) = @_;

    my $r = read_table( $d, %opt ); 
    delete($opt{conv_sub});#conv_sub在读入时生效

    $xr = melt( $r, id => $opt{label}, measure => $opt{legend}, names=> $opt{names}, return_arrayref=> 1,  );
    delete($opt{names}); #names在转换时生效

    return read_chart_data_dim3( $xr, 
        %opt, 
        label => [0], 
        legend => [1], 
        data=> [2] ,
        #legend_sort => $opt{legend_sort}, 
        #label_sort => $opt{label_sort}, 
    );
}

sub read_chart_data_dim2 {
    my ($d, %opt) = @_;

    $opt{legend} = $opt{label};
    $opt{legend_sort} = $opt{label_sort};
    $opt{legend_remember_order} = $opt{label_remember_order};
    my ($res, %res_opt) = read_chart_data_dim3($d, %opt); 
    my @data = map { $res->[$_][$_] } (0 .. $#$res);

    return (\@data, %res_opt);
}

sub read_chart_data_dim3 {
    my ( $d, %opt ) = @_;
    $opt{legend_remember_order} //= 1;
    $opt{label_remember_order} //= 1;
    $opt{chart_data_sub} ||= \&make_chart_data;

    my $r = read_table( $d, %opt );
    my $h = conv_arrayref_to_hash( $r, 
        [ $opt{legend}, $opt{label} ], $opt{data}, 
        remember_key_order => 1, 
    );

    my @legend_fields = $opt{legend_sort} ? @{ $opt{legend_sort} } : 
            $opt{legend_remember_order} ?  keys(%$h) : sort keys(%$h);

    my $label_uniq = uniq_arrayref([ map { keys(%{$h->{$_}}) } @legend_fields ],
        #remember_key_order => 1, 
        remember_key_order => $opt{label_remember_order}, 
    );
    my @label_fields = $opt{label_sort} ? @{ $opt{label_sort} } : 
        #$opt{label_remember_order} ?  @$label_uniq : sort @$label_uniq;
        @$label_uniq;

    #my @chart_data = map { [ @{ $h->{$_} }{@label_fields} ] } @legend_fields;
    my $chart_data = $opt{chart_data_sub}->($h, \@legend_fields, \@label_fields);

    for my $c (@$chart_data) {
        $_ ||= 0 for @$c;
    }

    my $label_ref = \@label_fields;
    if($opt{resort_label_by_chart_data_map}){
        my $tc = transpose_arrayref($chart_data);
        ($label_ref, $tc_new) = sort_by_other_arrayref(\@label_fields, $tc, 
           $opt{resort_label_by_chart_data_map},
           $opt{resort_label_by_chart_data_sort}
       );
        $chart_data = transpose_arrayref($tc_new);
    }

    return (
        $chart_data, 
        label  => $label_ref, 
        legend => \@legend_fields,
    );
}

1;
