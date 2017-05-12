#! /usr/bin/perl
#---------------------------------------------------------------------
# Make sure we issue the proper warnings for missing fields,
# but not for ones that are merely undef.
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More;

BEGIN {
  # RECOMMEND PREREQ: Test::Warn
  eval "use Test::Warn";
  plan skip_all => "Test::Warn required for testing warnings" if $@;
}

plan tests => 2;

use PostScript::Report ();

# Describe the report:
my $desc = {
  page_header => [
    { width => 100, value => 'head1' },
    { width => 100, value => 'head2' },
    { width => 100, value => 'missing' },
  ], # end page_header

  columns => {
    data => [
      [ 'Number' =>  40 ],
      [ 'Letter' =>  40 ],
      [ 'Text'   => 320 ],
      [ 'Right'  =>  60 ],
    ],
  }, # end columns
};

# Generate sample data for the report:
my $letter = 'A';

my @rows = map { my $r=[ $_, $letter, "$_ $letter", "Right $_" ];
                 ++$letter;
                 $r } 1 .. 20;

# Now sabotage the data:
pop @{ $rows[5] };

pop @{ $rows[17] };
pop @{ $rows[17] };

$rows[3][4] = undef;

my %data = ( head1 => 'ok', head2 => undef );

# Build the report and run it:
my $rpt = PostScript::Report->build($desc);

# Have to use warnings_like, because warnings_are expects " at X line ...":
warnings_like { $rpt->run(\%data, \@rows) }
  [qr/^missing is not a key in this report's %data/,
   qr/^Row 5 has no column 3 \(only 0 through 2\)/,
   qr/^Row 17 has no column 2 \(only 0 through 1\)/,
   qr/^Row 17 has no column 3 \(only 0 through 1\)/,
  ];

is($rpt->page_count, 1, 'page count');
