package SVG::Shapefile;

use Geo::Shapelib;
use File::Basename;
use Compress::Zlib;
use DBI;
use CSS::Tiny;
use SVG;
use strict;
use warnings;

our $VERSION = '0.01';
=pod

=head1 NAME SVG::Shapefile

=head1 SYNOPSIS

	my $shp = SVG::Shapefile->new( %options );
	$shp->render('filename.svg');

=head1 METHODS

=head2 new( %args )

new() takes the following arguments:

=over 4

=item ShapeFile

Path to the ESRI shapefile to parse. The .shx and .dbf components
should be in the same directory.

=item PolygonID

If defined, the name of the column from the .dbf component that should
be used as the identifier for each polygon. If undefined, the ID
is borrowed directly from the shapefile.

=item DataFile

The XBase (DBF), Excel, or CSV file to read data values from.

=item DataTable

If DataFile is an Excel spreadsheet, the name of the worksheet
to read data values from.

=item KeyColumn

The column from DataFile containing the polygon IDs.

=item ValueColumn

The column from DataFile containing the values to be mapped.

=item Scale

A constant multiplier applied to all vertices in the ShapeFile.
Used to scale up ShapeFile coordinates to something displayable
in SVG. Defaults to 1,000,000 if not specified.

=item Colors

A list of two lists, each containing an [R, G, B] triplet. The
first triplet is the RGB color assigned to the minimum data value,
the second triplet is the color assigned to the maximum.

=back

=cut

sub new {
    my ($class, %args) = @_;
    $args{Scale}  ||= 1_000_000;
    $args{Colors} ||= [[255,255,255], [0,0,255]];
    my $self = bless \%args, ref($class) || $class;
    $self->shapefile if $self->{ShapeFile};
    $self->dataset if $self->{DataFile};
    return $self;	
}

sub shapefile {
    my $self = shift;
    return $self->{ShapeObj} if $self->{ShapeObj};

    $self->{ShapeFile} = shift if @_;

    my ($file, $path) = fileparse($self->{ShapeFile}, ".shp");
    $self->{ShapeObj} = Geo::Shapelib->new( "$path/$file" )
	or die "Can't load $path/$file: $!\n";

    $self->polygon_id( $self->{PolygonID} ) 
	if $self->{PolygonID};
    $self->group_by($self->{GroupBy}) if $self->{GroupBy};

    return $self->{ShapeObj};
}

sub polygon_id {
    my $self = shift;

    return $self->{KeyIndex} if defined $self->{KeyIndex};
    $self->{PolygonID} = shift if @_;
	
    my @names = $self->shape_columns;
    for my $i (0 .. $#names) {
	if (lc $names[$i] eq lc $self->{PolygonID}) {
	    $self->{KeyIndex} = $i;
	    last;
	}
    }
    return $self->{KeyIndex};
}


sub group_by {
	my $self = shift;
	$self->{GroupBy} = shift if @_;
	 my @names = $self->shape_columns;
    for my $i (0 .. $#names) { 
        if (lc $names[$i] eq lc $self->{GroupBy}) { 
            $self->{GroupIndex} = $i;
            last;
        }
    }
    return $self->{GroupIndex};
}

sub groups {
	my $self = shift;
	my $dbf = $self->dataset or return;
	# cant select distninct against some drivers 
	my $s = "select ".$self->{GroupBy}." from ".$self->{DataTable};	
	my $rows = $dbf->selectall_arrayref($s);
	my %groups = map {$_->[0] => 1} @$rows;  		
	return (keys %groups);
}

sub filter {
    my $self = shift;
    my $in = shift;
    my $out;
    my $filter = $self->{Filter} or return 1;
    foreach (@$filter) {
	$out = 1 if $_ eq $in;
    }
    return $out;
}

sub svg {
    my ($self) = @_;
    return $self->{SVG} if $self->{SVG};

    my ($min_x, $max_x, $min_y, $max_y, %shapes);
    my $scale = $self->{Scale};
    my $shp   = $self->shapefile;
    my $poly_id = $self->polygon_id;

    my $records = $shp->{ShapeRecords};
    my $shapes = $shp->{Shapes};
    my %groups;
    my $group_by = $self->group_by;
    for my $i (0 .. $#$shapes) {
	my $poly = $shapes->[$i];
	my @points;
	for my $vertex (@{$poly->{Vertices}}) {
	    my ($x, $y) = @$vertex;
	    $x = int( $x * $scale ); 
	    $y = int( $y * $scale );
	    $min_x = $x if not defined $min_x or $x < $min_x;
	    $max_x = $x if not defined $max_x or $x > $max_x;
	    $min_y = $y if not defined $min_y or $y < $min_y;
	    $max_y = $y if not defined $max_y or $y > $max_y;
	    next if @points and $points[-2] == $x and $points[-1] == $y;
	    push @points, $x, $y;
	}

	my $id = $poly->{ShapeId};
	my $poly_num = $records->[$i][$poly_id];
	$id = $poly_num if $poly_num; 
	$id =~ s/\W//gos;
	my $filter = $self->filter($id);
	next if not $filter;

	if (defined($group_by) 
	    and my $g_id = $records->[$i][$group_by]) {
		$g_id =~ s/\W//gos;
		$groups{$g_id}{$id} = join ",", @points;
	}
	else {
		push @{$shapes{$id}}, join ",", @points;
	}
    }
    my ($width,$height) = ($max_x-$min_x,$max_y-$min_y);	
    my $svg = SVG->new( viewBox => "$min_x -$max_y $width $height" );

    my $group = $svg->group(
        id => 'shapefile',
        transform => 'scale(1,-1)',
        style => {stroke => 'black', 'stroke-width' => 10, fill => 'none'},
    );

    while (my ($id, $set) = each %shapes) {
	for my $pts (@$set) {
	    $group->polygon( class => "id$id", points => $pts );
	}
    }
	
    my %subs; 
    foreach my $g (keys %groups) {
	$subs{$g} ||=  $group->group(id => $g);
	my $subgroup = $subs{$g}; 
	while (my ($id,$pts) = each %{ $groups{$g} }) { 
	    $subgroup->polygon( class => "id$id", points => $pts );		
	} 	        
    }	

    $self->{SVG} = $svg;
    return $svg;
}

