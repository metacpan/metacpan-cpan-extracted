package Physics::CVD::Interface::OpenFOAM;
use strict;
use warnings;
use Carp;
use File::Path qw(make_path);

# ═══════════════════════════════════════════════════════════════════════════════
# OpenFOAM interface for CVD reactor-scale simulation
#
# Generates case directories for:
#   - reactingFoam (reacting gas flow)
#   - simpleFoam + scalarTransport (simplified transport)
#   - buoyantSimpleFoam (natural convection)
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        case_dir => $opts{case_dir} // './cvd_case',
        solver   => $opts{solver} // 'reactingFoam',
    }, $class;
    return $self;
}

sub generate_case {
    my ($self, %opts) = @_;
    my $dir = $self->{case_dir};
    make_path("$dir/constant/polyMesh", "$dir/system", "$dir/0");

    $self->_write_controlDict(%opts);
    $self->_write_fvSchemes;
    $self->_write_fvSolution;
    $self->_write_blockMeshDict(%opts);
    $self->_write_thermophysicalProperties(%opts);
    $self->_write_boundary_conditions(%opts);

    return $dir;
}

sub _write_controlDict {
    my ($self, %opts) = @_;
    my $end_time = $opts{end_time} // 1.0;
    my $dt = $opts{dt} // 1e-5;
    open my $fh, '>', "$self->{case_dir}/system/controlDict" or die $!;
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      controlDict;
}

application     $self->{solver};
startFrom       startTime;
startTime       0;
stopAt          endTime;
endTime         $end_time;
deltaT          $dt;
writeControl    adjustableRunTime;
writeInterval   0.1;
purgeWrite      5;
writeFormat      ascii;
writePrecision  8;
writeCompression off;
timeFormat       general;
timePrecision    6;
runTimeModifiable true;
EOF
    close $fh;
}

sub _write_fvSchemes {
    my ($self) = @_;
    open my $fh, '>', "$self->{case_dir}/system/fvSchemes" or die $!;
    print $fh <<'EOF';
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      fvSchemes;
}

ddtSchemes      { default Euler; }
gradSchemes     { default Gauss linear; }
divSchemes
{
    default         none;
    div(phi,U)      Gauss linearUpwind grad(U);
    div(phi,Yi_h)   Gauss linearUpwind grad(Yi_h);
    div(phi,K)      Gauss linear;
    div(((rho*nuEff)*dev2(T(grad(U))))) Gauss linear;
}
laplacianSchemes { default Gauss linear corrected; }
interpolationSchemes { default linear; }
snGradSchemes   { default corrected; }
EOF
    close $fh;
}

sub _write_fvSolution {
    my ($self) = @_;
    open my $fh, '>', "$self->{case_dir}/system/fvSolution" or die $!;
    print $fh <<'EOF';
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      fvSolution;
}

solvers
{
    "rho.*"     { solver diagonal; }
    p           { solver PCG; preconditioner DIC; tolerance 1e-6; relTol 0.01; }
    "(U|Yi|h)" { solver PBiCGStab; preconditioner DILU; tolerance 1e-6; relTol 0.1; }
}

PIMPLE
{
    nOuterCorrectors 2;
    nCorrectors      1;
    nNonOrthogonalCorrectors 0;
}
EOF
    close $fh;
}

sub _write_blockMeshDict {
    my ($self, %opts) = @_;
    my $radius = $opts{reactor_radius} // 0.075;  # m
    my $length = $opts{reactor_length} // 0.5;    # m
    my $gap    = $opts{gap} // 0.02;              # m (showerhead-wafer gap)

    open my $fh, '>', "$self->{case_dir}/system/blockMeshDict" or die $!;
    printf $fh <<'EOF', $radius, $gap, $length;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      blockMeshDict;
}

scale   1;

vertices
(
    (0 0 0)
    (%g 0 0)
    (%g %g 0)
    (0 %g 0)
    (0 0 %g)
    (%g 0 %g)
    (%g %g %g)
    (0 %g %g)
);

blocks ( hex (0 1 2 3 4 5 6 7) (20 10 40) simpleGrading (1 1 1) );

boundary
(
    inlet  { type patch; faces ((4 5 6 7)); }
    outlet { type patch; faces ((0 1 2 3)); }
    walls  { type wall;  faces ((0 4 7 3) (1 5 6 2) (0 1 5 4) (3 2 6 7)); }
    wafer  { type wall;  faces ((0 1 2 3)); }
);
EOF
    close $fh;
}

sub _write_thermophysicalProperties {
    my ($self, %opts) = @_;
    open my $fh, '>', "$self->{case_dir}/constant/thermophysicalProperties" or die $!;
    print $fh <<'EOF';
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      thermophysicalProperties;
}

thermoType
{
    type            hePsiThermo;
    mixture         multiComponentMixture;
    transport       sutherland;
    thermo          janaf;
    equationOfState perfectGas;
    specie          specie;
    energy          sensibleEnthalpy;
}
EOF
    close $fh;
}

sub _write_boundary_conditions {
    my ($self, %opts) = @_;
    my $T_wafer = $opts{temperature} // 700;
    my $T_inlet = $opts{inlet_temp} // 300;

    open my $fh, '>', "$self->{case_dir}/0/T" or die $!;
    printf $fh <<'EOF', $T_inlet, $T_wafer;
FoamFile
{
    version     2.0;
    format      ascii;
    class       volScalarField;
    object      T;
}

dimensions      [0 0 0 1 0 0 0];
internalField   uniform %g;

boundaryField
{
    inlet  { type fixedValue; value uniform %g; }
    wafer  { type fixedValue; value uniform %g; }
    walls  { type zeroGradient; }
    outlet { type zeroGradient; }
}
EOF
    close $fh;
}

sub run {
    my ($self, %opts) = @_;
    my $np = $opts{processors} // 1;
    my $dir = $self->{case_dir};

    system("cd $dir && blockMesh > log.blockMesh 2>&1") == 0
        or carp "blockMesh failed";

    if ($np > 1) {
        system("cd $dir && decomposePar > log.decomposePar 2>&1");
        system("cd $dir && mpirun -np $np $self->{solver} -parallel > log.solver 2>&1");
    } else {
        system("cd $dir && $self->{solver} > log.solver 2>&1");
    }
    return $self;
}

1;
