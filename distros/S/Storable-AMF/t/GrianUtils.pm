# vim: ts=8 et sw=4 sts=4
package GrianUtils;
use strict;
use warnings;
use Carp qw/carp croak/;
use Fcntl qw(:flock);
use File::Spec;
use Scalar::Util qw(refaddr reftype);
use List::Util qw(max); 
use Exporter qw(import);
use Carp qw(croak);
use warnings 'all';

our ( @EXPORT, @EXPORT_OK );
our $msg;
@EXPORT_OK = qw(ref_mem_safe my_readdir my_readfile loose $msg total_sv);

*total_sv = \&Storable::AMF::Util::total_sv;

sub loose(&) {
    my $sub  = shift;
    my $have = total_sv();
    my $delta;

    {
        my $c;
        &$sub() for 1;
    };
    return $delta unless $delta = $msg = total_sv() - $have;

    {
        my $c = &$sub();
    };
    return 0 if total_sv() - $have == $delta;
    return $delta unless $delta = $msg = total_sv() - $have;

    $have = total_sv();

    {
        my $c = &$sub();
    };
    return $delta = $msg = total_sv() - $have;
}


sub my_items {
    my $self      = shift;
    my $directory = shift;
    croak "GrianUtils::my_items list context required" unless wantarray;
    my @dir_content;
    @dir_content = GrianUtils->my_readdir( ($directory) );
    my %items;
    my %values;
    my %eval;

    for (@dir_content) {
        m/.*[\/\\](.*)\.(.*)/ and $items{$1}{$2} = $_ or next;
        my $val = $values{$1}{$2} = GrianUtils->my_readfile($_);
    }
    my @item = map $items{$_}, sort keys %items;

    # set name property
    $_->{ ( keys %$_ )[0] } =~ m/([-\.()\w]+)\./ and $_->{name} ||= $1 for @item;
    !$values{ $_->{name} } && warn "No name for '" . $_->{ ( keys %$_ )[0] } . "'" for @item;

    #read package if ext is pack
    for (@item) {
        if ( keys %$_ == 2 && $_->{'pack'} ) {
            my $val = $values{ $_->{name} } or next;
            %$_ = ( %$_, %{ _unpack( $val->{'pack'} ) } );
            $_->{dump} = $_->{eval} unless defined $_->{dump};
        }
        else {
            my $item = $_;
            $_ ne 'name' and $item->{$_} = $values{ $item->{name} }{$_} for keys %$item;
        }
    }

    @item = grep { defined $_->{dump} } @item;

    for my $item (@item) {
        my $eval = $item->{dump} ||= $item->{eval};
        no strict;
        $item->{obj} = eval $eval;
        use strict;
        $item->{eval} = $eval;
        croak "$item->{name}: $@" if $@;
        if ( defined $item->{xml} ) {
            $item->{eval_xml} = $item->{xml};
            $item->{obj_xml}  = eval $item->{xml};
            croak "$item->{name}: $@" if $@;
        }
        else {
            $item->{eval_xml} = $item->{eval};
            $item->{obj_xml}  = $item->{obj};
        }
    }
    return @item;
}

sub my_readdir {
    my $class   = shift;
    my $dirname = shift;
    my $option  = shift || 'abs';
    opendir my $SP, $dirname
        or die "Can't opendir $dirname for reading";
    if ( $option eq 'abs' ) {
        return map { File::Spec->catfile( $dirname, $_ ) } grep { $_ !~ m/^\.\.?$/ } readdir $SP;
    }
    elsif ( $option eq 'rel' ) {
        return map { $dirname . "/" . $_ } grep { $_ !~ m/^\./ } readdir $SP;
    }
    else {
        carp "unknown option: $option. Available options are 'abs' or 'rel'";
        return ();
    }
}

sub my_readfile {
    my $class = shift;
    my $file  = shift;
    my @dirs  = @_;
    my $buf;
    $file = File::Spec->catfile( @_, $file );
    open my $filefh, "<", $file
        or die "Can't open file '$file' for reading";
    binmode($filefh);
    flock $filefh, LOCK_SH;
    read $filefh, $buf, -s $filefh;
    flock $filefh, LOCK_UN;
    close($filefh);
    return $buf;
}

