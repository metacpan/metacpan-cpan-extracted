# ABSTRACT: Reshape data like R
package SimpleR::Reshape;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(read_table write_table melt cast merge merge_file split_file arrange);

our $VERSION     = 0.09;
our $DEFAULT_SEP = ',';

use B::Deparse ();
use Encode;
use Encode::Locale;

sub read_table {
    my ( $txt, %opt ) = @_;

    $opt{sep}        //= $DEFAULT_SEP;
    $opt{skip_head}  //= 0;
    $opt{write_head} //= 0;
    $opt{write_sub} = write_row_sub( $opt{write_file}, %opt )
      if ( exists $opt{write_file} );
    $opt{return_arrayref} //= exists $opt{write_file} ? 0 : 1;

    my @data;

    my $deal_head_sub = sub {
        my ( $o, $h ) = @_;
        return unless ( $o->{write_head} );
        my $wh = ref( $o->{write_head} ) eq 'ARRAY' ? $o->{write_head} : $h;
        $o->{write_sub}->($wh) if ( exists $o->{write_sub} );
        push @data, $wh if ( $o->{return_arrayref} );
    };

    my $deal_row_sub = sub {
        my (@row) = @_;

        return if ( $opt{skip_sub} and $opt{skip_sub}->(@row) );
        my @s = $opt{conv_sub} ? $opt{conv_sub}->(@row) : @row;
        return unless (@s);

        if ( exists $opt{write_sub} ) {
            $opt{write_sub}->($_) for @s;
        }

        push @data, @s if ( $opt{return_arrayref} );
    };

    if ( -f $txt ) {
        my $read_format = $opt{charset} ? "<:$opt{charset}" : "<";
        open my $fh, $read_format, $txt;

        my $sh = ( $opt{skip_head} ) ? <$fh> : undef;
        $deal_head_sub->( \%opt, $sh );

        while ( my $d = <$fh> ) {
            chomp($d);
            my @temp = split $opt{sep}, $d, -1;
            $deal_row_sub->( \@temp );
        }
    }
    elsif ( ref($txt) eq 'ARRAY' ) {
        my $sh = ( $opt{skip_head} ) ? <$fh> : undef;
        $deal_head_sub->( \%opt, $sh );

        my $i = $opt{skip_head} ? 1 : 0;
        $deal_row_sub->( $txt->[$_] ) for ( $i .. $#$txt );
    }
    elsif ( ref($txt) eq 'HASH' ) {
        $deal_head_sub->( \%opt );
        while ( my ( $tk, $tr ) = each %$txt ) {
            $deal_row_sub->( $tk, $tr );
        }
    }

    return \@data;
}

sub write_row_sub {
    my ( $txt, %opt ) = @_;
    $opt{sep} ||= $DEFAULT_SEP;

    my $write_format = $opt{charset} ? ">:$opt{charset}" : ">";
    open my $fh, $write_format, $txt;

    my $w_sub = sub {
        my ($r) = @_;

        #支持嵌套一层ARRAY
        my @data = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @$r;

        print $fh join( $opt{sep}, @data ), "\n";
    };
    return $w_sub;
}

sub write_table {
    my ( $data, %opt ) = @_;
    my $w_sub = write_row_sub( $opt{file}, %opt );
    $w_sub->( $opt{head} ) if ( $opt{head} );
    $w_sub->($_) for @$data;
    return $opt{file};
}

sub melt {
    my ( $data, %opt ) = @_;

    my $names = $opt{names};

    if ( !exists $opt{measure} and ref( $opt{id} ) eq 'ARRAY' ) {
        my %s_id = map { $_ => 1 } map_arrayref_value( $opt{id} );
        $opt{measure} = [ grep { !exists $s_id{$_} } ( 0 .. $#$names ) ];
    }

    my $measure_names = $opt{measure_names} || [
        map_arrayref_value( $opt{measure}, $opt{names} )

          #@{$names}[@{$opt{measure}}]
    ];
    my $n = $#$measure_names;

    $opt{conv_sub} = sub {
        my ($r) = @_;
        my @id_cols = map_arrayref_value( $opt{id},      $r );
        my @values  = map_arrayref_value( $opt{measure}, $r );
        my @s =
          map { [ @id_cols, $measure_names->[$_], $values[$_] ] } ( 0 .. $n );
        return @s;
    };

    $opt{write_file} = $opt{melt_file};
    return read_table( $data, %opt );
}

sub map_arrayref_value {
    my ( $id, $arr ) = @_;
    my $t = ref($id);

    my @res =
        ( $t eq 'ARRAY' ) ? ( map { map_arrayref_value( $_, $arr ) } @$id )
      : ( $t eq 'CODE' ) ? $id->($arr)
      : ( !$t and $arr and $id =~ /^\-?\d+$/ ) ? $arr->[$id]
      :                                       $id;

    wantarray ? @res : $res[0];
}

sub cast {
    my ( $data, %opt ) = @_;
    $opt{sep} //= ',';

    #$opt{stat_sub} ||= sub { $_[0][0] };
    $opt{default_cell_value} //= 0;
    $opt{default_cast_value} //= $opt{default_cell_value};
    $opt{reduce_start_value} //= $opt{default_cell_value};

    # { id_k => m_k => [ value ] / reduce_value  }
    my ( $kv, $m_names ) = cast_cut_group( $data, %opt );
    $opt{measure_names} ||= $m_names;

    my @cast_data;
    while ( my ( $id_k, $r ) = each %$kv ) {
        my @row = split( $opt{sep}, $id_k, -1 );
        for my $m ( @{ $opt{measure_names} } ) {
            my $v =
                ( not exists $r->{$m} )   ? $opt{default_cast_value}
              : ( exists $opt{stat_sub} ) ? $opt{stat_sub}->( $r->{$m} )
              :                             $r->{$m};
            push @row, ref($v) eq 'ARRAY' ? @$v : $v;
        }
        push @cast_data, \@row;
    }

    if ( $opt{write_head} and ref( $opt{write_head} ) ne 'ARRAY' ) {
        $opt{id_names} ||= [ map_arrayref_value( $opt{id}, $opt{names} ) ];
        $opt{write_head} = $opt{result_names}
          || [ @{ $opt{id_names} }, @{ $opt{measure_names} } ];
    }

    read_table(
        \@cast_data,
        write_file      => $opt{cast_file},
        return_arrayref => $opt{return_arrayref},
        write_head      => $opt{write_head},
    );
}

sub cast_cut_group {
    my ( $data, %opt ) = @_;
    my %kv;
    my %measure_name;
    $opt{conv_sub} = sub {
        my ($r) = @_;

        my @id_v = map_arrayref_value( $opt{id}, $r );
        my $id_k = join( $opt{sep}, @id_v );

        my $m_k = map_arrayref_value( $opt{measure}, $r );
        $measure_name{$m_k} = 1;

        my $v = map_arrayref_value( $opt{value}, $r );
        if ( exists $opt{reduce_sub} ) {
            my $last_v = $kv{$id_k}{$m_k} // $opt{reduce_start_value};
            $kv{$id_k}{$m_k} = $opt{reduce_sub}->( $last_v, $v );
        }
        else {
            push @{ $kv{$id_k}{$m_k} }, $v;
        }
        return;
    };

    read_table(
        $data, %opt,
        return_arrayref => 0,
        write_head      => 0,
    );
    return ( \%kv, [ sort keys %measure_name ] );
}

sub merge {
    my ( $x, $y, %opt ) = @_;

    my @raw = (
        {
            data  => $x,
            by    => $opt{by_x} || $opt{by},
            value => $opt{value_x} || $opt{value} || [ 0 .. $#{ $x->[0] } ],
        },
        {
            data  => $y,
            by    => $opt{by_y} || $opt{by},
            value => $opt{value_y} || $opt{value} || [ 0 .. $#{ $y->[0] } ],
        },
    );

    my %main;
    my @cut_list;
    for my $i ( 0 .. $#raw ) {
        my ( $d, $by ) = @{ $raw[$i] }{qw/data by/};
        for my $row (@$d) {
            my $cut = join( $opt{sep}, @{$row}[@$by] );
            push @cut_list, $cut unless ( exists $main{$cut} );
            $main{$cut}[$i] = $row;
        }
    }
    @cut_list = sort @cut_list;

    my @result;
    for my $cut (@cut_list) {
        my @vs = split qr/$opt{sep}/, $cut, -1;
        for my $i ( 0 .. $#raw ) {
            my $d     = $main{$cut}[$i];
            my $vlist = $raw[$i]{value};

            push @vs, $d ? ( $d->[$_] // '' ) : '' for (@$vlist);
        }
        push @result, \@vs;
    }

    return \@result;
}

sub merge_file {
	# $y left join $x , with some coulumn
	my ( $x, $y, %opt ) = @_;
	$opt{default_cell_value} //= 0;
	$opt{sep} //= ',';
	$opt{merge_file} ||= "$y.merge";
    $opt{skip_head} //= 0;

	my $x_raw = {
		by    => $opt{by_x} || $opt{by},
		value => $opt{value_x} || $opt{value} ,
	};
	my %mem_x;
	read_table($x, 
			%opt, 
			return_arrayref=>0, 
			conv_sub => sub {
			my ($r) = @_;
			my $cut = join( $opt{sep}, @{$r}[@{$x_raw->{by}}] );
			$mem_x{$cut} = $x_raw->{value} ? [ map { $r->[$_] // $opt{default_cell_value} } @{$x_raw->{value}} ] : $r;
			});

    my @null_x;
    while(my ($mk, $mv) = each %mem_x){
        my $mv_n = scalar(@$mv);
        @null_x = ('') x $mv_n ;
        last;
    }

	my $y_raw = {
		by    => $opt{by_y} || $opt{by},
		value => $opt{value_y} || $opt{value} ,
	};

	read_table($y, 
			%opt,
			write_file => $opt{merge_file}, 
			return_arrayref=>0, 
			conv_sub => sub {
			my ($d) = @_;
			my $cut = join( $opt{sep}, @{$d}[@{$y_raw->{by}}] );
			my $vs = $y_raw->{value} ? [ map { $d->[$_] // $opt{default_cell_value} } @{$y_raw->{value}} ] : $d;
			push @$vs, $mem_x{$cut} ? @{$mem_x{$cut}} : @null_x;
            $_ //= '' for @$vs;
			return $vs;
			}, 
		  );

	return $opt{merge_file};
}

sub split_file {
    my ( $f, %opt ) = @_;
    $opt{split_file} ||= $f;
    $opt{return_arrayref} //= 0;
    $opt{sep} //= $DEFAULT_SEP;

    return split_file_line( $f, %opt ) if ( exists $opt{line_cnt} );

    my %exist_fh;

    $opt{conv_sub} = sub {
        my ($r) = @_;
        return unless ($r);

        my $k = join( $opt{sep}, map_arrayref_value( $opt{id}, $r ) );
        $k =~ s#[\\\/,]#-#g;

        if ( ! exists $exist_fh{$k} ) {
            my $file = "$opt{split_file}.".encode(locale => $k);
            my $write_format = $opt{charset} ? ">:$opt{charset}" : ">";
            open $exist_fh{$k}, $write_format, $file;
        }

        my $fhw = $exist_fh{$k};
        print $fhw join( $opt{sep}, @$r ), "\n";

        return;
    };

    read_table( $f, %opt );
}

sub split_file_line {
    my ( $file, %opt ) = @_;
    $opt{split_file} ||= $file;

    open my $fh, '<', $file;
    my $i      = 0;
    my $file_i = 1;
    my $fhw;
    while (<$fh>) {
        if ( $i == 0 ) {
            open $fhw, '>', "$opt{split_file}.$file_i";
        }
        print $fhw $_;
        $i++;
        if ( $i == $opt{line_cnt} ) {
            $i = 0;
            $file_i++;
        }
    }
    close $fh;
}

sub arrange {
    my ( $df, %opt ) = @_;
    my $d = read_table(
        $df,
        skip_head       => $opt{skip_head},
        sep             => $opt{sep},
        charset         => $opt{charset},
        return_arrayref => 1,
    );

    my $deparse = B::Deparse->new;
    my $s       = $deparse->coderef2text( $opt{arrange_sub} );
    my @data    = eval "sort $s \@\$d";

    read_table(
        \@data,
        %opt,
        write_file      => $opt{arrange_file},
        return_arrayref => $opt{return_arrayref},
        write_head      => $opt{write_head},
        head            => $opt{head},
    );
}

1;
