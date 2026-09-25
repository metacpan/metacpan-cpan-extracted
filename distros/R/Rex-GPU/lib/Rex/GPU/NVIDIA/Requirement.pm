# ABSTRACT: What NVIDIA driver a GPU generation needs (experimental)

package Rex::GPU::NVIDIA::Requirement;
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use namespace::autoclean;

my %KERNEL_MODULES = map { $_ => 1 } qw( open proprietary either );


has generation => ( is => 'ro' );


has kernel_module => (
  is      => 'ro',
  default => 'either',
  isa     => sub {
    croak __PACKAGE__.'->kernel_module must be open, proprietary or either, not '
      .( defined $_[0] ? "'".$_[0]."'" : 'undef' )
      unless defined $_[0] && $KERNEL_MODULES{ $_[0] };
  }
);


has min_branch => ( is => 'ro', isa => \&_check_branch );
has max_branch => ( is => 'ro', isa => \&_check_branch );

sub _check_branch {
  my ( $branch ) = @_;
  croak __PACKAGE__.': a driver branch is an integer like 580, not '."'".$branch."'"
    if defined $branch && $branch !~ /^\d+\z/;
}


has device_id => (
  is  => 'ro',
  isa => sub {
    croak __PACKAGE__.'->device_id must be four lowercase hex digits, not '."'".$_[0]."'"
      if defined $_[0] && $_[0] !~ /^[0-9a-f]{4}\z/;
  }
);


has name    => ( is => 'ro' );
has members => ( is => 'ro', default => sub { [] } );


has compute => ( is => 'ro' );

sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.': min_branch '.$self->min_branch.' is above max_branch '
    .$self->max_branch.': no driver branch can satisfy that'
    if defined $self->min_branch && defined $self->max_branch
      && $self->min_branch > $self->max_branch;
}


