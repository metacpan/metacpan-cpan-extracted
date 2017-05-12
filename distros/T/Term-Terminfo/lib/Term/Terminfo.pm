#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

package Term::Terminfo;

use strict;
use warnings;

use Carp;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Term::Terminfo> - access the F<terminfo> database

=head1 SYNOPSIS

 use Term::Terminfo;

 my $ti = Term::Terminfo->new;

 printf "This terminal %s do overstrike\n",
    $ti->getflag('os') ? "can" : "cannot";

 printf "Tabs on this terminal are initially every %d columns\n",
    $ti->getnum('it');


 printf "This terminal %s do overstrike\n",
    $ti->flag_by_varname('over_strike') ? "can" : "cannot";

 printf "Tabs on this terminal are initially every %d columns\n",
    $ti->num_by_varname('init_tabs');

=head1 DESCRIPTION

Objects in this class provide access to F<terminfo> database entires.

This database provides information about a terminal, in three separate sets of
capabilities. Flag capabilities indicate the presence of a particular ability,
feature, or bug simply by their presence. Number capabilities give the size,
count or other numeric detail of some feature of the terminal. String
capabilities are usually control strings that the terminal will recognise, or
send.

Capabilities each have two names; a short name called the capname, and a
longer name called the varname. This class provides two sets of methods, one
that works on capnames, one that work on varnames.

This module optionally uses F<unibilium> to access the L<terminfo(5)>
database, if it is available at compile-time. If not, it will use
F<< <term.h> >> and F<-lcurses>. For more detail, see the L</SEE ALSO> section
below.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $ti = Term::Terminfo->new( $termtype )

Constructs a new C<Term::Terminfo> object representing the given termtype. If
C<$termtype> is not defined, C<$ENV{TERM}> will be used instead. If that
variable is empty, C<vt100> will be used.

=cut

sub new
{
   my $class = shift;
   my ( $termtype ) = @_;

   # If we've really no idea, call it a VT100
   $termtype ||= $ENV{TERM} || "vt100";

   my $self = bless {
      term => $termtype,
   }, $class;

   $self->_init;

   return $self;
}

=head1 METHODS

=cut

=head2 $bool = $ti->getflag( $capname )

=head2 $num = $ti->getnum( $capname )

=head2 $str = $ti->getstr( $capname )

Returns the value of the flag, number or string capability of the given
capname.

=cut

sub getflag
{
   my $self = shift;
   my ( $capname ) = @_;
   return $self->{flags_by_capname}{$capname};
}

sub getnum
{
   my $self = shift;
   my ( $capname ) = @_;
   return $self->{nums_by_capname}{$capname};
}

sub getstr
{
   my $self = shift;
   my ( $capname ) = @_;
   return $self->{strs_by_capname}{$capname};
}

=head2 $bool = $ti->flag_by_varname( $varname )

=head2 $num = $ti->num_by_varname( $varname )

=head2 $str = $ti->str_by_varname( $varname )

Returns the value of the flag, number or string capability of the given
varname.

=cut

sub flag_by_varname
{
   my $self = shift;
   my ( $varname ) = @_;
   return $self->{flags_by_varname}{$varname};
}

sub num_by_varname
{
   my $self = shift;
   my ( $varname ) = @_;
   return $self->{nums_by_varname}{$varname};
}

sub str_by_varname
{
   my $self = shift;
   my ( $varname ) = @_;
   return $self->{strs_by_varname}{$varname};
}

=head2 @capnames = $ti->flag_capnames

=head2 @capnames = $ti->num_capnames

=head2 @capnames = $ti->str_capnames

Return lists of the capnames of the supported flags, numbers, and strings

=cut

sub flag_capnames
{
   my $self = shift;
   return sort keys %{ $self->{flags_by_capname} };
}

sub num_capnames
{
   my $self = shift;
   return sort keys %{ $self->{nums_by_capname} };
}

sub str_capnames
{
   my $self = shift;
   return sort keys %{ $self->{strs_by_capname} };
}

=head2 @varnames = $ti->flag_varnames

=head2 @varnames = $ti->num_varnames

=head2 @varnames = $ti->str_varnames

Return lists of the varnames of the supported flags, numbers, and strings

=cut

sub flag_varnames
{
   my $self = shift;
   return sort keys %{ $self->{flags_by_varname} };
}

sub num_varnames
{
   my $self = shift;
   return sort keys %{ $self->{nums_by_varname} };
}

sub str_varnames
{
   my $self = shift;
   return sort keys %{ $self->{strs_by_varname} };
}

=head1 TODO

This distribution provides a small accessor interface onto F<terminfo>. It was
originally created simply so I can get at the C<bce> capability flag of the
current terminal, because F<screen> unlike every other terminal ever, doesn't
do this. Grrr.

It probably also wants more accessors for things like C<tparm> and C<tputs>.
I may at some point consider them.

=head1 SEE ALSO

=over 4

=item *

C<unibilium> - a terminfo parsing library -
<https://github.com/mauke/unibilium>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
