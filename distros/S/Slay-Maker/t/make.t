#!/usr/bin/perl -w

=item NAME

maker.t - Test suite for Slay::Maker

=head1 TODO

=item *

=cut

use strict ;
use Cwd ;
use Test ;
use vars qw( $path ) ;

my @e ;

my $file_0_name = "make.t.1.txt" ;
my $file_1_name = "make.t.0.txt" ;
my $file_2_name = "make.t.2.txt" ;
my $create_count = 0 ;
my $file_0_content ;
my @file_0_stats ;


sub pushe {
   my ( $maker, $target, $deps, $matches ) = @_ ;
   push @e,
   $target
} ;

sub age_file_0 {
   my $time = time - 1 ;
   utime $time, $time, $file_0_name or die "$1 utime-ing $file_0_name" ;
   @file_0_stats = stat $file_0_name ;
}

sub create_file_0 {
   ++$create_count ;
   open( F, ">$file_0_name" )
      or die "$! opening $file_0_name #$create_count" ;
   $file_0_content = "$file_0_name #$create_count" ;
   print F $file_0_content, "\n" ;
   close( F ) or die "$! closing $file_0_name #$create_count" ;
   return "created $file_0_name" ;
}

## This is needed so that the expected value can be computed at test tim
sub file_0_content { $file_0_content }

## slurp_...() could be check_...(), which would return a boolean.  But then the
## expected and actual values reported by the test suite would be '0' and '1'.
## Doing slurp_...() makes them a little more enlightening.
sub slurp_file_0 {
   open( F, "<$file_0_name" ) or die "$! opening $file_0_name" ;
   my $in = join( ', ', <F> ) ;
   close( F ) or die "$! closing $file_0_name" ;
   $in =~ s/\n//g ;
   return $in ;
}

sub slurp_file_1 {
   open( F, "<$file_1_name" ) or die "$! opening $file_1_name" ;
   my $in = join( ', ', <F> ) ;
   close( F ) or die "$! closing $file_1_name" ;
   $in =~ s/\n//g ;
   return $in ;
}

sub tweak_file_0 {
   open( F, ">>$file_0_name" ) or die "$! opening $file_0_name #$create_count" ;
   print F "tweaked\n" ;
   close( F ) or die "$! closing $file_0_name #$create_count" ;
   return "tweaked $file_0_name" ;
}


sub output_target {
   my ( $maker, $target, $deps, $matches ) = @_ ;
   $target ;
}

###############################################################################

my $m ;
my $r ;
my $tests ;

$tests = [

##
## Slay::MakerRule tests
##
## NB: MakeRule is not a public API.  But we need to test it's internals
## before testing Make

sub {
   $r = Slay::MakerRule->new( { rule => [qw{ abc a(*)b(*)c }, qr/d(.*)e(.*)f/] } ) ;
   ok( ref( $r ), "Slay::MakerRule" ) ;
},

sub {
   my ( $exactness, $matches ) = $r->matches( 'abc' ) ;
   ok( join( ',', $exactness, @$matches ), '-1' ) ;
},

sub {
   my ( $exactness, $matches ) = $r->matches( 'a123b456b789c' ) ;
   ok( join( ',', $exactness, @$matches ), '-3,123b456,789' ) ;
},

sub {
   my ( $exactness, $matches ) = $r->matches( 'd123e456d789f' ) ;
   ok( join( ',', $exactness, @$matches ), '-3,123,456d789' ) ;
},

sub { ok( Slay::MakerRule->new( {rule=>'a\b'}  )->matches( 'ab'   ) ? 1 : 0, 1 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a\b'}  )->matches( 'a\b'  ) ? 1 : 0, 0 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a*b'}  )->matches( 'a\b'  ) ? 1 : 0, 1 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a**b'} )->matches( 'a\b'  ) ? 1 : 0, 1 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a*b'}  )->matches( 'a/b'  ) ? 1 : 0, 0 ) },
# '\*' should match only a '*'.
sub { ok( Slay::MakerRule->new( {rule=>'a\*b'} )->matches( 'a\b'  ) ? 1 : 0, 0 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a\*b'} )->matches( 'a-b'  ) ? 1 : 0, 0 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a\*b'} )->matches( 'a*b'  ) ? 1 : 0, 1 ) },
sub { ok( Slay::MakerRule->new( {rule=>'a\*b'} )->matches( 'a\*b' ) ? 1 : 0, 0 ) },

##
## Slay::Maker tests
##
sub {
   ok( ref( $m = Slay::Maker->new({}) ), "Slay::Maker" ) ;
},

sub {
   my $f = "NoPe" ;
   die "$f must not exist" if -e $f ;
   ok( $m->e( $f ), '' ) ;
},

