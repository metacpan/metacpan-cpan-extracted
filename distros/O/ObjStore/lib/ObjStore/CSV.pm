use strict;

# This should be an entire module by itself.  It should also be 
# completely rewritten!

package ObjStore::CSV;
use Carp;
use ObjStore ':ADV';
use IO::File;
use vars qw(@EXPORT);
require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(print_csv parse_csv);

# do something about quoting XXX
# order-by asc/dec
# handle simple queries; constraints?
# also do sprintf style formats - anything in 2D
# you might want to do all the calculated fields in a single coderef
# GUI interface like Excel...
sub print_csv {
    my $top = shift;

    my $st = { 
	      fh => *STDOUT{IO},
	      sep => "\t",
	      endl => "\n",
	      title => 0,
	      row => 0,
	      skip => 0,
	      max => 15500,  #excel friendly?
	      calc => {},
	      cols => undef,
	      adapt_columns => 1,
	      # column ordering?
    };

    croak "print_csv: odd number of args (@_)" if @_ & 1;
    for (my $a=0; $a < @_; $a+=2) {
	my ($k,$v) = @_[$a,$a+1];
	croak "print_csv: unknown param '$k'" if !exists $st->{$k};
	$st->{$k} = $v;
    }

    my $skipsave = $st->{skip};
    my $typehead;

    my $dorow;
    $dorow = sub {
	my ($k,$v) = @_;
	if (!$st->{title}) {	#first row
	    ++ $st->{title};
	    $st->{cmap} = {};

	    # sort columns here
	    my @k;
	    if (blessed $v and $v->isa('ObjStore::AVHV')) {
		my $kmap = $v->[0];
		@k = grep(!/^_/, keys %$kmap);
	    } else {
		@k = keys %$v;
	    }
	    for my $k (@k, keys %{$st->{calc}}) { $st->{cmap}{$k} = -1 }

	    if (!$st->{cols}) {
		$st->{cols} = [sort keys %{$st->{cmap}}];
	    } else {
		$st->{adapt_columns} = 0;
	    }
		    
	    for (my $z=0; $z < @{$st->{cols}}; $z++) {
		$st->{cmap}{ $st->{cols}[$z] } = $z;
	    }
	    for my $k (keys %{$st->{cmap}}) { 
		delete $st->{cmap}{$k} if $st->{cmap}{$k} == -1;
	    }

	    $st->{fh}->print(join($st->{sep},$typehead,
				  @{$st->{cols}}).$st->{endl});
	}
	if (@_) {	#body row
	    ++ $st->{row};
	    my @z;
	    if (blessed $v and $v->isa('ObjStore::AVHV')) {
		my $kmap = $v->[0];
		while (my ($rk, $rx) = each %$kmap) {
		    next if $rk =~ m/^_/;
		    my $rv = $v->[$rx];
		    if ($st->{adapt_columns} and !exists $st->{cmap}{$rk}) {
			$st->{cmap}{$rk} = @{$st->{cols}};
			push(@{$st->{cols}}, $rk);
		    }
		    next if !exists $st->{cmap}{$rk};
		    $z[$st->{cmap}{$rk}] = ref $rv? "$rv" : $rv;
		}
	    } else {
		while (my ($rk, $rv) = each %$v) {
		    if ($st->{adapt_columns} and !exists $st->{cmap}{$rk}) {
			$st->{cmap}{$rk} = @{$st->{cols}};
			push(@{$st->{cols}}, $rk);
		    }
		    next if !exists $st->{cmap}{$rk};
		    $z[$st->{cmap}{$rk}] = ref $rv? "$rv" : $rv;
		}
	    }
	    while (my ($col,$sub) = each %{$st->{calc}}) {
		next if !exists $st->{cmap}{$col};
		$z[$st->{cmap}{$col}] = $sub->($v);
	    }
	    @z = map { defined $_? $_ : 'undef' } @z;
	    # calculated columns
	    $st->{fh}->print(join($st->{sep}, $k, @z).$st->{endl});

	} else {		#last row
	    $st->{fh}->print(join($st->{sep},$skipsave + $st->{row},
				  @{$st->{cols}}).$st->{endl});
	}
    };

#	$st->{fh}->print("No records.\n");

    if (reftype $top eq 'HASH') {
	$typehead = 'key';
	while (my($k,$v) = each %$top) {
	    if ($st->{skip}) { --$st->{skip}; next; }
	    $dorow->($k, $v);
	    last if $st->{row} > $st->{max}
	}
	$dorow->();

    } elsif (reftype $top eq 'ARRAY' or $top->isa('ObjStore::Index')) {
	$typehead = 'index';
	my $arlen = (blessed $top && $top->can("_count")? 
		     $top->_count() : scalar(@$top));
	for (my $x=0; $x < $arlen; $x++) {
	    if ($st->{skip}) { --$st->{skip}; next; }
	    my $r = $top->[$x];
	    $dorow->($x, $r);
	    last if $st->{row} > $st->{max};
	}
	$dorow->();

    } else {
	croak "convert_2csv($top): don't know how to convert";
    }
}

# use anonymous package? XXX
package ObjStore::CSV::Parser;

sub at {
    my ($o) = @_;
    my $file = $o->{file}? $o->{file} : 'STDIN';
    " at $file line $o->{line}";
}

sub line { shift->{line} }

package ObjStore::CSV;

sub parse_csv {
    my $st = bless {
	      fh => *STDIN{IO},
	      file => undef,
	      sep => "\t",
	      cols => [],
	      to => [],
	      undef_ok => 0,
	      line => 0,
		   }, 'ObjStore::CSV::Parser';
    croak "parse_csv: odd number of args (@_)" if @_ & 1;
    for (my $a=0; $a < @_; $a+=2) {
	my ($k,$v) = @_[$a,$a+1];
	croak "parse_csv: unknown param '$k'" if !exists $st->{$k};
	$st->{$k} = $v;
    }
    if ($st->{file}) {
	$st->{fh} = new IO::File;
	$st->{fh}->open($st->{file}) or die "open $st->{file}: $!";
    }
    my $fh = $st->{fh};
    my $split = "[$st->{sep}]+";
    my $to = ref $st->{to};
    while (defined(my $l = <$fh>)) {
	++ $st->{line};
	chomp($l);
	$l =~ s/^ $split//x;  # strip leading junk
	my @l = split(m/$split/, $l);  #should handle quoted sep chars XXX
	# strip quotes
	for my $e (@l) {
	    $e =~ s/^\"(.*)\"$/$1/;
	    $e =~ s/^\'(.*)\'$/$1/;
	}
	if (! @{$st->{cols}}) {
	    $st->{cols} = \@l;
	    next;
	}
	carp "Missing columns".$st->at
	    if !$st->{undef_ok} && @l < @{$st->{cols}};
	my %row;
	for (my $c=0; $c < @{$st->{cols}}; $c++) {
	    $row{ $st->{cols}[$c] } = $l[$c];
	}
	if ($to eq 'CODE') { $st->{to}->(\%row, $st); }
	elsif ($to eq 'ARRAY') { push(@{$st->{to}}, \%row); }
    }
    $st->{to};
}

1;
