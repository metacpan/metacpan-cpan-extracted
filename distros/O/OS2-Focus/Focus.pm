package OS2::Focus;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OS2::Focus ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'short' => [ qw(
	FocusChange
	QueryFocus
	SetFocus
) ] ,	'win' => [ qw(
	HWND_DESKTOP
	WinFocusChange
	WinQueryFocus
	WinSetFocus
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'short'} }, @{ $EXPORT_TAGS{'win'} },  );

@EXPORT = (

);
$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined OS2::Focus macro $constname";
	}
    }
    {  no strict 'refs';
       # Next line doesn't help with older Perls; in newers: no such warnings
       # local $^W = 0;		# Prototype mismatch: sub XXX vs ()
       if ($] >= 5.00561) {	# Fixed between 5.005_53 and 5.005_61
	 *$AUTOLOAD = sub () { $val };
       } else {
	 *$AUTOLOAD = sub { $val };
       }
    }
    goto &$AUTOLOAD;
}

bootstrap OS2::Focus $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OS2::Focus - Perl extension to get and set focus on PM windows.

=head1 SYNOPSIS

  use OS2::Focus ':short';
  $old_focus = QueryFocus;
  ...				# Say, create some Tk windows...
  SetFocus($old_focus) or warn "Cannot change focus, the error is $^E.\n".

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head2 Exportable constants

C<HWND_DESKTOP> is exported with a tag C<:win>.

=head2 Exportable functions

See C<PMREF> documentation for the following functions:

  BOOL WinFocusChange (HWND hwndDesktop, HWND hwndSetFocus, ULONG flFocusChange)
  HWND WinQueryFocus (HWND hwndDesktop)
  BOOL WinSetFocus (HWND hwndDesktop, HWND hwndSetFocus)

which are exported with a tag C<:win>.  Use C<HWND_DESKTOP> (exported with
the same tag) as the first argument for these functions.

Prefix C<Win> can be removed, the resulted functions omit the first argument,
and fill $! and $^E on error.  These functions are exported with a tag
C<:short>.

=head1 AUTHOR

Ilya Zakharevich, ilya@math.ohio-state.edu.

=head1 SEE ALSO

perl(1).

=cut