sub render {
    my ($self, $svgfile) = @_;

    my ($base, $path, $ext) = fileparse( $svgfile, qr/\.svgz?/ );
    my $output = $self->svg->render;
    $output =~ s/(<svg )
		/<?xml-stylesheet href="$base.css" type="text\/css"?>\n$1/osx;

    open my($xml), ">", $svgfile
	or die "Can't write to $svgfile: $!\n";

    if ($svgfile =~ /gz$/io) {
	print $xml compress( $output, Z_BEST_COMPRESSION );
    } else {
	print $xml $output;
    }

    $self->stylesheet->write("$path/$base.css")
	if $self->stylesheet;
}

sub color_scale {
    my ($self, $val, $min, $max) = @_;
    my ($color1, $color2) = @{$self->{Colors}};
    my @target;
    $val = ($max == $min ? .5 : ($val - $min) / ($max - $min));
    $target[$_] = int( $color1->[$_] + ($color2->[$_] - $color1->[$_]) * $val )
	for 0 .. $#$color1;
    return \@target;
}

sub color {
    my ($self, $val) = @_;
    if (exists $self->{Colors}{$val}) {
	return $self->{Colors}{$val};
    } else {
	return;
    }
}

sub dataset {
    my $self = shift;
    return $self->{DBF} if $self->{DBF};

    $self->{DataFile} = shift if @_;
    $self->{DataTable} = shift if @_;
    return unless $self->{DataFile};

    my ($table, $path, $type) = fileparse($self->{DataFile}, qr/\..*/);
    my $connect = {
	".dbf" => "dbi:XBase:$path",
	".xls" => "dbi:Excel:file=$path/$table.xls",
	".csv" => "dbi:CSV:f_dir=$path" 
	} -> {$type};

    $self->{DataType} = $type;
    $self->{DataTable} ||= $table;
    $self->{DBF} = DBI->connect( $connect, undef, undef, {RaiseError => 1} );
    return $self->{DBF};
}

sub stylesheet {
    my $self = shift;
    return $self->{CSS} if $self->{CSS};

    my $dbf = $self->dataset or return;

    my $rows = $dbf->selectall_arrayref(qq{
	select $self->{KeyColumn}, $self->{ValueColumn} 
	  from $self->{DataTable} });

    my ($min, $max, %data);
    for my $row (@$rows) {
	my ($key, $val) = @$row;
	# $val =~ s/,//gos; # de-commify numeric values
	# next unless $val =~ /^[-+]?[\d\.]+$/o;
	# $data{$key} += $val;
	# $min = $data{$key} if not defined $min or $min > $data{$key};
	# $max = $data{$key} if not defined $max or $max < $data{$key};
	$data{$key} = $val;
    }

    my $style = CSS::Tiny->new;
    while (my ($key, $val) = each %data) {
	#  my $color = $self->color_scale( $val, $min, $max );
	my $color = $self->color($val) or next;
	my $rgb = join(",", @$color);

	$key =~ s/\W//gos; # clean up key names
	$style->{".id$key"}{fill} = "rgb($rgb)";
    }

    $self->{CSS} = $style;
    return $style;
}

sub shape_columns {
    my $self = shift;
    my $shp = $self->shapefile or return;
    my $names = $shp->{FieldNames};
    return @$names;
}

sub data_tables {
    my $self = shift;
    my $dbf = $self->dataset or return;
    my $st = $dbf->table_info;
    my $data = $st->fetchall_arrayref;
    return map( $_->[2], @$data );
}

sub data_columns {
    my $self = shift;
    my $dbf = $self->dataset or return;
    if ($self->{DataType} eq ".xls") {
	my $cols = $dbf->{xl_tbl}{$self->{DataTable}}{col_names}; # ugh!
	return grep( !/^COL_\d+_$/o, @$cols );
    } elsif ($self->{DataType} eq ".csv") {
	my $cols = $dbf->{csv_tables}{$self->{DataTable}}{col_names};
	return @$cols;
    } elsif ($self->{DataType} eq ".dbf") {
	return $dbf->{xbase_tables}{$self->{DataTable}}->field_names;
    } else {
	my $st = $dbf->column_info( undef, undef, $self->{DataTable}, '%' );
	my $data = $st->fetchall_arrayref({});
	return map( $_->[2], @$data );
    }
}

1;