# The rows, and where they come from (moved here from Rex::GPU::Detect, karr
# #16 and #26). The compute flag decides Rex::GPU::Detect::_is_nvidia_compute
# before any name rule (karr #45, #54). Maintainer decision (karr #54): every
# GPU usable for AI is compute -- MX, GT and GTX 9xx with 2 GB included -- as
# long as a current driver branch supports it; the criterion is the
# generation, not the marketing name. So Maxwell through Blackwell Ultra carry
# compute => 1 and the Kepler-or-older row compute => 0 (skipped with a
# warning, not a die, before the PCI class rule (karr #55): gpu_setup /
# Rex::Rancher gpu => 1 keep going without the old card, a K80 included). An ID no row covers (0x3000+
# except Blackwell Ultra) has no verdict; Detect uses its name rules and its
# unknown-model default compute => 0 there.
#
# Checked 2026-09-24 against NVIDIA's supportedchips READMEs (Linux-x86_64
# 615.71.09, 580.95.05, 580.126.09, 550.163.01, 535.247.01) and pci.ids of
# 2026-09-24:
#   * 580.95.05 / 580.126.09 "current" list starts at 1340: every ID of the
#     615 legacy_580 list (1340..1DF6) is current there -- incl. Maxwell Gen1
#     GM107/GM108: GTX 750 Ti 1380, GTX 745 1382, 940MX 134D, MX130 174D,
#     MX110 174E -- except 137D (GeForce 940A, subsystem entry only) and 1DF5
#     (V100-SXM2-16GB), which only the 615 legacy_580 list names.
#   * No legacy_470-or-older ID is >= 1340; no current/legacy_580 ID < 1340.
#   * pci.ids: no 10de ID >= 1340 carries a Kepler-or-older codename (GK, GF,
#     GT2xx, G8x/G9x, NVxx), and no Maxwell-or-newer codename sits below 1340
#     except HD-audio functions (PCI class 0403, never read by detection).
#     pci.ids does name two Kepler IDs like Maxwell/Pascal products -- 0FC5
#     "GK107 [GeForce GT 1030]", 11C7 "GK106 [GeForce GTX 750 Ti]" -- which is
#     why the ID row decides before any name rule.
#
# Blackwell (karr #16): NO proprietary kernel module — NVIDIA's open GPU
# kernel modules are the only ones that bind — on every architecture, x86_64
# included. Source: the supported-GPU table in NVIDIA's open-gpu-kernel-modules
# README.md (github.com/NVIDIA/open-gpu-kernel-modules, driver 615.71.09). In
# that table the last pre-Blackwell (Ada) ID is 28F8, and every listed ID from
# 2901 up to 2F58 is Blackwell: B200 (2901, 2909), GB200 (2941), GeForce RTX
# 50xx desktop/laptop and RTX PRO Blackwell (2B85..2F58), GB10 (2E12).
# 0x2900-0x2FFF is therefore taken as a block: an unlisted ID inside it is
# post-Ada silicon and gets the open module (which supports every GPU from
# Turing on). Blackwell Ultra (B300 3182, GB300 31C2/31C3) is listed
# explicitly, NOT as a block — whatever else lands at 0x3000+ is unknown.
# min_branch 570 / 580: the first branch with Blackwell / Blackwell Ultra
# support (research for epic karr #25).
#
# GB10 (2E12, DGX Spark) is the exception inside the Blackwell block: min 580
# (karr #33, checked 2026-09-23 against NVIDIA's primary sources). 2E12 is
# absent from the open-gpu-kernel-modules README.md of every 570.x and 575.x
# tag and of 580.65.06 .. 580.105.08; it first appears in tag 580.119.02
# ("NVIDIA GB10 | 2E12 10DE 21EC"), and is in 580.126.09, 590.48.01, 595.44.02
# and 615.71.09 -- but NOT in 590.44.01. The aarch64 driver README
# (us.download.nvidia.com/XFree86/aarch64/<ver>/README/supportedchips.html)
# agrees: absent in 580.95.05 and 590.44.01, present in 580.119.02 and
# 590.48.01. A branch-granular row cannot express "580.119.02 or newer".
#
# Pre-Turing (karr #26). Source: the legacy sections of NVIDIA's
# supportedchips README (driver 615.71.09, us.download.nvidia.com/XFree86/
# Linux-x86_64/615.71.09/README/supportedchips.html), checked 2026-09-23:
#   * "current" list: lowest ID 1E02 (TITAN RTX, Turing). No current ID < 1E02.
#   * 580.xx legacy list (Maxwell/Pascal/Volta): exactly 1340..1DF6, e.g.
#     Tesla M60 13F2, M40 17FD, P100 15F7/15F8, P40 1B38, P4 1BB3, TITAN V
#     1D81, V100 1DB1/1DB4-1DB6, V100S 1DF6. Proprietary kernel module only —
#     the open module needs GSP, which these chips lack — and 580 is their last
#     branch (595+ dropped them).
#   * 470.xx list (Kepler): 0FC6..12BA. The 390.xx (Fermi) list interleaves
#     with it (1040..1251) and goes down to 06C0; older legacy lists reach
#     down to 0020. No list has an ID in 12BB..133F or 1DF7..1E01.
# So every ID below 1340 is Kepler or older and no driver newer than 470
# supports it: one block, not a Kepler-only range, so a Fermi Tesla (C2050
# 06D1, M2090 1091) is rejected too. 1340..1DF6 is taken as a block like the
# Blackwell one: an unlisted ID inside it is Maxwell..Volta silicon.
#
# Turing, Ampere, Ada, Hopper (karr #54): 1DF7..28FF, one block like the
# others. The 615.71.09 current list covers 1E02 (TITAN RTX) .. 28F8 in it,
# with gaps; nothing in 1DF7..1E01 is listed anywhere. The row sets no
# constraint (either module, no bounds -- the driver selection these GPUs got
# before they had a row); it exists for the compute flag and the label.
#
# Everything else — the gaps above 2FFF and any future ID — has no row:
# either kernel module, no bounds, no compute verdict.
sub generations {
  return (
    { generation => 'Blackwell', first => 0x2e12, last => 0x2e12,       # GB10, see above
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Blackwell', first => 0x2900, last => 0x2fff,       # GB100/GB102, GB20x, GB10
      kernel_module => 'open', min_branch => 570, compute => 1 },
    { generation => 'Blackwell Ultra', first => 0x3182, last => 0x3182, # B300 SXM6 AC
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Blackwell Ultra', first => 0x31c2, last => 0x31c3, # GB300
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Turing/Ampere/Ada/Hopper', first => 0x1df7, last => 0x28ff,
      compute => 1 },
    { generation => 'Maxwell/Pascal/Volta', first => 0x1340, last => 0x1df6,
      kernel_module => 'proprietary', max_branch => 580, compute => 1 },
    { generation => 'Kepler or older', first => 0x0000, last => 0x133f,
      kernel_module => 'proprietary', max_branch => 470, compute => 0 }
  );
}


