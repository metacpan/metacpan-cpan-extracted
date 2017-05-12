use strict;
use warnings;
use SOOT::Struct;
use Test::More tests => 6;

SCOPE: {
  my $struct = SOOT::Struct->new(name => 'strname', fields => <<'HERE');
    struct staff_t {
     Int_t           Category;
     Char_t          Division[4];
    };
HERE

  is_deeply(
    $struct, {
      name => 'strname',
      fields => [
        Category => 'Int_t',
        Division => 'Char_t[4]',
      ],
    }
  );
  is($struct->code, <<'HERE');
class strname : public TObject {
	public:
	Int_t	Category;
	Char_t	Division[4];
	ClassDef(strname, 1);
};
HERE
} # end scope



SCOPE: {
  my $struct = SOOT::Struct->new(name => 'strname2', fields => <<'HERE');
UInt_t a;
Char_t * * b;
HERE

  is_deeply(
    $struct, {
      name => 'strname2',
      fields => [
        a => 'UInt_t',
        b => 'Char_t**',
      ],
    }
  );
  is($struct->code, <<'HERE');
class strname2 : public TObject {
	public:
	UInt_t	a;
	Char_t**	b;
	ClassDef(strname2, 1);
};
HERE
} # end scope


SCOPE: {
  my $struct = SOOT::Struct->new(name => 'strname3', fields => [c=> 'UInt_t[5]', d=>'Double_t *']);

  is_deeply(
    $struct, {
      name => 'strname3',
      fields => [
        c => 'UInt_t[5]',
        d => 'Double_t*',
      ],
    }
  );
  is($struct->code, <<'HERE');
class strname3 : public TObject {
	public:
	UInt_t	c[5];
	Double_t*	d;
	ClassDef(strname3, 1);
};
HERE
} # end scope


