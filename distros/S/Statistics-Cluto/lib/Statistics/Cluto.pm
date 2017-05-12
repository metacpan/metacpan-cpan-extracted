package Statistics::Cluto;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Statistics::Cluto ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	CLUTO_CLFUN_CLINK
	CLUTO_CLFUN_CLINK_W
	CLUTO_CLFUN_CUT
	CLUTO_CLFUN_E1
	CLUTO_CLFUN_G1
	CLUTO_CLFUN_G1P
	CLUTO_CLFUN_H1
	CLUTO_CLFUN_H2
	CLUTO_CLFUN_I1
	CLUTO_CLFUN_I2
	CLUTO_CLFUN_MMCUT
	CLUTO_CLFUN_NCUT
	CLUTO_CLFUN_RCUT
	CLUTO_CLFUN_SLINK
	CLUTO_CLFUN_SLINK_W
	CLUTO_CLFUN_UPGMA
	CLUTO_CLFUN_UPGMA_W
	CLUTO_COLMODEL_IDF
	CLUTO_COLMODEL_NONE
	CLUTO_CSTYPE_BESTFIRST
	CLUTO_CSTYPE_LARGEFIRST
	CLUTO_CSTYPE_LARGESUBSPACEFIRST
	CLUTO_DBG_APROGRESS
	CLUTO_DBG_CCMPSTAT
	CLUTO_DBG_CPROGRESS
	CLUTO_DBG_MPROGRESS
	CLUTO_DBG_PROGRESS
	CLUTO_DBG_RPROGRESS
	CLUTO_GRMODEL_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_ASYMETRIC_LINKS
	CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
	CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS
	CLUTO_GRMODEL_NONE
	CLUTO_GRMODEL_SYMETRIC_DIRECT
	CLUTO_GRMODEL_SYMETRIC_LINKS
	CLUTO_MEM_NOREUSE
	CLUTO_MEM_REUSE
	CLUTO_MTYPE_HEDGE
	CLUTO_MTYPE_HSTAR
	CLUTO_MTYPE_HSTAR2
	CLUTO_OPTIMIZER_MULTILEVEL
	CLUTO_OPTIMIZER_SINGLELEVEL
	CLUTO_ROWMODEL_LOG
	CLUTO_ROWMODEL_MAXTF
	CLUTO_ROWMODEL_NONE
	CLUTO_ROWMODEL_SQRT
	CLUTO_SIM_CORRCOEF
	CLUTO_SIM_COSINE
	CLUTO_SIM_EDISTANCE
	CLUTO_SIM_EJACCARD
	CLUTO_SUMMTYPE_MAXCLIQUES
	CLUTO_SUMMTYPE_MAXITEMSETS
	CLUTO_TREE_FULL
	CLUTO_TREE_TOP
	CLUTO_VER_MAJOR
	CLUTO_VER_MINOR
	CLUTO_VER_SUBMINOR
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	CLUTO_CLFUN_CLINK
	CLUTO_CLFUN_CLINK_W
	CLUTO_CLFUN_CUT
	CLUTO_CLFUN_E1
	CLUTO_CLFUN_G1
	CLUTO_CLFUN_G1P
	CLUTO_CLFUN_H1
	CLUTO_CLFUN_H2
	CLUTO_CLFUN_I1
	CLUTO_CLFUN_I2
	CLUTO_CLFUN_MMCUT
	CLUTO_CLFUN_NCUT
	CLUTO_CLFUN_RCUT
	CLUTO_CLFUN_SLINK
	CLUTO_CLFUN_SLINK_W
	CLUTO_CLFUN_UPGMA
	CLUTO_CLFUN_UPGMA_W
	CLUTO_COLMODEL_IDF
	CLUTO_COLMODEL_NONE
	CLUTO_CSTYPE_BESTFIRST
	CLUTO_CSTYPE_LARGEFIRST
	CLUTO_CSTYPE_LARGESUBSPACEFIRST
	CLUTO_DBG_APROGRESS
	CLUTO_DBG_CCMPSTAT
	CLUTO_DBG_CPROGRESS
	CLUTO_DBG_MPROGRESS
	CLUTO_DBG_PROGRESS
	CLUTO_DBG_RPROGRESS
	CLUTO_GRMODEL_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_ASYMETRIC_LINKS
	CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
	CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS
	CLUTO_GRMODEL_NONE
	CLUTO_GRMODEL_SYMETRIC_DIRECT
	CLUTO_GRMODEL_SYMETRIC_LINKS
	CLUTO_MEM_NOREUSE
	CLUTO_MEM_REUSE
	CLUTO_MTYPE_HEDGE
	CLUTO_MTYPE_HSTAR
	CLUTO_MTYPE_HSTAR2
	CLUTO_OPTIMIZER_MULTILEVEL
	CLUTO_OPTIMIZER_SINGLELEVEL
	CLUTO_ROWMODEL_LOG
	CLUTO_ROWMODEL_MAXTF
	CLUTO_ROWMODEL_NONE
	CLUTO_ROWMODEL_SQRT
	CLUTO_SIM_CORRCOEF
	CLUTO_SIM_COSINE
	CLUTO_SIM_EDISTANCE
	CLUTO_SIM_EJACCARD
	CLUTO_SUMMTYPE_MAXCLIQUES
	CLUTO_SUMMTYPE_MAXITEMSETS
	CLUTO_TREE_FULL
	CLUTO_TREE_TOP
	CLUTO_VER_MAJOR
	CLUTO_VER_MINOR
	CLUTO_VER_SUBMINOR
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Statistics::Cluto::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

