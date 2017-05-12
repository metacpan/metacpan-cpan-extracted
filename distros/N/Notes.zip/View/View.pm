package Notes::View;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

require Notes::Object;

our @ISA = qw(Exporter DynaLoader Notes::Object);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Notes::View ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	COLOR_BLACK
	COLOR_BLUE 
	COLOR_CYAN
	COLOR_DARK_BLUE
	COLOR_DARK_CYAN
	COLOR_DARK_GREEN
	COLOR_DARK_MAGENTA
	COLOR_DARK_RED
	COLOR_DARK_YELLOW 
	COLOR_GRAY
	COLOR_GREEN 
	COLOR_LIGHT_GRAY
	COLOR_MAGENTA 
	COLOR_RED
	COLOR_WHITE
	COLOR_YELLOW	
	VW_SPACING_SINGLE
	VW_SPACING_ONE_POINT_25
	VW_SPACING_ONE_POINT_50	  
	VW_SPACING_ONE_POINT_75
	VW_SPACING_DOUBLE
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    local $! = 0;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Notes::View macro $constname";
	}
    }
    {
	no strict 'refs';
	no warnings;
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

bootstrap Notes::View $VERSION;

# Preloaded methods go here.

sub aliases()
{
	my $invocant = shift;
	my @values = split(/\|/, $invocant->name());
	shift @values;
	return join("|",@values);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Notes::View - Perl extension for the Lotus Notes C API

=head1 SYNOPSIS

  use Notes::View;

=head1 DESCRIPTION

Stub documentation for Notes::View, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.


=head2 EXPORT

None by default.


=head1 AUTHOR

Cloutier, C. <lt>christian.cloutier@eds.com<gt>

With initial work, help and support from Martin Brech <lt>martin.brech@siemens.com<gt>

=head1 SEE ALSO

L<perl>.

=cut