#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Test::Base::has_file_content;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex -base;
use base qw(Rex::Test::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my ( $pkg, $file ) = caller(0);

  return $self;
}

sub run_test {
  my ( $self, $file, $wanted_content ) = @_;
  my $content = cat $file;

  $self->ok( $content eq $wanted_content, "File $file has content: $content" );
}

1;