sub for_device_id {
  my ( $self, $device_id ) = @_;
  return ( ref $self || $self )->new( $self->_lookup( $device_id ) );
}

sub from_gpu {
  my ( $self, $gpu ) = @_;
  croak __PACKAGE__.'->from_gpu needs a GPU hashref from Rex::GPU::Detect::detect'
    unless ref $gpu eq 'HASH';
  return ( ref $self || $self )->new(
    $self->_lookup( $gpu->{device_id} ),
    defined $gpu->{name} ? ( name => $gpu->{name} ) : ()
  );
}

# Constructor arguments for a device ID. The format check is the one
# Rex::GPU::Detect used before this table existed, kept as it was so the
# wrappers there return exactly what they did.
sub _lookup {
  my ( $self, $device_id ) = @_;
  return () unless defined $device_id && $device_id =~ /^[0-9a-f]{4}$/i;
  my $id = hex $device_id;
  my %args = ( device_id => lc substr( $device_id, 0, 4 ) );
  for my $row ( $self->generations ) {
    croak __PACKAGE__.'->generations: every row needs first and last'
      unless defined $row->{first} && defined $row->{last};
    next unless $id >= $row->{first} && $id <= $row->{last};
    return (
      %args,
      generation    => $row->{generation},
      kernel_module => $row->{kernel_module} // 'either',
      defined $row->{min_branch} ? ( min_branch => $row->{min_branch} ) : (),
      defined $row->{max_branch} ? ( max_branch => $row->{max_branch} ) : (),
      defined $row->{compute} ? ( compute => $row->{compute} ? 1 : 0 ) : ()
    );
  }
  return %args;
}


sub satisfied_by {
  my ( $self, $source ) = @_;
  return defined $self->why_not( $source ) ? 0 : 1;
}

sub why_not {
  my ( $self, $source ) = @_;
  croak __PACKAGE__.'->satisfied_by needs a source hashref { kernel_module, branch }'
    unless ref $source eq 'HASH';
  my ( $branch, $floor ) = @{ $source }{qw( branch branch_at_least )};
  for my $n ( $branch, $floor ) {
    croak __PACKAGE__.'->satisfied_by: branch must be an integer like 580, not '."'".$n."'"
      if defined $n && $n !~ /^\d+\z/;
  }

  if ( $self->kernel_module ne 'either' ) {
    my $module = $source->{kernel_module};
    return ( defined $module ? $module : 'unknown' ).' kernel module, the '
        .$self->kernel_module.' one is needed'
      unless defined $module && $module eq $self->kernel_module;
  }
  my ( $min, $max ) = ( $self->min_branch, $self->max_branch );
  return unless defined $min || defined $max;

  if ( defined $branch ) {
    return 'branch '.$branch.' is older than '.$min if defined $min && $branch < $min;
    return 'branch '.$branch.' is newer than '.$max if defined $max && $branch > $max;
    return;
  }
  return 'driver branch not known, '.( defined $min ? $min.' or newer' : $max.' or older' )
      .' is needed'
    unless defined $floor;
  return 'installs the newest branch it carries, which can be newer than '.$max
    if defined $max;
  return 'installs the newest branch it carries, known only to be '.$floor
      .' or newer; '.$min.' is needed'
    if $floor < $min;
  return;
}


