#@ Automated test for S-SymObj (make test).
#@ Note this should be run with $Debug=0,1,2 TODO automatize this

use Test::Simple tests => 53;

BEGIN{ require SymObj; $SymObj::Debug = 0 }
my ($o, $v, @va, %ha, $m);

## Basic: creation, field content validity, "feed-in and forget"

{package X1;
   SymObj::sym_create(SymObj::NONE, { # (NONE is 0..)
      _name => '', _array => [qw(av1 av2)],
      _hash => {hk1 => 'hv1', hk2 => 'hv2'}})
}
{package X2;
   our @ISA = ('X1'); SymObj::sym_create(0, {})
}
{package X3;
   our @ISA = ('X2');
   SymObj::sym_create(0, {_name => 'X3 override',
      '@_array2' => undef, '%_hash2' => undef})
}

$o = X2->new(name => 'EASY T1');
ok(defined $o);
ok($o->name eq 'EASY T1');

$v = $o->name('EASY T2');
ok($o->name eq 'EASY T2' && $v eq $o->name);

$o->array(   '1_1');  $o->array('2_1');
$o->array(qw( 1_2                2_2));
$o->array([qw(1_3                2_3)]);
$o->array(   '1_4' =>           '2_4');
ok($o->array->[0] eq 'av1' && $o->array->[1] eq 'av2' &&
   $o->array->[2] eq '1_1' && $o->array->[3] eq '2_1' &&
   $o->array->[4] eq '1_2' && $o->array->[5] eq '2_2' &&
   $o->array->[6] eq '1_3' && $o->array->[7] eq '2_3' &&
   $o->array->[8] eq '1_4' && $o->array->[9] eq '2_4');

$v = $o->array;
ok($v->[0] eq 'av1' && $v->[1] eq 'av2' &&
   $v->[2] eq '1_1' && $v->[3] eq '2_1' &&
   $v->[4] eq '1_2' && $v->[5] eq '2_2' &&
   $v->[6] eq '1_3' && $v->[7] eq '2_3' &&
   $v->[8] eq '1_4' && $v->[9] eq '2_4');

@va = $o->array();
ok($va[0] eq 'av1' && $va[1] eq 'av2' &&
   $va[2] eq '1_1' && $va[3] eq '2_1' &&
   $va[4] eq '1_2' && $va[5] eq '2_2' &&
   $va[6] eq '1_3' && $va[7] eq '2_3' &&
   $va[8] eq '1_4' && $va[9] eq '2_4');

$o->hash(    i_1 => 'yo1',  we_1 => 'al1');
$o->hash(   'i_2',  'yo2', 'we_2',  'al2');
$o->hash(qw( i_3     yo3    we_3     al3));
$o->hash([qw(i_4     yo4    we_4     al4)]);
$o->hash({   i_5 => 'yo5',  we_5 => 'al5'});
ok($o->hash->{hk1} eq 'hv1' && $o->hash->{hk2} eq 'hv2' &&
   $o->hash->{i_1} eq 'yo1' && $o->hash->{we_1} eq 'al1' &&
   $o->hash->{i_2} eq 'yo2' && $o->hash->{we_2} eq 'al2' &&
   $o->hash->{i_3} eq 'yo3' && $o->hash->{we_3} eq 'al3' &&
   $o->hash->{i_4} eq 'yo4' && $o->hash->{we_4} eq 'al4' &&
   $o->hash->{i_5} eq 'yo5' && $o->hash->{we_5} eq 'al5');

$v = $o->hash;
ok($v->{hk1} eq 'hv1' && $v->{hk2} eq 'hv2' &&
   $v->{i_1} eq 'yo1' && $v->{we_1} eq 'al1' &&
   $v->{i_2} eq 'yo2' && $v->{we_2} eq 'al2' &&
   $v->{i_3} eq 'yo3' && $v->{we_3} eq 'al3' &&
   $v->{i_4} eq 'yo4' && $v->{we_4} eq 'al4' &&
   $v->{i_5} eq 'yo5' && $v->{we_5} eq 'al5');