sub DESTROY {}

require XSLoader;
XSLoader::load('Statistics::Cluto', $VERSION);

# Preloaded methods go here.

our $MATRIX_TYPE_DENSE = 0;
our $MATRIX_TYPE_SPARSE = 1;

our $NO_OPTIMIZE_SOLUTION = 0;
our $OPTIMIZE_SOLUTION = 1;

sub new {
    my $class = shift;
    my $self = {
        nrows => 0,
        ncols => 0,
        nnz => 0,
        rowptr => [],
        rowind => [],
        rowval => [],

        # global (not method-specific) defaults
        simfun => CLUTO_SIM_COSINE(),
        cstype => CLUTO_CSTYPE_BESTFIRST(),
        rowmodel => CLUTO_ROWMODEL_NONE(),
        colprune => 1.0,
        nnbrs => 40,
        grmodel => CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT(),
        edgeprune => -1,
        vtxprune => -1,
        mincomponent => 5,
        kwayrefine => $NO_OPTIMIZE_SOLUTION,
        ntrials => 10,
        niter => 10,
        seed => time,
        dbglvl => 0,
        nclusters => 1,
        nfeatures => 5,

        pretty_format => 0,

        @_,
    };

    bless $self, $class;
    return $self;
}

sub set_options {
    my ($self, $opts) = @_;

    while (my ($key, $val) = each(%$opts)) {
        $self->{$key} = $val;
    }
}

#
# matrix loading functions
#

