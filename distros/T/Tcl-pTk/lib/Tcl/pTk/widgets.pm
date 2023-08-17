#

=head1 NAME

Tcl::pTk::widgets -  Convenience Module for loading Tcl::pTk Widgets


=head1 SYNOPSIS

        use Tcl::pTk;
        
        # Load Text and Tree widgets (without have to call our on separate lines.)
        use Tcl::pTk::widgets qw/ Text Tree /;
        
        # Above is equivalent to
        use Tcl::pTk::Text;
        use Tcl::pTk::Tree;

=head1 DESCRIPTION

I<Tcl::pTk::widget> is a module for loading multiple widgets, without having to call-out each on separate
'use' lines. See the I<SYNOPSIS> line above for examples.

=cut



package Tcl::pTk::widgets;
use warnings;
use strict;
use Carp;

our ($VERSION) = ('1.11');

sub import
{
 my $class = shift;
 foreach (@_)
  {
   local $SIG{__DIE__} = \&Carp::croak;
   # carp "$_ already loaded" if (exists $INC{"Tk/$_.pm"});
   next if ref $$Tcl::pTk::Widget::_ptk2tcltk{$_} eq 'ARRAY';
   require "Tcl/pTk/$_.pm";
  }
}

1;
__END__
