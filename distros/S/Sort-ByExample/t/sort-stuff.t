#!perl
use strict;
use warnings;

use Test::More tests => 13;

use Sort::ByExample
  sbe    => undef,
  sorter => { -as => 'alpha_sort', example => [ qw(first second third) ] },
  cmp    => { -as => 'alpha_cmp',  example => [ qw(first second third) ] };

{
  my @example = qw(
    foo
    bar
    baz
    quux
    pantalones
  );

  my @input  = qw(foo bar bar x foo quux foo pantalones garbage);

  {
    # We'll sort by example, falling back to sorting by length.
    my @expect = qw(foo foo foo bar bar quux pantalones x garbage);

    my $sorter = sbe(\@example, sub { length $_[0] <=> length $_[1] });
    my @sorted = $sorter->(@input);

    # diag "IN:   @input";
    # diag "OUT:  @sorted";
    # diag "WANT: @expect";
    is_deeply(\@sorted, \@expect, "it sorted as we wanted");
  }

  {
    # We'll sort by example, falling back to sorting by length.
    my @expect = qw(foo foo foo bar bar quux pantalones garbage x);

    my $sorter = sbe(\@example, sub { length $_[1] <=> length $_[0] });
    my @sorted = $sorter->(@input);

    # diag "IN:   @input";
    # diag "OUT:  @sorted";
    # diag "WANT: @expect";
    is_deeply(\@sorted, \@expect, "it sorted as we wanted");
  }
}

{
  # We'll sort by example, falling back to sorting by length.
  my $example = { x => 1, xyzzy => 1, bar => 2 };
  my @input   = qw(x xyzzy crap xyzzy bar bar lemon x x xyzzy);
  my @expect  = qw(x x x xyzzy xyzzy xyzzy bar bar crap lemon);

  my $sorter = sbe($example, sub { length $_[0] <=> length $_[1] });
  my @sorted = $sorter->(@input);

  # diag "IN:   @input";
  # diag "OUT:  @sorted";
  # diag "WANT: @expect";
  is_deeply(\@sorted, \@expect, "it sorted as we wanted");
}

{
  # We'll sort by example, falling back to sorting by length (named args).
  my $example = { x => 1, xyzzy => 1, bar => 2 };
  my @input   = qw(x xyzzy crap xyzzy bar bar lemon x x xyzzy);
  my @expect  = qw(x x x xyzzy xyzzy xyzzy bar bar crap lemon);

  my $sorter = sbe(
    $example,
    { fallback => sub { length $_[0] <=> length $_[1] } },
  );
  my @sorted = $sorter->(@input);

  # diag "IN:   @input";
  # diag "OUT:  @sorted";
  # diag "WANT: @expect";
  is_deeply(\@sorted, \@expect, "it sorted as we wanted");
}

{
  eval { sbe('scalars are invalid'); };
  like($@, qr/invalid/, 'we throw an exception for non-% non-@ example');
}

{
  # We'll sort codename alpha after the example.
  my $example = [ qw(charlie alfa bravo) ];
  my @input   = (
    { name => 'Bertrand', codename => 'bravo'   },
    { name => 'Dracover', codename => 'zulu',   },
    { name => 'Cheswick', codename => 'charlie' },
    { name => 'Elbereth', codename => 'yankee'  },
    { name => 'Algernon', codename => 'alfa'    },
  );
  my @expect  = (
    { name => 'Cheswick', codename => 'charlie' },
    { name => 'Algernon', codename => 'alfa'    },
    { name => 'Bertrand', codename => 'bravo'   },
    { name => 'Elbereth', codename => 'yankee'  },
    { name => 'Dracover', codename => 'zulu',   },
  );

  my $fallback = sub {
    my ($x, $y) = @_;
    return $x cmp $y;
  };

  my $sorter = sbe(
    $example,
    {
      fallback => $fallback,
      xform    => sub { $_[0]->{codename} },
    },
  );

  my @sorted = $sorter->(@input);

  is_deeply(\@sorted, \@expect, "hashrefs sorted as we wanted");
}

{
  # We'll sort name alpha  after the example.
  my $example = [ qw(charlie alfa bravo) ];
  my @input   = (
    { name => 'Bertrand', codename => 'bravo'   },
    { name => 'Dracover', codename => 'zulu',   },
    { name => 'Cheswick', codename => 'charlie' },
    { name => 'Elbereth', codename => 'yankee'  },
    { name => 'Algernon', codename => 'alfa'    },
  );
  my @expect  = (
    { name => 'Cheswick', codename => 'charlie' },
    { name => 'Algernon', codename => 'alfa'    },
    { name => 'Bertrand', codename => 'bravo'   },
    { name => 'Dracover', codename => 'zulu',   },
    { name => 'Elbereth', codename => 'yankee'  },
  );

  my $fallback = sub {
    my ($x_xf, $y_xf, $x, $y) = @_;
    return $x->{name} cmp $y->{name};
  };

  my $sorter = sbe(
    $example,
    {
      fallback => $fallback,
      xform    => sub { $_[0]->{codename} },
    },
  );

  my @sorted = $sorter->(@input);

  is_deeply(\@sorted, \@expect, "hashrefs sorted as we wanted");
}

{
  my $example = [ qw(first fifth fourth third second sixth) ];

  is_deeply(
    [ alpha_sort(@$example) ],
    [ qw(first second third fifth fourth sixth) ],
    "alpha_sort installed routine",
  );

  is(
    alpha_cmp('second', 'first'),
    1,
    "alpha_cmp on two args",
  );

  is_deeply(
    [ sort { alpha_cmp($a, $b) } @$example ],
    [ qw(first second third fifth fourth sixth) ],
    "alpha_cmp installed routine",
  );

  is_deeply(
    [ sort alpha_cmp @$example ],
    [ qw(first second third fifth fourth sixth) ],
    "alpha_cmp installed routine",
  );
}

{
  use Sort::ByExample
   cmp    => { -as => 'by_eng',   example => [qw(first second third fourth)] },
   sorter => { -as => 'eng_sort', example => [qw(first second third fourth)] };

  my @example = qw(first second third fourth);
  my $sorter = sbe(\@example);

  is_deeply(
    [ eng_sort(qw(second third unknown fourth first)) ],
    [ qw(first second third fourth unknown) ],
    'sorter from synopsis',
  );

  is_deeply(
    [ sort by_eng qw(second third unknown fourth first) ],
    [ qw(first second third fourth unknown) ],
    'sort cmp LIST from synopsis',
  );
}