sub {
   die "$0 must exist" unless -e $0 ;
   ok( $m->e( $0 ), 1 ) ;
},

sub {
   $m->rules(
      [ qw( a: aa ab =), \&pushe ],
      [ qw( aa = ), \&pushe ],
      [ qw( ab = ), \&pushe ],
   ) ;
   ok( @{$m->rules}, 3 ) ;
},

sub {
   $m->build_queue( 'a' ) ;
   ok( $m->queue_size, 3 ) ;
},

sub {
   $m->exec_queue() ;
   ok( $m->queue_size, 3 ) ;
},

sub {
   ok( join( ', ', @e ), 'aa, ab, a' ) ;
},

## Test calling the command line.
sub {
   $m->rules(
      [ qw( a: b = ), 'perl -e "print \'$TARGET\'"' ],
      [ qw( b = ),    'perl -e "print \'$TARGET\'"' ],
   ) ;
   ok( @{$m->rules}, 2 ) ;
},

sub {
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   ok( $m->output, 'ba' ) ;
},

sub {
   $m->rules(
      [ qw( a: b = ), 'perl -e "print \'$TARGET\'"', { options => 1 } ],
      [ qw( b = ),    'perl -e "print \'$TARGET\'"'                   ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->replace_rules(
      [ qw{ a: b= },
	 [ qw( perl -e ), 'print \'$TARGET\'' ],
      ],
   ) ;
   ok( @{$m->rules}, 2 ) ;
},

sub {
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   ok( $m->output, 'b$TARGET' ) ;
},

sub {
   $m->rules(
      [ qw{ * : b = }, \&output_target ],
      [ qw{ b= }, \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->rules(
      [ qw{ a**c: c }, '=', \&output_target ],
      [ qr/a\*c/,  ':', 'b', '=', \&output_target ],
      [ '*:', 'd', \&output_target ],
      [ 'b=', \&output_target ],
      [ 'c=', \&output_target ],
      [ 'd=', \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a*c' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba*c' ) ;
},

sub {
   $m->replace_rules(
      [ '*:', sub { qw( b  c ) }, '=', \&output_target ],
      [ 'b=', \&output_target ],
      [ 'c=', \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'bca' ) ;
},

sub {
   $m->rules(
      [ qw{ ?: b =}, \&output_target ],
      [ 'b=',        \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->rules(
      [ '**:', 'b=', \&output_target ],
      [ 'b=',        \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->rules(
      [ '(*):', 'b=',
	 sub { 
	    my ( $maker, $target, $deps, $matches ) = @_ ;
	    return $matches->[0] ;
	 }
      ],
      [ 'b=', \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->rules(
      [ 'a(?)(?):', '$1', '${2}', 'd${TARGET}=', \&output_target ],
      [ 'b=',     \&output_target ],
      [ 'c=',     \&output_target ],
      [ 'dabc=',  \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'abc' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'bcdabcabc' ) ;
},

sub {
   $m->rules(
      [ 'a:', sub { shift->make( 'b' ) ; () }, '=', \&output_target ],
      [ 'b=', \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'a' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'ba' ) ;
},

sub {
   $m->rules(
      [
	 'a(?)',
	 ':', sub { my ( $maker, $target, $matches ) = @_ ; $matches->[0] },
	 '=', \&output_target
      ],
      [ 'b=', \&output_target ],
   ) ;
   my $out = join( '', $m->make( 'ab' ) ) ;
   $out =~ s/\n//g ;
   ok( $out, 'bab' ) ;
},

## Beginning of file based tests

sub {
   $m->rules( [ $file_0_name, '=', \&create_file_0 ] ) ;
   unlink $file_0_name ;
   $m->make( $file_0_name ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

sub {
   my $out = join( '', $m->make( $file_0_name ) ) ;
   chomp $out ;
   ok( $out, '' ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

## See if utime and atime are indeed restored.  Since the count has not gone
## above 8 by this time, size won't change, and they should be restored.
sub {
   age_file_0() ;
   $m->clear_caches() ;
   $m->make(
      $file_0_name,
      { force=>1, detect_no_size_change=>1 }
   ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub {
   my @new_stats = stat $file_0_name ;
   ok( join(',',@new_stats[7..9]), join(',',@file_0_stats[7..9]) ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

## See if utime and atime are not restored when the size changes.
sub {
   tweak_file_0() ;
   age_file_0() ;
   sleep 1;
   $m->make( $file_0_name, {force=>1, detect_no_size_change=>1} ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub {
   my @new_stats = stat $file_0_name ;
   ok( join(',',@new_stats[8,9]) eq join(',',@file_0_stats[8,9]), '' ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

## See if utime and atime are not restored when the content changes. Since we're
## below 8 here (still), the size won't change (we test this).
sub {
   age_file_0() ;
   sleep 1;

   $m->make( $file_0_name, {force=>1, detect_no_diff_change=>1} ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub {
   my @new_stats = stat $file_0_name ;
   ok( join(';',@new_stats[7..9]) eq join(';',@file_0_stats[7..9]), '' );
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

sub {
   $m->make( $file_0_name, {force => 1} ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

sub {
   my $out = tweak_file_0() ;
   chomp $out ;
   ok( $out, "tweaked $file_0_name" )
},

sub{ ok( \&slurp_file_0, "$file_0_content, tweaked" ) },

sub {
   $m->make( $file_0_name, {force => 1} ) ;
   ok( $m->output, "created $file_0_name" ) ;
},

sub { ok( \&slurp_file_0, \&file_0_content ) },

## See if mtime logic works.

sub {
   ## We rely on shell redirects here, but not on cat or echo.
   unlink $file_0_name ;
   unlink $file_1_name ;
   $m->clear_caches() ;
   $m->rules(
      [ "$file_1_name",
	':', "$file_0_name",
	'=', 'perl -pe 1 $DEP0>$TARGET; perl -e "print 1"'
      ],
      [ "$file_0_name",
	'=', 'perl -e "print \\"$TARGET\\"">$TARGET; perl -e "print 0"'
      ],
   ) ;
   $m->make( $file_1_name ) ;
   ok( $m->output, '01' ) ;
},

sub { ok( \&slurp_file_1, $file_0_name ) },

sub {
   my $now = time ;
   utime $now, $now, $file_0_name ;
   utime $now, $now, $file_1_name ;
   $m->clear_caches() ;
   $m->make( $file_1_name ) ;
   ok( $m->output, '' ) ;
},

sub {
   my $now = time ;
   utime $now, $now, $file_0_name ;
   utime $now+1, $now+1, $file_1_name ;
   $m->clear_caches() ;
   $m->make( $file_1_name ) ;
   ok( $m->output, '' ) ;
},

sub {
   my $now = time ;
   utime $now, $now, $file_0_name ;
   utime $now-1, $now-1, $file_1_name ;
   $m->clear_caches() ;
   $m->make( $file_1_name ) ;
   ok( $m->output, '1' ) ;
},

# Check that we catch recursive dependencies
sub {
   my $now = time ;
   utime $now, $now, $file_0_name ;
   utime $now-1, $now-1, $file_1_name ;
   $m->clear_caches() ;
   $m->rules(
      [ $file_1_name,
	':', $file_0_name, $file_1_name, 
	'=', 'perl -pe 1 $DEP0>$TARGET; perl -e "print 1"'
      ],
   ) ;
   my @warnings;
   local $SIG{__WARN__} = sub {
       push @warnings, @_;
   };
   $m->make( $file_1_name ) ;
   ok( @warnings . $m->output, '11' ) ;
},
sub {
   ## We rely on shell redirects here, but not on cat or echo.
   unlink $file_0_name ;
   unlink $file_1_name ;
   my @warnings;
   local $SIG{__WARN__} = sub {
       push @warnings, @_;
   };
   $m->clear_caches() ;
   $m->rules(
      [ $file_1_name,
	':', $file_0_name,
	'=', 'perl -pe 1 $DEP0>$TARGET; perl -e "print 1"'
      ],
      [ $file_0_name,
	':', $file_1_name,
	'=', 'perl -e "print \\"$TARGET\\"">$TARGET; perl -e "print 0"'
      ],
   ) ;
   $m->make( $file_1_name ) ;
   ok( @warnings . $m->output, '101' ) ;
},
sub {
   my $now = time ;
   do { open my $fh, '>', $file_2_name };
   utime $now-1, $now-1, $file_0_name ;
   utime $now-1, $now-1, $file_1_name ;
   utime $now, $now, $file_2_name ;
   $m->clear_caches() ;
   $m->rules(
      [ $file_0_name,
	':', $file_1_name,
	'=', 'perl -pe 1 $DEP0>$TARGET; perl -e "print 1"'
      ],
      [ $file_1_name,
	':', $file_2_name,
	'=', 'perl -e "print \\"$TARGET\\"">$TARGET; perl -e "print 0"'
      ],
   ) ;
   $m->make( $file_1_name, $file_0_name ) ;
   ok( $m->output, '01' ) ;
},
] ;

plan tests => scalar( @$tests ) ;

require Slay::Maker ;

for ( qw( a b c aa bb dabc NoPe ) ) {
   die "file '$_' must not exist in " . cwd() if -e $_  ;
}

&$_ for ( @$tests ) ;

unlink $file_0_name ;
unlink $file_1_name ;