%ha = $o->hash();
ok($ha{hk1} eq 'hv1' && $ha{hk2} eq 'hv2' &&
   $ha{i_1} eq 'yo1' && $ha{we_1} eq 'al1' &&
   $ha{i_2} eq 'yo2' && $ha{we_2} eq 'al2' &&
   $ha{i_3} eq 'yo3' && $ha{we_3} eq 'al3' &&
   $ha{i_4} eq 'yo4' && $ha{we_4} eq 'al4' &&
   $ha{i_5} eq 'yo5' && $ha{we_5} eq 'al5');

$o = X3->new;
ok($o->name eq 'X3 override');
ok(defined $o->array2 && defined $o->hash2);
ok(ref $o->array2 eq 'ARRAY' && ref $o->hash2 eq 'HASH');

## "Static" data update

%{X1::hash()} = ();
X1::hash(newhk1=>'newhv1', newhk2=>'newhv2');
$o = X2->new(name => 'EASY T3');
ok($o->name eq 'EASY T3' && $o->hash->{newhk1} eq 'newhv1' &&
   $o->hash->{newhk2} eq 'newhv2');

## Clean straight hierarchy, ctor call order

{package T1_0;
   SymObj::sym_create(0, {_i1 => 'T1_0', _n => 'T1_0', _v => 1},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0); $m |= 0b00000001 })
}
{package T1_1;
   our @ISA = (qw(T1_0));
   SymObj::sym_create(0, {_i2 => 'T1_1', _n => 'T1_1', _v => 2},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0b1); $m |= 0b00000010 })
}
{package T1_2;
   our @ISA = (qw(T1_1));
   SymObj::sym_create(0, {_i3 => 'T1_2', _n => 'T1_2', _v => 3},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0b11); $m |= 0b00000100 })
}

{package T2_0;
   SymObj::sym_create(0, {_i4 => 'T2_0', _n => 'T2_0', _v => 4},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0b111); $m |= 0b00001000 })
}
{package T2_1;
   our @ISA = (qw(T2_0));
   SymObj::sym_create(0, {_i5 => 'T2_1', _n => 'T2_1', _v => 5},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0b1111); $m |= 0b00010000 })
}

{package TX;
   our @ISA = (qw(T1_2 T2_1));
   SymObj::sym_create(0, {_ix => 'TX', _n => 'TX', _v => 1000},
      sub{ my ($self, $pkg) = @_; ::ok($m == 0b11111); $m |= 0b00100000 })
}

$m = 0;
$o = TX->new;
ok($m == 0b00111111);
ok($o->n eq 'TX' && $o->v == 1000 && $o->i1 eq 'T1_0' &&
   $o->i2 eq 'T1_1' && $o->i3 eq 'T1_2' && $o->i4 eq 'T2_0' &&
   $o->i5 eq 'T2_1');

## Clean diverged hierarchy, ctor order

{package C111;
   SymObj::sym_create(0, {_i1 => 'C111', _n => 'C111', _v => 1},
      sub{ my $self=shift; ::ok($m==0b000000000000); $m|=0b000000000001 })
}
{package C112;
   SymObj::sym_create(0, {_i2 => 'C112', _n => 'C112', _v => 2},
      sub{ my $self=shift; ::ok($m==0b000000000001); $m|=0b000000000010 })
}
{package C11;
   our @ISA = (qw(C111 C112));
   SymObj::sym_create(0, {_i3 => 'C11', _n => 'C11', _v => 3},
      sub{ my $self=shift; ::ok($m==0b000000000011); $m|=0b000000000100 })
}
{package C12;
   SymObj::sym_create(0, {_i4 => 'C12', _n => 'C12', _v => 4},
      sub{ my $self=shift; ::ok($m==0b000000000111); $m|=0b000000001000 })
}
{package C1;
   our @ISA = (qw(C11 C12));
   SymObj::sym_create(0, {_i5 => 'C1', _n => 'C1', _v => 5},
      sub{ my $self=shift; ::ok($m==0b000000001111); $m|=0b000000010000 })
}

