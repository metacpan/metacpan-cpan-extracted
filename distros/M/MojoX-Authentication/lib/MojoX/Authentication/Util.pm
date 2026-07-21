package MojoX::Authentication::Util;
use v5.24;
use Carp;
use English qw< -no_match_vars >;
use experimental qw< signatures >;

use Scalar::Util qw< blessed >;
use Exporter qw< import >;

our @EXPORT_OK = qw<
   coercer_for
>;

sub coercer_for ($name, $class) {
   return sub ($x) {
      return ($x->can($name) // sub { $_[0] })->($x) if blessed($x);
      return $x->() if ref($x) eq 'CODE'; # factory sub

      # assume we have to get a new instance
      my $module_file = "$class.pm" =~ s{::}{/}rgmxs;
      require $module_file;
      return $class->new($x);
   }
}


1;
__END__


