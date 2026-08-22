package Physics::Lithography::Interface::OpenFOAM;
use strict;
use warnings;
use Carp;
use File::Path qw(make_path);

# ═══════════════════════════════════════════════════════════════════════════════
# OpenFOAM interface for laser ablation fluid dynamics
#
# Generates cases for:
#   - interFoam (VOF melt pool + vapor plume)
#   - laserFoam / customized solvers
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        case_dir => $opts{case_dir} // './laser_case',
        solver   => $opts{solver} // 'interFoam',
    }, $class;
    return $self;
}

sub generate_case {
    my ($self, %opts) = @_;
    my $dir = $self->{case_dir};
    make_path("$dir/constant", "$dir/system", "$dir/0");

    $self->_write_controlDict(%opts);
    $self->_write_fvSchemes;
    $self->_write_fvSolution;
    return $dir;
}

sub _write_controlDict {
    my ($self, %opts) = @_;
    my $dt = $opts{dt} // 1e-10;
    my $end = $opts{end_time} // 1e-6;
    open my $fh, '>', "$self->{case_dir}/system/controlDict" or die $!;
    print $fh <<EOF;
FoamFile { version 2.0; format ascii; class dictionary; object controlDict; }
application     $self->{solver};
startFrom       startTime;
startTime       0;
stopAt          endTime;
endTime         $end;
deltaT          $dt;
writeControl    adjustableRunTime;
writeInterval   1e-8;
writeFormat      ascii;
timePrecision    10;
runTimeModifiable true;
adjustTimeStep  yes;
maxCo           0.5;
EOF
    close $fh;
}

sub _write_fvSchemes {
    my ($self) = @_;
    open my $fh, '>', "$self->{case_dir}/system/fvSchemes" or die $!;
    print $fh <<'EOF';
FoamFile { version 2.0; format ascii; class dictionary; object fvSchemes; }
ddtSchemes { default Euler; }
gradSchemes { default Gauss linear; }
divSchemes { default none; div(rhoPhi,U) Gauss linearUpwind grad(U); }
laplacianSchemes { default Gauss linear corrected; }
interpolationSchemes { default linear; }
snGradSchemes { default corrected; }
EOF
    close $fh;
}

sub _write_fvSolution {
    my ($self) = @_;
    open my $fh, '>', "$self->{case_dir}/system/fvSolution" or die $!;
    print $fh <<'EOF';
FoamFile { version 2.0; format ascii; class dictionary; object fvSolution; }
solvers
{
    p_rgh { solver PCG; preconditioner DIC; tolerance 1e-8; relTol 0.01; }
    U     { solver PBiCGStab; preconditioner DILU; tolerance 1e-6; relTol 0.1; }
    T     { solver PBiCGStab; preconditioner DILU; tolerance 1e-7; relTol 0.01; }
}
PIMPLE { nOuterCorrectors 2; nCorrectors 1; nNonOrthogonalCorrectors 1; }
EOF
    close $fh;
}

1;