sub set_sparse_matrix {
    my ($self, $nrows, $ncols, $rowval) = @_;

    die ('number of rows does not match') if ($nrows != $#$rowval + 1);

    $self->{matrix_type} = $MATRIX_TYPE_SPARSE;
    $self->{nrows} = $nrows;
    $self->{ncols} = $ncols;
    $self->{nnz} = 0;

    my @rowptr = ();
    my @rowind = ();
    my @rowval = ();
    for (my $rowptr = 0; $rowptr < $nrows; $rowptr++) {
        my $row = $$rowval[$rowptr];
        push @rowptr, $#rowind + 1;
        for (my $j = 0; $j <= $#$row; $j+=2) {
            my $col = $$row[$j];
            die ("inappropriate col#$col in row#".($rowptr+1)) if ($col > $ncols);
            push @rowind, $col - 1;
            push @rowval, $$row[$j + 1];
            $self->{nnz} ++;
        }
    }
    push @rowptr, $#rowind + 1;
    $self->{rowptr} = \@rowptr;
    $self->{rowind} = \@rowind;
    $self->{rowval} = \@rowval;
}

sub set_raw_sparse_matrix {
    my ($self, $nrows, $ncols, $rowptr, $rowind, $rowval) = @_;

    # $$rowptr[$#$rowptr + 1] = $#$rowind + 1 if ($$rowptr[-1] != $#$rowind + 1);
    if ($$rowptr[-1] != $#$rowind + 1 or $#$rowptr != $nrows) {
        die('rowptr not appropriate');
    }

    $self->{matrix_type} = $MATRIX_TYPE_SPARSE;
    $self->{nrows} = $nrows;
    $self->{ncols} = $ncols;
    $self->{nnz} = $#$rowval + 1;

    $self->{rowptr} = $rowptr;
    $self->{rowind} = $rowind;
    $self->{rowval} = $rowval;
}

sub set_dense_matrix {
    my ($self, $nrows, $ncols, $rowval) = @_;

    die ('number of rows does not match') if ($nrows != $#$rowval + 1);

    $self->{matrix_type} = $MATRIX_TYPE_DENSE;
    $self->{nrows} = $nrows;
    $self->{ncols} = $ncols;
    $self->{nnz} = -1;

    my @rowval = ();
    for (my $i = 0; $i <= $#$rowval; $i++) {
        my $row = $$rowval[$i];
        die ('number of cols does not match: row #'.($i+1)) if ($#$row+1 != $self->{ncols});
        push @rowval, @$row;
    }
    $self->{rowval} = \@rowval;
}

sub set_dense_matrix_as_sparse {
    my ($self, $nrows, $ncols, $matrix) = @_;
    my $rowval = [];

    die ('number of rows does not match') if ($nrows != $#$matrix + 1);

    for my $row_n (0..$nrows-1) {
        die ('number of cols does not match: row #'.($row_n+1)) if ($#{$matrix->[$row_n]} + 1 != $ncols);
        $rowval->[$row_n] = [];
        for my $col_n (0..$ncols-1) {
            my $val = $matrix->[$row_n][$col_n];
            if ($val) {
                push @{$rowval->[$row_n]}, $col_n + 1;
                push @{$rowval->[$row_n]}, $val;
            }
        }
    }
    $self->set_sparse_matrix($nrows, $ncols, $rowval);
}


#
# API wrappers
#

sub VP_ClusterDirect {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{part} = [];

    # call xs
    &_VP_ClusterDirect($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{ntrials}, $self->{niter}, $self->{seed}, $self->{dbglvl}, $self->{nclusters}, $self->{part});

    return $self->{pretty_format} && $self->format_cluster
        || $self->{part};
}

sub VP_ClusterRB {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{part} = [];

    # call xs
    &_VP_ClusterRB($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{ntrials}, $self->{niter}, $self->{seed}, $self->{cstype}, $self->{kwayrefine}, $self->{dbglvl}, $self->{nclusters}, $self->{part});

    return $self->{pretty_format} && $self->format_cluster
        || $self->{part};
}

sub VA_Cluster {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_UPGMA();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{part} = [];
    $self->{ptree} = [];
    $self->{tsims} = [];
    $self->{gains} = [];

    # call xs
    &_VA_Cluster($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{tsims}, $self->{gains});

    return $self->{pretty_format} && {
        clusters => $self->format_cluster,
        tree => $self->format_tree
    }
        || map $self->{$_}, qw(part ptree tsims gains);
}

sub VA_ClusterBiased {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_UPGMA();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());
    $self->{npclusters} = int($self->{nrows}**.5);

    # init return values
    $self->{part} = [];
    $self->{ptree} = [];
    $self->{tsims} = [];
    $self->{gains} = [];

    # call xs
    &_VA_ClusterBiased($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{dbglvl}, $self->{npclusters}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{tsims}, $self->{gains});

    return $self->{pretty_format} && {
        clusters => $self->format_cluster,
        tree => $self->format_tree
    }
        || map $self->{$_}, qw(part ptree tsims gains);
}

sub SP_ClusterDirect {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    warn ("number of rows not equal to number of cols") if ($self->{nrows} != $self->{ncols});

    # init return values
    $self->{part} = [];

    # call xs
    &_SP_ClusterDirect($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{crfun}, $self->{ntrials}, $self->{niter}, $self->{seed}, $self->{dbglvl}, $self->{nclusters}, $self->{part});

    return $self->{pretty_format} && $self->format_cluster
        || $self->{part};
}

sub SP_ClusterRB {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    warn ("number of rows not equal to number of cols") if ($self->{nrows} != $self->{ncols});

    # init return values
    $self->{part} = [];

    # call xs
    &_SP_ClusterRB($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{crfun}, $self->{ntrials}, $self->{niter}, $self->{seed}, $self->{cstype}, $self->{kwayrefine}, $self->{dbglvl}, $self->{nclusters}, $self->{part});

    return $self->{pretty_format} && $self->format_cluster
        || $self->{part};
}

sub VP_GraphClusterRB {
    my $self = shift;

    # method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_CUT();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{part} = [];
    $self->{crvalue} = 0;

    # call xs
    my $rtn = &_VP_GraphClusterRB($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{grmodel}, $self->{nnbrs}, $self->{edgeprune}, $self->{vtxprune}, $self->{mincomponent}, $self->{ntrials}, $self->{seed}, $self->{cstype}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{crvalue});

    return $self->{pretty_format} && $self->format_cluster
        || [ $rtn, $self->{part}, $self->{crvalue} ];
}

sub SP_GraphClusterRB {
    my $self = shift;

    # method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_CUT();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{part} = [];
    $self->{crvalue} = 0;

    # call xs
    my $rtn = &_SP_GraphClusterRB($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{nnbrs}, $self->{edgeprune}, $self->{vtxprune}, $self->{mincomponent}, $self->{ntrials}, $self->{seed}, $self->{cstype}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{crvalue});

    return $self->{pretty_format} && $self->format_cluster
        || [ $rtn, $self->{part}, $self->{crvalue} ];
}

sub SA_Cluster {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_UPGMA();

    # init return values
    $self->{part} = [];
    $self->{ptree} = [];
    $self->{tsims} = [];
    $self->{gains} = [];

    # call xs
    &_SA_Cluster($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{crfun}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{tsims}, $self->{gains});

    return $self->{pretty_format} && {
        clusters => $self->format_cluster,
        tree => $self->format_tree 
    }
        || map $self->{$_}, qw(part ptree tsims gains);
}

sub V_BuildTree {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());
    $self->{treetype} ||= CLUTO_TREE_TOP();

    # init return values
    $self->{ptree} = [];
    $self->{tsims} = [];
    $self->{gains} = [];

    # call xs
    &_V_BuildTree($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{treetype}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{tsims}, $self->{gains});

    return $self->{pretty_format} && $self->format_tree
        || map $self->{$_}, qw(ptree tsims gains);
}

sub S_BuildTree {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    warn ("number of rows not equal to number of cols") if ($self->{nrows} != $self->{ncols});
    $self->{treetype} ||= CLUTO_TREE_TOP();

    # init return values
    $self->{ptree} = [];
    $self->{tsims} = [];
    $self->{gains} = [];

    # call xs
    &_S_BuildTree($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{crfun}, $self->{treetype}, $self->{dbglvl}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{tsims}, $self->{gains});

    return $self->{pretty_format} && $self->format_tree
        || map $self->{$_}, qw(ptree tsims gains);
}

sub V_GetGraph {
    my $self = shift;

    # set method-specific defaults
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values
    $self->{growptr} = [];
    $self->{growind} = [];
    $self->{growval} = [];

    # call xs
    &_V_GetGraph($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{grmodel}, $self->{nnbrs}, $self->{dbglvl}, $self->{growptr}, $self->{growind}, $self->{growval});

    return map $self->{$_}, qw(growptr growind growval);
}

sub S_GetGraph {
    my $self = shift;

    # set method-specific defaults

    # init return values
    $self->{growptr} = [];
    $self->{growind} = [];
    $self->{growval} = [];

    # call xs
    &_S_GetGraph($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{grmodel}, $self->{nnbrs}, $self->{dbglvl}, $self->{growptr}, $self->{growind}, $self->{growval});

    return map $self->{$_}, qw(growptr growind growval);
}

sub V_GetSolutionQuality {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());

    # init return values

    # call xs
    return &_V_GetSolutionQuality($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{crfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part});
}

sub S_GetSolutionQuality {
    my $self = shift;

    # set method-specific defaults
    $self->{crfun} ||= CLUTO_CLFUN_I2();
    warn ("number of rows not equal to number of cols") if ($self->{nrows} != $self->{ncols});

    # init return values

    # call xs
    return &_S_GetSolutionQuality($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{crfun}, $self->{nclusters}, $self->{part});
}

sub V_GetClusterStats {
    my $self = shift;

    # set method-specific defaults

    # init return values
    $self->{pwgts} = [];
    $self->{cintsim} = [];
    $self->{cintsdev} = [];
    $self->{izscores} = [];
    $self->{cextsim} = [];
    $self->{cextsdev} = [];
    $self->{ezscores} = [];

    # call xs
    &_V_GetClusterStats($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part}, $self->{pwgts}, $self->{cintsim}, $self->{cintsdev}, $self->{izscores}, $self->{cextsim}, $self->{cextsdev}, $self->{ezscores});

    return $self->{pretty_format} && $self->format_cluster_stats
        || map $self->{$_}, qw(pwgts cintsim cintsdev izscores cextsim cextsdev ezscores);
}

sub S_GetClusterStats {
    my $self = shift;

    # set method-specific defaults
    warn ("number of rows not equal to number of cols") if ($self->{nrows} != $self->{ncols});

    # init return values
    $self->{pwgts} = [];
    $self->{cintsim} = [];
    $self->{cintsdev} = [];
    $self->{izscores} = [];
    $self->{cextsim} = [];
    $self->{cextsdev} = [];
    $self->{ezscores} = [];

    # call xs
    &_S_GetClusterStats($self->{matrix_type}, $self->{nrows}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{nclusters}, $self->{part}, $self->{pwgts}, $self->{cintsim}, $self->{cintsdev}, $self->{izscores}, $self->{cextsim}, $self->{cextsdev}, $self->{ezscores});

    return $self->{pretty_format} && $self->format_cluster_stats
        || map $self->{$_}, qw(pwgts cintsim cintsdev izscores cextsim cextsdev ezscores);
}

sub V_GetClusterFeatures {
    my $self = shift;

    # init return values
    $self->{internalids} = [];
    $self->{internalwgts} = [];
    $self->{externalids} = [];
    $self->{externalwgts} = [];

    # call xs
    &_V_GetClusterFeatures($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part}, $self->{nfeatures}, $self->{internalids}, $self->{internalwgts}, $self->{externalids}, $self->{externalwgts});

    return $self->{pretty_format} && $self->format_cluster_features
        || map $self->{$_}, qw(internalids internalwgts externalids externalwgts);
}

