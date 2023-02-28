#<<<
use strict; use warnings;
#>>>

package Test::Builder::SubtestSelection;

our $VERSION = '0.001002';

BEGIN {
  require parent;
  local $ENV{ TB_NO_EARLY_INIT } = 1;
  parent->import( qw( Test::Builder ) );
}
use Getopt::Long qw( GetOptions :config posix_default );

my @subtest_selection;
# parse @ARGV
GetOptions(
  's|subtest=s' => sub {
    ( undef, my $opt_value ) = @_;
    push @subtest_selection, eval { qr/$opt_value/ } ? $opt_value : "\Q$opt_value\E";
  }
);

sub import { shift->new; }

# override Test::Builder::subtest()
sub subtest {
  my ( $self, $name ) = @_;

  my $class        = ref $self;
  my $current_test = $self->current_test + 1;
  if (
    defined $self->parent    # ignore nested subtests
    or not @subtest_selection
    or grep { m/\A [1-9]\d* \z/x ? $current_test == $_ : $name =~ m/$_/ } @subtest_selection
    )
  {
    goto $class->can( 'SUPER::subtest' );
  } else {
    $self->skip( "forced by $class", $name );
  }
}

1;
