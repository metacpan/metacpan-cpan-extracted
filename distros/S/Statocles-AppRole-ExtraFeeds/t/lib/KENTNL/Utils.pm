use 5.006;    # our
use strict;
use warnings;

package KENTNL::Utils;

our $VERSION = '0.001000';

# ABSTRACT: Output function lists heirachially

# AUTHORITY

use Exporter        ();
use Term::ANSIColor ('colored');
use Carp            ('croak');
use Package::Stash  ();

BEGIN { *import = \&Exporter::import }

our @EXPORT = qw( symdump has_feeds );

use constant 1.03 ( { map { ( sprintf '_E%x', $_ ), ( sprintf ' E<%s#%d>', __PACKAGE__, $_ ) } 1 .. 4 } );

{
  no strict;    # namespace clean
  delete ${ __PACKAGE__ . '::' }{ sprintf '_E%x', $_ } for 1 .. 4;
}

our @TYPE_METHOD      = ('cyan');
our @TYPE             = ('yellow');
our @PRIVATE          = ('reset');
our @PUBLIC           = ( 'bold', 'bright_green' );
our @SHADOWED_PRIVATE = ('magenta');
our @SHADOWED_PUBLIC  = ('red');

our $MAX_WIDTH     = 80;
our $SHOW_SHADOWED = 1;
our $INDENT        = q[ ] x 4;
our $CLUSTERING    = 'type_shadow_clustered';

sub symdump {
  my $nargs = scalar( my ( $target, ) = @_ );
  $nargs == 1     or croak "Passed $nargs arguments, Expected 1" . _E1;
  defined $target or croak "Expected defined target" . _E2;
  length $target  or croak "Expected target with non-zero length" . _E3;
  !ref $target    or croak "Expected scalar target" . _E4;
  _pp_key() . _pp_class($target);
}

sub has_feeds {
  my ( $desc, $page, @feeds ) = @_;
  require Test::More;
  my %has_feeds;
  for my $link ( $page->links('feed') ) {
    $has_feeds{ $link->href }++;
  }
  for my $feed (@feeds) {
    $has_feeds{$feed}--;
  }
  Test::More::note("Feeds for $desc: ");
  return Test::More::pass("No Unexpected / Missing Feeds in $desc") unless keys %has_feeds;

  my $failed = 0;
  for my $feed ( sort keys %has_feeds ) {
    if ( $has_feeds{$feed} > 0 ) {
      $failed++;
      Test::More::fail("$desc has unexpected extra $feed");
      next;
    }
    if ( $has_feeds{$feed} < 0 ) {
      $failed++;
      Test::More::fail("$desc is missing $feed");
      next;
    }
    Test::More::pass("$desc has feed $feed");
  }
  if ($failed) {
    Test::More::diag("\n---\nExpected feeds for $desc:");
    Test::More::diag( sprintf "- [%s]", join q[, ], sort @feeds );
    Test::More::diag("Got feeds for $desc:");
    Test::More::diag( sprintf "- [%s]", join q[, ], sort map { $_->href } $page->links('feed') );
    Test::More::diag("---");
  }
}

# -- no user servicable parts --
sub _class_functions {
  my ($class) = @_;
  Package::Stash->new($class)->list_all_symbols('CODE');
}

sub _function_type {
  my ($function) = @_;
  return 'PRIVATE'   if $function =~ /^_/;
  return 'TYPE_UTIL' if $function =~ /^(is_|assert_|to_)[A-Z]/;
  return 'PRIVATE'   if $function =~ /^[A-Z][A-Z]/;
  return 'TYPE'      if $function =~ /^[A-Z]/;
  return 'PUBLIC';
}

sub _hl_TYPE_UTIL {
  $_[0] =~ /^([^_]+_)(.*$)/;
  colored( \@TYPE_METHOD, $1 ) . colored( \@TYPE, $2 );
}
sub _hl_TYPE { colored( \@TYPE, $_[0] ) }
sub _hl_PUBLIC  { $_[1] ? colored( \@SHADOWED_PUBLIC,  $_[0] ) : colored( \@PUBLIC,  $_[0] ) }
sub _hl_PRIVATE { $_[1] ? colored( \@SHADOWED_PRIVATE, $_[0] ) : colored( \@PRIVATE, $_[0] ) }