{package C211;
   SymObj::sym_create(0, {_i6 => 'C211', _n => 'C211', _v => 6},
      sub{ my $self=shift; ::ok($m==0b000000011111); $m|=0b000000100000 })
}
{package C2121;
   SymObj::sym_create(0, {_i7 => 'C2121', _n => 'C2121', _v => 7},
      sub{ my $self=shift; ::ok($m==0b000000111111); $m|=0b000001000000 })
}
{package C212;
   our @ISA = (qw(C2121));
   SymObj::sym_create(0, {_i8 => 'C212', _n => 'C212', _v => 8},
      sub{ my $self=shift; ::ok($m==0b000001111111); $m|=0b000010000000 })
}
{package C21;
   our @ISA = (qw(C211 C212));
   SymObj::sym_create(0, {_i9 => 'C21', _n => 'C21', _v => 9},
      sub{ my $self=shift; ::ok($m==0b000011111111); $m|=0b000100000000 })
}
{package C221;
   SymObj::sym_create(0, {_i10 => 'C221', _n => 'C221', _v => 10},
      sub{ my $self=shift; ::ok($m==0b000111111111); $m|=0b001000000000 })
}
{package C22;
   our @ISA = (qw(C221));
   SymObj::sym_create(0, {_i11 => 'C22', _n => 'C22', _v => 11},
      sub{ my $self=shift; ::ok($m==0b001111111111); $m|=0b010000000000 })
}
{package C2;
   our @ISA = (qw(C21 C22));
   SymObj::sym_create(0, {_i12 => 'C2', _n => 'C2', _v => 12},
      sub{ my $self=shift; ::ok($m==0b011111111111); $m|=0b100000000000 })
}

{package C;
   our @ISA = (qw(C1 C2));
   SymObj::sym_create(0, {_i13 => 'C', _n => 'C', _v => 13},
      sub{ my $self=shift; ::ok($m==0b111111111111); $m|=0b1000000000000 })
}

$m = 0;
$o = C->new;
ok($m == 0b1111111111111);
ok($o->n eq 'C' && $o->v == 13 && $o->i1 eq 'C111' && $o->i2 eq 'C112' &&
   $o->i3 eq 'C11' && $o->i4 eq 'C12' && $o->i5 eq 'C1' &&
   $o->i6 eq 'C211' && $o->i7 eq 'C2121' && $o->i8 eq 'C212' &&
   $o->i9 eq 'C21' && $o->i10 eq 'C221' && $o->i11 eq 'C22' &&
   $o->i12 eq 'C2' && $o->i13 eq 'C');

## Dirty diverged hierarchy (, ctor order) (reuse "C1" tree from above test)

{package DSUPER;
   sub new{ my $self = {}; bless $self, shift }
   sub n{ my $self = shift; $self->{_n} }
   sub v{ my $self = shift; $self->{_v} }
}

