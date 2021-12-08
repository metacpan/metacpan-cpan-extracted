# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Text::Structure;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';
use List::Util     'first';


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;
    $self->{OTS_subs}  = [];
    $self->{OTS_level} = delete $args->{level}
        or panic "no level defined for structural component";
    $self;
}


sub emptyExtension($)
{   my ($self, $container) = @_;

    my $new = ref($self)->new
     ( name      => $self->name
     , linenr    => -1
     , level     => $self->level
     , container => $container
     );
    $new->extends($self);
    $new;
}

#-------------------------------------------


sub level()   {shift->{OTS_level}}


sub niceName()
{   my $name = shift->name;
    $name =~ m/[a-z]/ ? $name : ucfirst(lc $name);
}

#-------------------------------------------


sub path() { panic "Not implemented" }


sub findEntry($) { panic "Not implemented" }

#-------------------------------------------


sub all($@)
{   my ($self, $method) = (shift, shift);
    $self->$method(@_);
}


sub isEmpty()
{   my $self = shift;

    my $manual = $self->manual;
    return 0 if $self->description !~ m/^\s*$/;
    return 0 if first {!$manual->inherited($_)}
        $self->examples, $self->subroutines;

    my @nested
      = $self->isa('OODoc::Text::Chapter')    ? $self->sections
      : $self->isa('OODoc::Text::Section')    ? $self->subsections
      : $self->isa('OODoc::Text::SubSection') ? $self->subsubsections
      : return 1;

    not first {!$_->isEmpty} @nested;
}

#-------------------

sub addSubroutine(@)
{  my $self = shift;
   push @{$self->{OTS_subs}}, @_;
   $_->container($self) for @_;
   $self;
}


sub subroutines() { @{shift->{OTS_subs}} }


sub subroutine($)
{   my ($self, $name) = @_;
    first {$_->name eq $name} $self->subroutines;
}


sub setSubroutines($)
{   my $self = shift;
    $self->{OTS_subs} = shift || [];
}

#-------------------------------------------



1;