sub V_GetClusterSummaries {
    my $self = shift;

    # set method-specific defaults
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());
    $self->{sumtype} ||= CLUTO_SUMMTYPE_MAXCLIQUES();

    # init return values
    $self->{r_nsum} = undef;
    $self->{r_spid} = [];
    $self->{r_swgt} = [];
    $self->{r_sumptr} = [];
    $self->{r_sumind} = [];

    # call xs
    &_V_GetClusterSummaries($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part}, $self->{sumtype}, $self->{nfeatures}, $self->{r_nsum}, $self->{r_spid}, $self->{r_swgt}, $self->{r_sumptr}, $self->{r_sumind});


    return $self->{pretty_format} && $self->format_cluster_summaries
        || map $self->{$_}, qw(r_nsum r_spid r_swgt r_sumptr r_sumind);
}

sub V_GetTreeStats {
    my $self = shift;

    # set method-specific defaults
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());
    warn ("ptree not set or size does not equal to 2*nclusters") if ($#{$self->{ptree}}+1 != $self->{nclusters}*2);

    # init return values
    $self->{pwgts} = [];
    $self->{cintsim} = [];
    $self->{cextsim} = [];

    # call xs
    &_V_GetTreeStats($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{pwgts}, $self->{cintsim}, $self->{cextsim});


    return $self->{pretty_format} && $self->format_tree_stats
        || map $self->{$_}, qw(pwgts cintsim cextsim);
}

