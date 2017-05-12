# ABSTRACT: Simple Call LIBSVM 
package SimpleCall::LIBSVM;
use strict;
use warnings;
use utf8;

#use SimpleR::Reshape;
use List::AllUtils qw/mesh/;

our $VERSION = 0.01;

sub new {
    my ( $self, %opt ) = @_;
    $opt{sep} ||= ',';
    bless {%opt}, __PACKAGE__;
}

sub predict_libsvm {
    my ( $self, $predict_data_f, $model_f, $svmout_f, %o ) = @_;
    $o{predict_opt} ||= '';
    system(
        qq[svm-predict $o{predict_opt} "$predict_data_f" "$model_f" "$svmout_f"]
    );
    return $svmout_f;
}

sub train_libsvm {
    my ( $self, $train_data_f, $model_f, %o ) = @_;
    $o{train_opt} ||= '-h 0';
    system(qq[svm-train $o{train_opt} "$train_data_f" "$model_f"]);
    return $model_f;
}

sub conv_libsvm_to_file {
    my ( $self, $src_file, %o ) = @_;
    %o = ( %$self, %o );
    return unless ( -f $o{libsvm_type} );

    $o{libsvm_out}   ||= "$src_file.libsvm.out";
    $o{predict_file} ||= "$src_file.libsvm.predict.csv";

    my $mem            = $self->read_libsvm_type( $o{libsvm_type} );
    my $mem_id_to_name = $mem->{id};

    open my $fhw, '>', $o{predict_file};
    open my $fh,  '<', $src_file;
    open my $fho, '<', $o{libsvm_out};

    my $head = <$fh>;
    chomp($head);
    print $fhw "predict,$head\n";
    while (<$fh>) {
        chomp;
        my $dst_i = <$fho>;
        chomp $dst_i;
        my $type_n = $mem_id_to_name->{$dst_i};
        print $fhw "$type_n,$_\n";
    }
    close $fho;
    close $fh;
    close $fhw;

    return $o{predict_file};
}

sub conv_file_to_libsvm {
    my ( $self, $f, %o ) = @_;
    %o = ( %$self, %o );

    open my $fh,  '<', $f;
    open my $fhw, '>', "$f.libsvm.data";

    my $head = <$fh>;
    chomp($head);
    my $head_opt = $self->read_column_info( $head, %o );

    my $n = 1;
    my %mem_type;
    if ( $o{libsvm_type} and -f $o{libsvm_type} ) {
        my $mem = $self->read_libsvm_type( $o{libsvm_type} );
        %mem_type = %{ $mem->{name} } if ($mem);
    }

    while (<$fh>) {
        chomp;
        my @data = split /$o{sep}/;
        $_ ||= 0 for @data;
        my %d = mesh @{ $head_opt->{name} }, @data;
        my $t = $d{ $head_opt->{type} };

        if ( !exists $mem_type{$t} ) {
            $mem_type{$t} = $n;
            $n++;
        }
        my $type_n = $mem_type{$t} || 0;

        my @m =
          map { "$head_opt->{name_id}{$_}:$d{$_}" } @{ $head_opt->{data} };
        print $fhw join( " ", $type_n, @m ), "\n";
    }
    close $fhw;
    close $fh;

    open my $fht, '>', "$f.libsvm.type";
    print $fht "$_,$mem_type{$_}\n" for sort keys(%mem_type);
    close $fht;

    return ( "$f.libsvm.data", "$f.libsvm.type" );
}

sub read_column_info {
    my ( $self, $head, %o ) = @_;

    my @col_head = split /$o{sep}/, $head;
    $o{name} = \@col_head;
    $o{num}  = scalar(@col_head);

    #type => xxx ,  data => []

    my @id = ( 1 .. $o{num} );
    my %name_id = mesh @col_head, @id;
    $o{name_id} = \%name_id;
    return \%o;
}

sub read_libsvm_type {
    my ( $self, $type_file ) = @_;
    return unless ( -f $type_file );

    my %mem_type;
    open my $fhr, '<', $type_file;
    while (<$fhr>) {
        chomp;
        my ( $name, $n ) = split ',';
        $mem_type{id}{$n}      = $name;
        $mem_type{name}{$name} = $n;
    }
    return \%mem_type;
}

1;