sub intersect {
  my ( $self, @requirements ) = @_;
  unshift @requirements, $self if ref $self;
  my @members = $self->_members_of( @requirements );
  return $requirements[0] if @requirements == 1;

  my @conflicts = $self->conflicts( @members );
  croak __PACKAGE__.'->intersect: no single NVIDIA driver supports all GPUs on this host: '
    .join( '; ', @conflicts )
    if @conflicts;

  my %module = map { $_->kernel_module => 1 } @members;
  my ( $lower, $upper ) = $self->_bounds( @members );
  my $class = ref $self || $self;
  return $class->new(
    kernel_module => $module{open}        ? 'open'
                   : $module{proprietary} ? 'proprietary'
                   :                        'either',
    $lower ? ( min_branch => $lower->min_branch ) : (),
    $upper ? ( max_branch => $upper->max_branch ) : (),
    members => \@members
  );
}

sub conflicts {
  my ( $self, @requirements ) = @_;
  unshift @requirements, $self if ref $self;
  my @members = $self->_members_of( @requirements );

  my %by_module;
  push @{ $by_module{ $_->kernel_module } }, $_ for @members;
  my ( $lower, $upper ) = $self->_bounds( @members );

  my @conflicts;
  push @conflicts, join( ', ', map { $_->who } @{ $by_module{open} } )
      .' need'.( @{ $by_module{open} } == 1 ? 's' : '' ).' the open kernel module, but '
      .join( ', ', map { $_->who } @{ $by_module{proprietary} } )
      .' need'.( @{ $by_module{proprietary} } == 1 ? 's' : '' ).' the proprietary one'
    if $by_module{open} && $by_module{proprietary};
  push @conflicts, $lower->who.' needs driver branch '.$lower->min_branch
      .' or newer, but '.$upper->who.' is supported only up to branch '.$upper->max_branch
    if $lower && $upper && $lower->min_branch > $upper->max_branch;
  return @conflicts;
}

