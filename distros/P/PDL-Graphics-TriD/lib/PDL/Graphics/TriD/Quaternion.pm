##############################################
#
# Quaternions... inefficiently.
#
# Should probably use PDL and C... ?
#
# Stored as [c,x,y,z].
#
# XXX REMEMBER!!!! First component = cos(angle/2), *NOT* cos(angle)

package PDL::Graphics::TriD::Quaternion;

use strict;
use warnings;

sub _scalar_wrap {
  my ($v) = @_;
  return PDL::Graphics::TriD::Quaternion->new($v,0,0,0) if !ref $v;
  return PDL::Graphics::TriD::Quaternion->new(@$v) if ref $v eq 'ARRAY';
  $v;
}
use overload
  '=' => sub {$_[0]}, # without this, `$this->{Quat} .= $q` errors
  '.=' => sub {
    my ($a1, $a2) = @_;
    $a1->set(_scalar_wrap $a2);
  },
  '+' => sub {
    my ($a1, $a2, $swap) = @_;
    $a1->add(_scalar_wrap $a2);
  },
  '*' => sub {
    my ($a1, $a2, $swap) = @_;
    $a2 = _scalar_wrap $a2;
    ($a2, $a1) = ($a1, $a2) if $swap;
    $a1->multiply($a2);
  },
  '/' => sub {
    my ($a1, $a2, $swap) = @_;
    $a2 = _scalar_wrap $a2;
    ($a2, $a1) = ($a1, $a2) if $swap;
    $a1->multiply($a2->invert);
  },
  '!' => \&invert,
  '""' => sub { ref($_[0])."->new(".join(',', @{$_[0]}).")" };

sub new {
	my($type,$c,$x,$y,$z) = @_;
	my $this;

   if(ref($type)){
	  $this = $type;
	}else{
	  $this = bless [$c,$x,$y,$z],$type;
	}
	return $this;
}

sub copy {
  PDL::Graphics::TriD::Quaternion->new(@{$_[0]});
}

sub new_vrmlrot {
	my($type,$x,$y,$z,$c) = @_;
	my $l = sqrt($x**2+$y**2+$z**2);
	my $this = bless [cos($c/2),map {sin($c/2)*$_/$l} $x,$y,$z],$type;
	$this->normalise;
}

sub to_vrmlrot {
	my($this) = @_;
	my $d = POSIX::acos($this->[0]);
	if(abs($d) < 0.0000001) {
		return [0,0,1,0];
	}
	return [(map {$_/sin($d)} @{$this}[1..3]),2*$d];
}

sub multiply {
  my($this,$with) = @_;
  return PDL::Graphics::TriD::Quaternion->new(
        $this->[0] * $with->[0]
      - $this->[1] * $with->[1]
      - $this->[2] * $with->[2]
      - $this->[3] * $with->[3],
            $this->[0] * $with->[1]
          + $this->[1] * $with->[0]
          + $this->[2] * $with->[3]
          - $this->[3] * $with->[2],
        $this->[0] * $with->[2]
      - $this->[1] * $with->[3]
      + $this->[2] * $with->[0]
      + $this->[3] * $with->[1],
            $this->[0] * $with->[3]
          + $this->[1] * $with->[2]
          - $this->[2] * $with->[1]
          + $this->[3] * $with->[0],
  );
}

sub set {
  my($this,$new) = @_;
  @$this = @$new;
  $this;
}

sub add {
  my($this,$with) = @_;
  PDL::Graphics::TriD::Quaternion->new(map $this->[$_]+$with->[$_], 0..3);
}

sub abssq {
	my($this) = @_;
	return  $this->[0] ** 2 +
		$this->[1] ** 2 +
		$this->[2] ** 2 +
		$this->[3] ** 2 ;
}

sub invert {
	my($this) = @_;
	my $abssq = $this->abssq();
	return PDL::Graphics::TriD::Quaternion->new(
		 1/$abssq * $this->[0] ,
		-1/$abssq * $this->[1] ,
		-1/$abssq * $this->[2] ,
		-1/$abssq * $this->[3] );
}

sub invert_rotation_this {
	my($this) = @_;
	$this->[0] = - $this->[0];
}

sub normalise {
  my($this) = @_;
  my $abs = sqrt($this->abssq);
  @$this = map $_/$abs, @$this;
  $this;
}

sub rotate {
  my($this,$vec) = @_;
  my $q = PDL::Graphics::TriD::Quaternion->new(0,@$vec);
  my $m = $this->multiply($q->multiply($this->invert));
  return [@$m[1..3]];
}

1;