BEGIN {
    our $pack        = "(w/a)*";
    our @fixed_names = qw(eval amf0 amf3);

    sub _pack {
        my $hash = shift;
        my (@fixed) = delete @$hash{@fixed_names};

        #my $s = \ pack "N/aN/aN/a(N/aN/a)*", $eval, $amf0, $amf3, %$hash;
        my $s = \pack $pack, @fixed, %$hash;
        @$hash{@fixed_names} = (@fixed);
        return $$s;
    }

    sub _unpack {
        my ( @fixed, %rest );
        ( @fixed[ 0 .. $#fixed_names ], %rest ) = unpack $pack, $_[0];
        @rest{@fixed_names} = (@fixed);
        return \%rest;
    }
}

sub create_pack {
    my $class = shift;
    my $dir   = shift;
    my $name  = shift;
    my $value = shift;

    $dir =~ s/[\/\\]$//;
    my $pack_name = File::Spec->catfile( $dir, "$name.pack" );
    my $sname = $pack_name;
    $sname =~ s/\.pack$//;
    our %folder;

    $folder{$sname} = $value;
    delete $folder{$sname}{'pack'};
    open my $fh, ">", $pack_name or die "can't create $pack_name";
    binmode($fh);
    print $fh _pack( $folder{$sname} );
    close($fh);

}

sub abs2rel {
    my $class    = shift;
    my $abs_path = shift;
    my $base     = shift;
    $base     =~ s/[\\\/]$//;
    $base     =~ s/\\/\//g;
    $abs_path =~ s/\\/\//g;
    if ( $base eq '.' ) {
        $base     =~ s/^\.//g;
        $abs_path =~ s/^\.\///g;
        return "./$abs_path";
    }
    print STDERR "path='$abs_path' base='$base'\n";
    carp "Path can't transformed to relative: path='$abs_path' base='$base'" unless substr( $abs_path, 0, length($base) ) eq $base;
    return "." . substr( $abs_path, length($base) );
}

# not tested yet
sub rel2abs {
    my $class    = shift;
    my $rel_path = shift;
    my $base     = shift;
    $base     =~ s/[\\\/]$//;
    $rel_path =~ s/^\.\///;
    carp "Path isn't relative: path='$rel_path' base='$base'" if $rel_path =~ /^[\\\/]/;
    return File::Spec->catfile( $base, $rel_path );
}

sub _all_refs_addr {
    my $c = shift;
    while (@_) {
        my $item = shift;

        next unless refaddr $item;
        next if $$c{ refaddr $item};

        #print refaddr $item, "\n";
        $$c{ refaddr $item} = 1;
        if ( reftype $item eq 'ARRAY' ) {
            _all_refs_addr( $c, @$item );
        }
        elsif ( reftype $item eq 'HASH' ) {
            _all_refs_addr( $c, $_ );
        }
        elsif ( reftype $item eq 'SCALAR' ) {
        }
        elsif ( reftype $item eq 'REF' ) {
            _all_refs_addr( $c, $$item );
        }
        else {
            croak "Unsupported type " . reftype $item;
        }
    }
    return keys %$c;
}

sub ref_mem_safe {
    my $sub              = shift;
    my $count_to_execute = shift || 400;
    my $count_to_be_ok   = shift || 50;

    my $nu = -1;
    my @addresses;
    my %addr;
    my $old_max = 0;
    for ( my $round = 1; $round <= $count_to_execute; ++$round ) {
        my @seq = &$sub();
        push @seq, ( \my $b ), [], {}, [], {}, \my $a;
        my $new_max = max( _all_refs_addr( {}, @seq, ) );
        if ( $old_max < $new_max ) {
            $old_max = $new_max;
            $nu      = -1;
        }
        else {
            ++$nu;
        }
        return $round, $round if ( $nu > $count_to_be_ok );
        @seq = ();
    }
    return ( 0, "$nu/$count_to_be_ok, $count_to_execute" ) if wantarray;
    return 0;
}

sub my_create_file {
    my $class   = shift;
    my $file    = shift;
    my $content = shift;
    my $base    = shift;
    my $usage   = 'GrianUtils->my_create_file($file, $content, $base)...';
    warn "$usage: \$base not is option" unless $base;
    croak "$usage: double dot in \$file restricted" if $file =~ m/\.\./;
    $base ||= '.';
    carp "$usage: \$base --- ($base) is not a directory" unless -d $base;
    my @r = split "/", $file;
    my $lfile = pop @r;

    my $loc_folder = File::Spec->catfile( $base, @r );
    if ( -d -w $loc_folder ) {
        my $loc_file;
        open my $fh, ">", $loc_file = File::Spec->catfile( $base, $file )
            or croak "$usage: Can't create file($loc_file)";
        binmode($fh);
        print $fh $content;
        close($fh);
    }
    elsif ( -d _ ) {
        croak "$usage: Not writeable directory($loc_folder)";
    }
    else {
        # Generate path for

        my @folders;
        my $folder = $base;

        for my $r (@r) {
            $folder = File::Spec->catfile( $folder, $r );
            next if ( -d $folder );
            mkdir($folder)
                or croak "$usage: Can't create directory ($folder) for path($loc_folder)";
        }
        $class->my_create_file( $file, $content, $base );
    }
}

GrianUtils::T::import();

package GrianUtils::T;
no strict 'refs';

sub Dumper {
    require Data::Dumper;
    goto &Data::Dumper::Dumper;
}

sub import {
    *{ caller(1) . '::Dumper' } = \&Dumper if caller(1);
}

sub AUTOLOAD {
    require Data::Dumper;
    Data::Dumper->import('Dumper');
    goto &Dumper;
}

1;