# Validated, flattened members of a list of requirements.
sub _members_of {
  my ( $self, @requirements ) = @_;
  croak __PACKAGE__.'->intersect needs at least one requirement'
    unless @requirements;
  for my $req ( @requirements ) {
    croak __PACKAGE__.'->intersect: not a '.__PACKAGE__.' object: '.( $req // 'undef' )
      unless blessed( $req ) && $req->isa( __PACKAGE__ );
  }
  return map { @{ $_->members } ? @{ $_->members } : $_ } @requirements;
}

# The member with the highest lower bound and the one with the lowest upper
# bound (either may be undef).
sub _bounds {
  my ( $self, @members ) = @_;
  my ( $lower ) = sort { $b->min_branch <=> $a->min_branch }
    grep { defined $_->min_branch } @members;
  my ( $upper ) = sort { $a->max_branch <=> $b->max_branch }
    grep { defined $_->max_branch } @members;
  return ( $lower, $upper );
}


sub describe {
  my ( $self ) = @_;
  my $module = $self->kernel_module eq 'either'
    ? 'any kernel module'
    : $self->kernel_module.' kernel module';
  my ( $min, $max ) = ( $self->min_branch, $self->max_branch );
  my $branch = defined $min && defined $max ? 'driver branch '.$min.' to '.$max
             : defined $min                 ? 'driver branch '.$min.' or newer'
             : defined $max                 ? 'driver branch '.$max.' or older'
             :                                'any driver branch';
  return $module.', '.$branch;
}


sub who {
  my ( $self ) = @_;
  return join( ', ', map { $_->who } @{ $self->members } ) if @{ $self->members };
  my @what = grep { defined } $self->generation,
    defined $self->device_id ? '10de:'.$self->device_id : undef;
  my $who = $self->name // 'NVIDIA GPU';
  return @what ? $who.' ('.join( ', ', @what ).')' : $who;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Requirement - What NVIDIA driver a GPU generation needs (experimental)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Rex::GPU::NVIDIA::Requirement;

  my $req = Rex::GPU::NVIDIA::Requirement->from_gpu($gpu);
  say $req->generation // 'unknown generation', ': ', $req->describe;

  $req->satisfied_by({ kernel_module => 'open', branch => 580 })
    or die "the -open 580 driver cannot drive this GPU\n";

  # several GPUs, one driver
  my $all = Rex::GPU::NVIDIA::Requirement->intersect(
    map { Rex::GPU::NVIDIA::Requirement->from_gpu($_) } @compute_gpus
  );

=head1 DESCRIPTION

B<Experimental.> This API may change without a deprecation cycle for one
release. L<Rex::GPU::NVIDIA/install_driver> chooses the driver with it: the
L<Rex::GPU::NVIDIA::Setup> classes intersect the requirements of every GPU
they install for and take the first of their driver sources that
L</satisfied_by> accepts. L<Rex::GPU::Detect/open_kernel_module_required>
and L<Rex::GPU::Detect/legacy_driver_requirement> read from it too.

A requirement says which NVIDIA driver a GPU can work with: the kernel module
(L</kernel_module>) and the range of driver branches
(L</min_branch>..L</max_branch>). It is keyed on the PCI device ID, the one
signal C<lspci -nn> prints even when the host's C<pci.ids> predates the
silicon. Objects are immutable.

The table in L</generations> is a method, not a global, so a subclass can add
a row for silicon this release does not know yet without touching the
module.

=head2 generation

A label for the GPU generation (C<Blackwell>, C<Maxwell/Pascal/Volta>, ...)
taken from L</generations>, for messages. C<undef> for a device ID the table
does not know, and for a requirement built by L</intersect> from several
GPUs.

=head2 kernel_module

Which NVIDIA kernel module the GPU binds with: C<open> (NVIDIA's open GPU
kernel modules only — Blackwell has no proprietary module),
C<proprietary> (the closed module only — pre-Turing silicon lacks the GSP the
open module needs) or C<either>. Defaults to C<either>.

=head2 min_branch

The oldest driver branch (an integer, e.g. C<570>) that supports the GPU, or
C<undef> for no lower bound.

=head2 max_branch

The newest driver branch that still supports the GPU (e.g. C<580> for
Maxwell/Pascal/Volta, whose support ends there), or C<undef> for no upper
bound.

=head2 device_id

The lowercase PCI device ID (the C<XXXX> in C<[10de:XXXX]>) the requirement
was looked up for, or C<undef> (no or malformed ID, or an intersected
requirement).

=head2 name

The GPU name from detection (L</from_gpu>), for messages only. Never used to
decide anything.

=head2 members

For a requirement built by L</intersect> from several GPUs: an arrayref of
the per-GPU requirements it combines, so a message can name every GPU that
constrained it. Empty for a per-GPU requirement.

=head2 compute

Whether the GPU generation is one to install a driver for, as the
L</generations> row for L</device_id> declares it (karr #45, #54):

=over

=item * C<1> -- a generation a current driver branch supports: every GPU
NVIDIA has published with an ID in that row can run CUDA, so
L<Rex::GPU::Detect> counts the device as compute whatever its PCI class, its
marketing name (GeForce MX, GT, ... included) and whether C<lspci> could
resolve that name. The built-in table marks Maxwell through Blackwell Ultra.

=item * C<0> -- the row says the generation is not to be installed for: the
built-in table marks Kepler and older, whose last driver branch (470) the
current distributions no longer package. L<Rex::GPU::Detect> reports such a
GPU as not compute whatever its PCI class (a class-C<0302> Tesla K80 too,
karr #55), with a warning naming the generation and branch.

=item * C<undef> -- no row covers the ID (or it is missing or malformed), the
row has no C<compute> key, or the requirement was built by L</intersect>.
The table has no opinion; L<Rex::GPU::Detect> falls back to its name rules.

=back

=head2 generations

  my @rows = $class->generations;

The generation table: an ordered list of hashrefs, each covering the
inclusive PCI device-ID range C<first>..C<last> (numbers) with a
C<generation> label, a C<kernel_module> (default C<either>), optional
C<min_branch>/C<max_branch> and an optional C<compute> flag (see L</compute>).
The B<first> row whose range contains an ID
wins, so a narrower row goes before a block it sits in. An ID no row covers
gets C<either> with no bounds and no C<compute> verdict. The built-in rows
cover every ID from C<0000> to C<2FFF> without a gap, plus the Blackwell
Ultra IDs; the Turing-to-Hopper row carries no constraint (C<either>, no
bounds), only its label and C<compute>.

Override it in a subclass to add or replace rows; prepend to
C<< $self->SUPER::generations >> to keep the built-in ones:

  package My::GPU::Requirement;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Requirement';

  sub generations {
    my ( $self ) = @_;
    return (
      { generation => 'Hopper (site policy)', first => 0x2330, last => 0x2330,
        kernel_module => 'open', min_branch => 575 },
      $self->SUPER::generations
    );
  }

The table chooses a driver, and its C<compute> flags also decide detection:
L<Rex::GPU::Detect> asks this class (the built-in table, not a subclass) for
L</compute> before its name rules (karr #45, #54). The criterion is the
generation, not the marketing name: Maxwell, Pascal, Volta, Turing, Ampere,
Ada, Hopper, Blackwell and Blackwell Ultra rows are C<compute =E<gt> 1>, the
Kepler-or-older row C<compute =E<gt> 0>. A subclass that adds or replaces rows
changes the driver choice only, not detection.

Sources, all checked 2026-09-23 (Blackwell, pre-Turing) and 2026-09-24
(Turing to Hopper, compute flags):

=over

=item * Blackwell C<2900>-C<2FFF> (B200 C<2901>, GB200 C<2941>, GeForce RTX 50xx,
RTX PRO Blackwell, GB10 C<2E12>) and Blackwell Ultra (B300 C<3182>, GB300
C<31C2>/C<31C3>, listed one by one, not as a block): the supported-GPU table
in NVIDIA's open-gpu-kernel-modules README (driver 615.71.09). The last Ada ID
there is C<28F8>, and every listed ID from C<2901> to C<2F58> is Blackwell,
so an unlisted ID in C<2900>-C<2FFF> is taken as Blackwell too. Open kernel
module only; oldest branch 570 (Blackwell; GB10: 580, next item) and 580
(Blackwell Ultra).

=item * GB10 C<2E12> (DGX Spark, aarch64) has its own row ahead of the
Blackwell block: open kernel module, oldest branch B<580>, not 570. NVIDIA
lists C<2E12> first in driver 580.119.02 (open-gpu-kernel-modules README of
tag C<580.119.02>, and the aarch64 C<supportedchips> README of that driver);
580.105.08 and every 570/575 release lack it, and so does 590.44.01 (590.48.01
has it). The table counts whole branches, so it cannot say "580.119.02 or
newer": a host that installs an older 580 point release is not caught here.

=item * Maxwell/Pascal/Volta C<1340>-C<1DF6> (Tesla M60/M40, P100, P40, P4, V100,
V100S, TITAN V, ...): the 580 legacy list of NVIDIA's C<supportedchips>
README (615.71.09). Proprietary kernel module only; 580 is the last branch.
Compute: the entry-level parts in it (GeForce GT 1030, MX110/MX130/MX150,
GTX 750 Ti, GTX 9xx) included -- the 580 README lists every one of those IDs
as current, Maxwell Gen1 (GM107/GM108) too.

=item * Turing, Ampere, Ada, Hopper C<1DF7>-C<28FF>: NVIDIA's current list
(615.71.09) runs from C<1E02> (TITAN RTX) to C<28F8> in this range; no
legacy list has an ID above C<1DF6>. No constraint (C<either>, no bounds):
the default driver selection. Compute, GeForce MX450/MX550/MX570 and GTX 16xx
included.

=item * Kepler or older, every ID below C<1340> (Kepler C<0FC6>-C<12BA>, Fermi and
earlier): the 470 and older legacy lists. Proprietary only, nothing newer
than 470. Not compute, at any PCI class (the class-C<0302> Tesla
K80/K40/K20 included, karr #55): L<Rex::GPU::Detect> skips them with a
warning, and L<Rex::GPU::NVIDIA> refuses to install for one passed to it
anyway.

=back

=head2 for_device_id

  my $req = Rex::GPU::NVIDIA::Requirement->for_device_id('1db4');

The requirement for one NVIDIA PCI device ID (the C<XXXX> in C<[10de:XXXX]>,
any case), looked up in L</generations>. C<undef>, a malformed ID and an ID
no row covers all return a requirement of C<either> with no bounds. Called on
a subclass, it returns an object of that subclass and uses its table.

=head2 from_gpu

  my $req = Rex::GPU::NVIDIA::Requirement->from_gpu($gpu);

The same for a GPU hashref as returned by L<Rex::GPU::Detect/detect>: looks
up its C<device_id> and carries its C<name> along for messages. Croaks unless
C<$gpu> is a hashref.

=head2 satisfied_by

  $req->satisfied_by({ kernel_module => 'open', branch => 580 });   # 1 or 0
  $req->satisfied_by({ kernel_module => 'open', branch_at_least => 590 });

Whether a driver source satisfies this requirement: 1 or 0, the negation of
L</why_not>. A source is a hashref with a C<kernel_module> (C<open> or
C<proprietary>) and what is known about its driver branch, one of:

=over

=item * C<branch> -- an integer: the source installs exactly that branch
(C<nvidia-driver-580-server>, Debian 12's C<nvidia-driver> 535).

=item * C<branch_at_least> -- an integer, C<branch> undefined: the source
installs the B<newest> branch its repository carries, which is not known
before the install but is known to be at least this one (the repository
carries it, and a repository does not lose its newest branch). It satisfies
a L</min_branch> up to that floor and B<never> a L</max_branch>: a newer
branch can appear in the repository at any time and move past the bound.

=item * neither -- the branch is not known at all. That satisfies only a
requirement with no bounds.

=back

A requirement of C<either> takes any kernel module; otherwise the module must
match exactly. An exact C<branch> must lie within
L</min_branch>..L</max_branch>, both inclusive. A missing C<kernel_module>
satisfies only C<either>: an unknown never passes a real constraint. Croaks
unless C<$source> is a hashref, or if C<branch> or C<branch_at_least> is not
an integer.

=head2 why_not

  my $reason = $req->why_not($source);   # undef if it fits

C<undef> if L</satisfied_by> would say 1, otherwise a short reason for
messages (C<"proprietary kernel module, the open one is needed">,
C<"branch 590 is newer than 580">).

=head2 intersect

  my $req = Rex::GPU::NVIDIA::Requirement->intersect(@requirements);
  my $req = $v100->intersect($b200);   # invocant included: croaks here

The one requirement that satisfies all given ones, for a host with several
GPUs: one driver has to drive them all. Called on an object, that object is
one of the requirements. The kernel module is the one any member insists on
(C<either> only if all say C<either>); C<min_branch> is the highest lower
bound, C<max_branch> the lowest upper bound. A single requirement comes back
unchanged; several give a new object whose L</members> lists them (nested
intersections flattened) and whose C<generation>, C<device_id> and C<name>
are C<undef>.

Croaks with the L</conflicts>, naming the GPUs on each side, if members need
different kernel modules (a V100 needs C<proprietary>, a B200 C<open>) or the
bounds leave no branch (one GPU needs at least 590, another at most 580).
Also croaks for an empty list or anything that is not a requirement object.

=head2 conflicts

  my @why = Rex::GPU::NVIDIA::Requirement->conflicts(@requirements);

What L</intersect> would croak about, as a list of messages, one per
conflict; empty when the requirements can be combined. For a caller that
wants to phrase the failure itself.

=head2 describe

  print $req->describe;   # "open kernel module, driver branch 570 or newer"

A short human-readable form of the constraint, for log lines and error
messages.

=head2 who

  print $req->who;   # "GV100GL [Tesla V100] (Maxwell/Pascal/Volta, 10de:1db4)"

Who the requirement is for, for messages: the GPU's name, generation and
device ID, or for an intersected requirement the L</members>, comma
separated. C<NVIDIA GPU> when nothing is known.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA>, L<Rex::GPU::Detect>,
L<https://github.com/NVIDIA/open-gpu-kernel-modules>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-gpu/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