sub V_GetTreeFeatures {
    my $self = shift;

    # set method-specific defaults
    $self->{colmodel} ||=
        ($self->{simfun} == CLUTO_SIM_CORRCOEF() ? CLUTO_COLMODEL_NONE() : CLUTO_COLMODEL_IDF());
    warn ("ptree not set or size does not equal to 2*nclusters")
        if ($#{$self->{ptree}}+1 != $self->{nclusters}*2);

    # init return values
    $self->{internalids} = [];
    $self->{internalwgts} = [];
    $self->{externalids} = [];
    $self->{externalwgts} = [];

    # call xs
    &_V_GetTreeFeatures($self->{matrix_type}, $self->{nrows}, $self->{ncols}, $self->{nnz}, $self->{rowptr}, $self->{rowind}, $self->{rowval}, $self->{simfun}, $self->{rowmodel}, $self->{colmodel}, $self->{colprune}, $self->{nclusters}, $self->{part}, $self->{ptree}, $self->{nfeatures}, $self->{internalids}, $self->{internalwgts}, $self->{externalids}, $self->{externalwgts});


    return $self->{pretty_format} && $self->format_tree_features
        || map $self->{$_}, qw(internalids internalwgts externalids externalwgts);
}




#
# for prertty_format option
#

sub format_cluster {
    my $self = shift;

    my $clusters = [];
    for my $i (0..$self->{nrows}-1) {
        push @{$clusters->[$self->{part}->[$i]]}, {
            row => $i,
            rowlabel => $self->{rowlabels}->[$i]
        } if ($self->{part}->[$i] >= 0);
    }
    return $clusters;

#        return [ map {
#            rowlabel => $self->{rowlabels}->[$_],
#            cluster => $self->{part}->[$_]
#        }, (0..$self->{nrows}-1)]
}

sub format_cluster_stats {
    my $self = shift;

    return {
        clusters => [ map {
            pwgt => $self->{pwgts}->[$_],
            cintsim => $self->{cintsim}->[$_],
            cintsdev => $self->{cintsdev}->[$_],
            cextsim => $self->{cextsim}->[$_],
            cextsdev => $self->{cextsdev}->[$_],
        }, (0..$self->{nclusters}-1) ],
        rows => [ map {
            rowlabel => $self->{rowlabels}->[$_],
            izscore => $self->{izscores}->[$_],
            exscore => $self->{ezscores}->[$_]
        }, (0..$self->{nrows}-1) ]
    }
}

sub format_cluster_features {
    my $self = shift;

    return [ map {
        descriptive =>
            [ map {
                internalid => $self->{internalids}->[$_],
                collabel => $self->{collabels}->[$self->{internalids}->[$_]],
                internalwgt => $self->{internalwgts}->[$_]
            }, (($_*$self->{nfeatures})..(($_ + 1)*$self->{nfeatures} - 1)) ],
        discriminating =>
            [ map {
                externalid => $self->{externalids}->[$_],
                collabel => $self->{collabels}->[$self->{externalids}->[$_]],
                externalwgt => $self->{externalwgts}->[$_]
            }, (($_*$self->{nfeatures})..(($_ + 1)*$self->{nfeatures} - 1)) ],
        }, (0..$self->{nclusters}-1)];
}

sub format_cluster_summaries {
    my $self = shift;

    return [ map {
        cluster => $self->{r_spid}->[$_],
        swgt => $self->{r_swgt}->[$_],
        features => [ map $self->{r_sumind}->[$_], ($self->{r_sumptr}->[$_]..($self->{r_sumptr}->[$_+1]-1)) ],
    },  (0..($self->{r_nsum}-1)) ];
}

sub format_tree {
    my $self = shift;

    return [ map {
        parent => $self->{ptree}->[$_],
        tsims => $self->{tsims}->[$_],
        gains => $self->{gains}->[$_]
    }, (0..$#{$self->{ptree}}-1) ];
}

sub format_tree_stats {
    my $self = shift;

    return [ map {
        cintsim => $self->{cintsim}->[$_],
        cextsim => $self->{cextsim}->[$_]
    }, (0..$self->{nclusters}*2-1) ];
}

sub format_tree_features {
    my $self = shift;

    return [ map
        [ map {
            descriptive =>
                [ map {
                    internalid => $self->{internalids}->[$_],
                    collabel => $self->{collabels}->[$self->{internalids}->[$_]],
                    internalwgt => $self->{internalwgts}->[$_]
                },
                  grep defined($self->{internalids}->[$_]),
                  (($_*$self->{nfeatures})..(($_ + 1)*$self->{nfeatures} - 1)) ],
            discriminating =>
                [ map {
                    externalid => $self->{externalids}->[$_],
                    collabel => $self->{collabels}->[$self->{externalids}->[$_]],
                    externalwgt => $self->{externalwgts}->[$_]
                },
                  grep defined($self->{externalids}->[$_]),
                  (($_*$self->{nfeatures})..(($_ + 1)*$self->{nfeatures} - 1)) ],
            }, ($_..$_+$self->{nclusters}-1)]
     , (0..$self->{nclusters}*2-1) ];
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You'd better edit it!


=head1 NAME

Statistics::Cluto - Perl binding for CLUTO

=head1 INSTALLATION

Download CLUTO from L<http://glaros.dtc.umn.edu/gkhome/views/cluto>.

Find C<libcluto.a> which matches your environment and place it under
your library path (or specify its path with LIBS option as shown below).

Then do:

   perl Makefile.PL [LIBS='-L/where/to/find/libcluto.a -lcluto']
   make
   make test
   make install

Tested with cluto-2.1.2/Darwin-i386, cluto-2.1.2/Darwin-ppc and
cluto-2.1.1/Linux-i686.


=head1 SYNOPSIS

   use Statistics::Cluto;
   use Data::Dumper;
   
   my $c = new Statistics::Cluto;
   
   $c->set_dense_matrix(4, 5, [
     [8, 8, 0, 3, 2],
     [2, 9, 9, 1, 4],
     [7, 6, 1, 2, 3],
     [1, 7, 8, 2, 1]
   ]);
   $c->set_options({
     rowlabels => [ 'row0', 'row1', 'row2', 'row3' ],
     collabels => [ 'col0', 'col1', 'col2', 'col3', 'col4' ],
     nclusters => 2,
     rowmodel => CLUTO_ROWMODEL_NONE,
     colmodel => CLUTO_COLMODEL_NONE,
     pretty_format => 1,
   });
   
   my $clusters = $c->VP_ClusterRB;
   print Dumper $clusters;
   
   my $cluster_features = $c->V_GetClusterFeatures;
   print Dumper $cluster_features;


=head1 DESCRIPTION

This is a perl binding for CLUTO.
Please refer to the CLUTO's manual sections 5.6 - 5.8 for details
of each function. Basically, Statistics::Cluto has all
corresponding methods for functions described in the manual.

=head2 loading matrix

Initial matrix can be set either via C<set_dense_matrix> or via
C<set_sparse_matrix> method.

   # loading 4x5 dense matrix
   #
   # 1 1 0 1 1
   # 1 0 0 1 0
   # 0 1 1 0 0
   # 0 0 1 0 0
   
   my $c = new Statistics::Cluto;
   my $nrows = 4;
   my $ncols = 5;
   my $rowval = [
     [1, 1, 0, 0, 1],
     [1, 1, 0, 1, 1],
     [1, 0, 1, 1, 0],
     [1, 0, 1, 0, 0]
   ];
   $c->set_dense_matrix($nrows, $ncols, $rowval);


   # loading 4x5 sparse matrix
   #
   # 1 1 0 1 1
   # 1 0 0 1 0
   # 0 1 1 0 0
   # 0 0 1 0 0
   
   my $c = new Statistics::Cluto;
   my $nrows = 4;
   my $ncols = 5;
   my $rowval = [
     [1, 1, 2, 1, 4, 1, 5, 1],
     [1, 1, 4, 1],
     [2, 1, 3, 1],
     [3, 1]
   ];
   $c->set_sparse_matrix($nrows, $ncols, $rowval)

Sparse matrix can also be set with C<set_raw_sparse_matrix>,
using the data format described in the manual section 3.3, Fig 16.

   # loading sparse matrix via set_raw_sparse_matrix()
   #
   # 1 1 0 1 1
   # 1 0 0 1 0
   # 0 1 1 0 0
   # 0 0 1 0 0
   
   my $c = new Statistics::Cluto;
   my $nrows = 4;
   my $ncols = 5;
   my $rowptr = [0, 4, 6, 8, 9];
   my $rowind = [0, 1, 3, 4, 0, 3, 1, 2, 2];
   my $rowval = [1, 1, 1, 1, 1, 1, 1, 1, 1];
   $c->set_raw_sparse_matrix($nrows, $ncols, $rowptr, $rowind, $rowval);

=head2 setting input parameters

Input parameters C<nrows>, C<ncols>, C<rowptr>, C<rowind>, C<rowval> are
set automatically when initial matrix is loaded. All other input
parameters should be set before calling clustering functions via
C<set_options> method. See sections 5.6 - 5.8 for necessary parameters.

   $c->set_options({
       rowlabels => ['row0', 'row1', 'row2', 'row3', 'row4'],
       collabels => ['col0', 'col1', 'col2', 'col3', 'col4'],
       nclusters => 2,
       nfeatures => 2,
       clfun => CLUTO_CLFUN_I2,
       treetype => CLUTO_TREE_TOP,
   });

=head2 calling functions

CLUTO's api functions described in the manual sections from 5.6 to 5.8 can be
called with methods of the same name, but without prefix "CLUTO_".

e.g. C<CLUTO_VP_ClusterDirect> (in section 5.6.1) is named C<VP_ClusterDirect>
in this package.

Routines with a single output parameter will return a single value / arrayref.
Routines with multiple output parameters will return an array, each member of
the array being the output parameters appearing in the same order as the manual.

   # suppose $c is initialized with 5x5 sparse matrix:
   #     col0 ... col4
   # row0: 2 2 0 2 2
   # row1: 2 1 0 1 4
   # row2: 0 2 5 0 0
   # row3: 0 1 6 0 0
   # row4: 2 1 0 3 4
   
   $c->set_options({
       rowlabels => ['row0', 'row1', 'row2', 'row3', 'row4'],
       collabels => ['col0', 'col1', 'col2', 'col3', 'col4'],
       nclusters => 2,
       nfeatures => 2,
   });
   my $part = $c->VP_ClusterDirect;
   
   # $part =   [
   #             '1',
   #             '1',
   #             '0',
   #             '0',
   #             '1'
   #           ];
   
   my ($internalids, $internalwgts, $externalids, $externalwgts) = $c->V_GetClusterFeatures;
   
   # $internalids =
   #           [
   #             '2',
   #             '0',
   #             '4',
   #             '0'
   #           ]
   # $internalwgts =
   #           [
   #             '1',
   #             '0',
   #             '0.598181843757629',
   #             '0.209491595625877'
   #           ]
   # $externalids =
   #           [
   #             '2',
   #             '4',
   #             '2',
   #             '4'
   #           ]
   # $externalwgts =
   #           [
   #             '0.5',
   #             '0.299090921878815',
   #             '0.5',
   #             '0.299090921878815'
   #           ]

Please refer to the manual for the details of the returned data structure.

When C<pretty_format> option is set to 1, results are returned in a single
hashref, and in a (hopefully) little bit more comprehensible way.
Meaning of the returned data should be pretty much self-explanatory.

   # with the same matrix and options as above...
   
   $c->set_options({ pretty_format => 1 });
   my $result = $c->VP_ClusterDirect;
   
   # $result =
   #         [
   #           [
   #             { 'row' => 2, 'rowlabel' => 'row2' },
   #             { 'row' => 3, 'rowlabel' => 'row3' }
   #           ],
   #           [
   #             { 'row' => 0, 'rowlabel' => 'row0' },
   #             { 'row' => 1, 'rowlabel' => 'row1' },
   #             { 'row' => 4, 'rowlabel' => 'row4' }
   #           ]
   #         ];
   
   $result = $c->V_GetClusterFeatures;
   
   # $result =
   #         [
   #           [
   #             {
   #               'discriminating' => [
   #                                     {
   #                                       'externalwgt' => '0.5',
   #                                       'collabel' => 'col2',
   #                                       'externalid' => 2
   #                                     },
   #                                     {
   #                                       'externalwgt' => '0.299090921878815',
   #                                       'collabel' => 'col4',
   #                                       'externalid' => 4
   #                                     }
   #                                   ],
   #               'descriptive' => [
   #                                  {
   #                                    'internalid' => 2,
   #                                    'internalwgt' => '1',
   #                                    'collabel' => 'col2'
   #                                  },
   #                                  {
   #                                    'internalid' => 0,
   #                                    'internalwgt' => '0',
   #                                    'collabel' => 'col0'
   #                                  }
   #                                ]
   #             },
   #             {
   #               'discriminating' => [
   #                                     {
   #                                       'externalwgt' => '0.5',
   #                                       'collabel' => 'col2',
   #                                       'externalid' => 2
   #                                     },
   #                                     {
   #                                       'externalwgt' => '0.299090921878815',
   #                                       'collabel' => 'col4',
   #                                       'externalid' => 4
   #                                     }
   #                                   ],
   #               'descriptive' => [
   #                                  {
   #                                    'internalid' => 4,
   #                                    'internalwgt' => '0.598181843757629',
   #                                    'collabel' => 'col4'
   #                                  },
   #                                  {
   #                                    'internalid' => 0,
   #                                    'internalwgt' => '0.209491595625877',
   #                                    'collabel' => 'col0'
   #                                  }
   #                                ]
   #             }
   #           ]
   #         ];

=head1 Exportable constants

  use Statistics::Cluto qw(:all)

will export all constants defined in C<cluto.h>. (Auto generated by
h2xs).
See section 5 of CLUTO's manual, or cluto.h for details.

  CLUTO_CLFUN_CLINK
  CLUTO_CLFUN_CLINK_W
  CLUTO_CLFUN_CUT
  CLUTO_CLFUN_E1
  CLUTO_CLFUN_G1
  CLUTO_CLFUN_G1P
  CLUTO_CLFUN_H1
  CLUTO_CLFUN_H2
  CLUTO_CLFUN_I1
  CLUTO_CLFUN_I2
  CLUTO_CLFUN_MMCUT
  CLUTO_CLFUN_NCUT
  CLUTO_CLFUN_RCUT
  CLUTO_CLFUN_SLINK
  CLUTO_CLFUN_SLINK_W
  CLUTO_CLFUN_UPGMA
  CLUTO_CLFUN_UPGMA_W
  CLUTO_COLMODEL_IDF
  CLUTO_COLMODEL_NONE
  CLUTO_CSTYPE_BESTFIRST
  CLUTO_CSTYPE_LARGEFIRST
  CLUTO_CSTYPE_LARGESUBSPACEFIRST
  CLUTO_DBG_APROGRESS
  CLUTO_DBG_CCMPSTAT
  CLUTO_DBG_CPROGRESS
  CLUTO_DBG_MPROGRESS
  CLUTO_DBG_PROGRESS
  CLUTO_DBG_RPROGRESS
  CLUTO_GRMODEL_ASYMETRIC_DIRECT
  CLUTO_GRMODEL_ASYMETRIC_LINKS
  CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
  CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
  CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
  CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
  CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
  CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
  CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
  CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS
  CLUTO_GRMODEL_NONE
  CLUTO_GRMODEL_SYMETRIC_DIRECT
  CLUTO_GRMODEL_SYMETRIC_LINKS
  CLUTO_MEM_NOREUSE
  CLUTO_MEM_REUSE
  CLUTO_MTYPE_HEDGE
  CLUTO_MTYPE_HSTAR
  CLUTO_MTYPE_HSTAR2
  CLUTO_OPTIMIZER_MULTILEVEL
  CLUTO_OPTIMIZER_SINGLELEVEL
  CLUTO_ROWMODEL_LOG
  CLUTO_ROWMODEL_MAXTF
  CLUTO_ROWMODEL_NONE
  CLUTO_ROWMODEL_SQRT
  CLUTO_SIM_CORRCOEF
  CLUTO_SIM_COSINE
  CLUTO_SIM_EDISTANCE
  CLUTO_SIM_EJACCARD
  CLUTO_SUMMTYPE_MAXCLIQUES
  CLUTO_SUMMTYPE_MAXITEMSETS
  CLUTO_TREE_FULL
  CLUTO_TREE_TOP
  CLUTO_VER_MAJOR
  CLUTO_VER_MINOR
  CLUTO_VER_SUBMINOR


=head1 SEE ALSO

http://glaros.dtc.umn.edu/gkhome/views/cluto

=head1 AUTHOR

Ikuhiro IHARA E<lt>tsukue@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ikuhiro IHARA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

