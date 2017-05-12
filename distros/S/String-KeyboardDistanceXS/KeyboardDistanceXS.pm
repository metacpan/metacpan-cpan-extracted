package String::KeyboardDistanceXS;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use String::KeyboardDistanceXS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

my @EXPORT_SUBS = qw(
  qwertyKeyboardDistance
  qwertyKeyboardDistanceMatch
);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_SUBS, qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined String::KeyboardDistanceXS macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap String::KeyboardDistanceXS $VERSION;


my $initStatus = initQwertyMap();


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

String::KeyboardDistanceXS - String Comparison Algorithm

=head1 SYNOPSIS

  use String::KeyboardDistanceXS qw( :all );
  my $s1 = 'Apple';
  my $s2 = 'Wople';

  # compute a match probability
  my $pr = qwertyKeyboardDistanceMatch($s1,$s2);

  # find the keyboard distance between two strings
  my $dst = qwertyKeyboardDistance('IBM','HAL');


=head1 DESCRIPTION

This is an XS implementation of the main qwerty functions for computing the
distance and match probabilities from the String::KeyboardDistance module.
Please see the documentation for String::KeyboardDistance for more about these
functions.

Since these functions are implemented as XS, in C, they are significantly
faster than the Perl based functions in String::KeyboardDistance.  That
is the primary reason for this module, performance.

=head2 TODO

This module only implements 2 of the functions from the Perl based module.
We should match the API from the other module as well as possible.  Some 
of the features will not be possible with this module, namely making the 
keyboard maps easily accessable to Perl code.

=head2 EXPORT

None by default.  Functions are exported with the :all tag.

  qwertyKeyboardDistance
  qwertyKeyboardDistanceMatch

=head1 AUTHOR

 Kyle R. Burton
 krburton@hmsonline.com
 kburton@hmsonline.com
 HMS
 625 Ridge Pike
 Building E
 Suite 400
 Conshohocken, PA 19428

=head1 SEE ALSO

perl(1).  String::Approx.  Text::DoubleMetaphone.  String::Similarity.
String::KeyboardDistance.

=cut