sub _pp_function {
  return __PACKAGE__->can( '_hl_' . _function_type( $_[0] ) )->(@_);
}

sub _pp_key {
  my @tokens;
  push @tokens, "Public Function: " . _hl_PUBLIC("foo_example");
  push @tokens, "Type Constraint: " . _hl_TYPE("TypeName");
  push @tokens, "Type Constraint Utility: " . _hl_TYPE_UTIL("typeop_TypeName");
  push @tokens, "Private/Boring Function: " . _hl_PRIVATE("foo_example");
  if ($SHOW_SHADOWED) {
    push @tokens, "Public Function shadowed by higher scope: " . _hl_PUBLIC( "shadowed_example", 1 );
    push @tokens, "Private/Boring Function shadowed by higher scope: " . _hl_PRIVATE( "shadowed_example", 1 );
  }
  push @tokens, "No Functions: ()";
  return sprintf "Key:\n$INDENT%s\n\n", join qq[\n$INDENT], @tokens;
}

sub _mg_sorted {
  my (%functions) = @_;
  if ($SHOW_SHADOWED) {
    return ( [ sort { lc($a) cmp lc($b) } keys %functions ] );
  }
  return ( [ grep { !$functions{$_} } sort { lc($a) cmp lc($b) } keys %functions ] );
}

sub _mg_type_shadow_clustered {
  my (%functions) = @_;
  my %clusters;
  for my $function ( keys %functions ) {
    my $shadow = '.shadowed' x !!$functions{$function};
    $clusters{ _function_type($function) . $shadow }{$function} = $functions{$function};
  }
  my @out;
  for my $type ( map { $_, "$_.shadowed" } qw( PUBLIC PRIVATE TYPE TYPE_UTIL ) ) {
    next unless exists $clusters{$type};
    push @out, _mg_sorted( %{ $clusters{$type} } );
  }
  return @out;
}

sub _mg_type_clustered {
  my (%functions) = @_;
  my %clusters;
  for my $function ( keys %functions ) {
    $clusters{ _function_type($function) }{$function} = $functions{$function};
  }
  my @out;
  for my $type (qw( PUBLIC PRIVATE TYPE TYPE_UTIL )) {
    next unless exists $clusters{$type};
    push @out, _mg_sorted( %{ $clusters{$type} } );
  }
  return @out;
}

sub _mg_aleph {
  my (%functions) = @_;
  my %clusters;
  for my $function ( keys %functions ) {
    $clusters{ lc( substr $function, 0, 1 ) }{$function} = $functions{$function};
  }
  my @out;
  for my $key ( sort keys %clusters ) {
    push @out, _mg_sorted( %{ $clusters{$key} } );
  }
  return @out;

}

sub _pp_functions {
  my (%functions) = @_;
  my (@clusters)  = __PACKAGE__->can( '_mg_' . $CLUSTERING )->(%functions);
  my (@out_clusters);
  for my $cluster (@clusters) {
    my $cluster_out = '';

    my @functions = @{$cluster};
    while (@functions) {
      my $line = $INDENT;
      while ( @functions and length $line < $MAX_WIDTH ) {
        my $function = shift @functions;
        $line .= $function . q[, ];
      }
      $cluster_out .= "$line\n";
    }

    # Suck up trailing ,
    $cluster_out =~ s/,[ ]\n\z/\n/;
    $cluster_out =~ s{(\w+)}{ _pp_function($1, $functions{$1}) }ge;
    push @out_clusters, $cluster_out;
  }
  return join qq[\n], @out_clusters;
}

sub _pp_class {
  my ($class)        = @_;
  my $out            = q[];
  my $pad            = q[ ] x 4;
  my $seen_functions = {};
  for my $isa ( @{ mro::get_linear_isa($class) } ) {
    $out .= colored( ['green'], $isa ) . ":";
    my $section        = "";
    my $line           = $pad;
    my (@my_functions) = _class_functions($isa);
    if ( not @my_functions ) {
      $out .= " ()\n";
      next;
    }
    else { $out .= "\n" }
    my %function_map;
    for my $function (@my_functions) {
      if ( not exists $seen_functions->{$function} ) {
        $seen_functions->{$function} = $isa;
      }
      $function_map{$function} = ( $seen_functions->{$function} ne $isa );
    }
    $out .= _pp_functions(%function_map) . "\n";

    next;
  }
  return $out;
}

1;