{package D111;
   our @ISA = (qw(DSUPER));
   sub new{
      my $class = shift;
      my $self = $class->SUPER::new();
      ::ok($m==0b000000011111); $m|=0b000000100000;
      $self->{_i6} = 'D111'; $self->{_n} = 'D111'; $self->{_v} = 6;
      bless $self, $class
   }
   sub i6{ my $self = shift; $self->{_i6} }
}
{package D1121;
   SymObj::sym_create(0, {_i7 => 'D1121', _n => 'D1121', _v => 7},
      sub{ my $self=shift; ::ok($m==0b000000111111); $m|=0b000001000000 })
}
{package D112;
   our @ISA = (qw(D1121));
   SymObj::sym_create(0, {_i8 => 'D112', _n => 'D112', _v => 8},
      sub{ my $self=shift; ::ok($m==0b000001111111); $m|=0b000010000000 })
}
{package D11;
   our @ISA = (qw(D111 D112));
   SymObj::sym_create(0, {_i9 => 'D11', _n => 'D11', _v => 9},
      sub{ my $self=shift; ::ok($m==0b000011111111); $m|=0b000100000000 })
}
{package D121;
   our @ISA = (qw(DSUPER));
   sub new{
      my $class = shift;
      my $self = $class->SUPER::new();
      ::ok($m==0b000111111111); $m|=0b001000000000;
      $self->{_i10} = 'D121'; $self->{_n} = 'D121'; $self->{_v} = 10;
      bless $self, $class
   }
   sub i10{ my $self = shift; $self->{_i10} }
}
{package D12;
   our @ISA = (qw(D121));
   sub new{
      my $class = shift;
      my $self = $class->SUPER::new();
      ::ok($m==0b001111111111); $m|=0b010000000000;
      $self->{_i11} = 'D12'; $self->{_n} = 'D12'; $self->{_v} = 11;
      bless $self, $class
   }
   sub i11{ my $self = shift; $self->{_i11} }
}
{package D1;
   our @ISA = (qw(D11 D12));
   SymObj::sym_create(0, {_i12 => 'D1', _n => 'D1', _v => 12},
      sub{ my $self=shift; ::ok($m==0b011111111111); $m|=0b100000000000 })
}

{package DC;
   our @ISA = (qw(C1 D1));
   SymObj::sym_create(0, {_i13 => 'DC', _n => 'DC', _v => 13},
      sub{ my $self=shift; ::ok($m==0b111111111111); $m|=0b1000000000000 })
}

$m = 0;
$o = DC->new;
ok($m == 0b1111111111111);
ok($o->n eq 'DC' && $o->v == 13 && $o->i1 eq 'C111' && $o->i2 eq 'C112' &&
   $o->i3 eq 'C11' && $o->i4 eq 'C12' && $o->i5 eq 'C1' &&
   $o->i6 eq 'D111' && $o->i7 eq 'D1121' && $o->i8 eq 'D112' &&
   $o->i9 eq 'D11' && $o->i10 eq 'D121' && $o->i11 eq 'D12' &&
   $o->i12 eq 'D1' && $o->i13 eq 'DC');

## Deep cloning

{package E1;
   SymObj::sym_create(SymObj::NONE,
      {_array => [1, [2, 3]], _hash => {one => 4, two => [5, 6]}});

   sub reset{
      array()->[0] = 1;
      array()->[1]->[0] = 2;
      hash()->{one} = 4;
      hash()->{two}->[0] = 5
   }

   sub modify{
      array()->[0] = -1;
      array()->[1]->[0] = -2;
      hash()->{one} = -4;
      hash()->{two}->[0] = -5
   }

   sub test{
      my ($self, $ismod) = @_;
      # First level is always "deep copied", but references deeper only with
      # DEEP_CLONE
      if(!$ismod){
         $self->array->[0] == 1 && $self->array->[1]->[0] == 2 &&
            $self->hash->{one} == 4 && $self->hash->{two}->[0] == 5
      }else{
         $self->array->[0] == 1 && $self->array->[1]->[0] == -2 &&
            $self->hash->{one} == 4 && $self->hash->{two}->[0] == -5
      }
   }
}
{package E11;
   our @ISA = ('E1'); SymObj::sym_create(SymObj::DEEP_CLONE, {})
}
{package E12;
   our @ISA = ('E1'); SymObj::sym_create(SymObj::NONE, {})
}

$o = E11->new;
E1::modify();
ok($o->test(0));
E1::reset();
$o = E12->new;
E1::modify();
ok($o->test(1))

# s-it-mode
