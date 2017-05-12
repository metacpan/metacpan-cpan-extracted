package Net::IP::Match::Bin::Perl;

require Exporter;

use vars qw (@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw( match_ip );

$VERSION = '0.01';

our @BITS = (
    0x80000000, 0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
    0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00100000,
    0x00080000, 0x00040000, 0x00020000, 0x00010000, 0x00008000, 0x00004000,
    0x00002000, 0x00001000, 0x00000800, 0x00000400, 0x00000200, 0x00000100,
    0x00000080, 0x00000040, 0x00000020, 0x00000010, 0x00000008, 0x00000004,
    0x00000002, 0x00000001,
    );

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self => $class;

    my $tree = [];
    $self->{Tree} = $tree;
    return $self;
}

sub add {
    my $self = shift;
    my @ipranges = @_;

   # If an argument is a hash or array ref, flatten it
   # If an argument is a scalar, make it a key and give it a value of 1
   my @map
       = map {   ! ref $_            ? ( $_ => -1 )
               :   ref $_ eq 'ARRAY' ? map { $_ => -1 } @{$_}
               :                       %{$_}         } @ipranges;

   # The tree is a temporary construct.  It has three possible
   # properties: 0, 1, and code.  The code is the return value for a
   # match.

   for ( my $i = 0; $i < @map; $i += 2 ) {
      my $range = $map[ $i ];
      my $match = $map[ $i + 1 ];
      if ($match eq "-1") {
	  $match = "$range";
      }

      my ( $ip, $mask ) = split m/\//xms, $range;
      if (! defined $mask) {
         $mask = 32;          ## no critic(MagicNumbers)
      }

      my $tree = $self->{Tree}; # root

      my $addr = unpack 'N', pack 'C4', split /[.]/, $ip;
      for (my $i = 0; $i < $mask; $i++) {
	  my $bit = $addr & $BITS[$i] ? 1 : 0;
	  unless (defined $tree->[$bit]) {
	      $tree->[$bit] ||= [];
	  }
	  $tree = $tree->[$bit];   # Follow one branch
      }

      # Our $tree is now a leaf node of @$tree.  Set its value
      # If the code is already set, it's a non-fatal error (redundant data)
      $tree->[2] ||= $match;
   }
   return $self;
}

sub match_ip {
    my $self = shift;
    my $ip;

    if (! ref $self) {
	$ip = $self;
	$self = Net::IP::Match::Bin::Perl->new();
    } else {
	$ip = shift;
    }
    if (@_) {
	$self->add(\@_);
    }

    my $tree = $self->{Tree};
    my $addr = unpack 'N', pack 'C4', split /[.]/, $ip;

    for (my $i = 0; $i <= 32; $i++) {
	return $tree->[2] if defined $tree->[2];
	my $bit = $addr & $BITS[$i] ? 1 : 0;
	return undef unless defined $tree->[$bit];
	$tree = $tree->[$bit];
    }
    return undef;
}

sub _dump {
    my ($tree, $bits, $lvl) = @_;

    if (defined $tree->[2]) {
	for (my $i=$lvl; $i<32; $i++) {
	    $bits->[$i] = 0;
	}
	print join(".", unpack("C4", pack("B32", join('',@$bits)))) . "/$lvl\n";
    }
    if (defined $tree->[0]) {
	$bits->[$lvl] = 0;
	_dump($tree->[0], $bits, $lvl+1);
    }
    if (defined $tree->[1]) {
	$bits->[$lvl] = 1;
	_dump($tree->[1], $bits, $lvl+1);
    }
}

sub dump {
    my $self = shift;
    my @bits;
    _dump($self->{Tree}, \@bits, 0);
}

1;
