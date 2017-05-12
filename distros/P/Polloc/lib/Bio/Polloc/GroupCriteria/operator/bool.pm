=head1 NAME

Bio::Polloc::GroupCriteria::operator::bool - A boolean operator

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::GroupCriteria::operator::bool;
use base qw(Bio::Polloc::GroupCriteria::operator);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization method.

=head3 Arguments

See L<Bio::Polloc::GroupCriteria::operator->new()>

=head3 Returns

A L<Bio::Polloc::GroupCriteria::operator::bool> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 operate

=head3 Returns

A boolean value.

=cut

sub operate {
   my $self = shift;
   return $self->val if defined $self->val;
   $self->throw('Bad operators', $self->operators)
   	unless ref($self->operators) and ref($self->operators)=~/ARRAY/;
   my $o1 = $self->operators->[0]->operate;
   $self->throw("Undefined first operator", $self->operators) unless defined $o1;
   return (not $o1)	if $self->operation =~ /^\s*(?:\!|not)\s*$/i;
   my $o2 = $self->operators->[1]->operate;
   $self->throw("Undefined second operator") unless defined $o2;
   return ($o1 > $o2)	if $self->operation =~ /^\s*(?:>|gt)\s*$/i;
   return ($o1 < $o2)	if $self->operation =~ /^\s*(?:<|lt)\s*$/i;
   return ($o1 >= $o2)	if $self->operation =~ /^\s*(?:>=|ge)\s*$/i;
   return ($o1 <= $o2)	if $self->operation =~ /^\s*(?:<=|le)\s*$/i;
   return ($o1 and $o2)	if $self->operation =~ /^\s*(?:&&?|and)\s*$/i;
   return ($o1 or $o2)	if $self->operation =~ /^\s*(?:\|\|?|or)\s*$/i;
   return ($o1 xor $o2)	if $self->operation =~ /^\s*(?:\^|xor)\s*$/i;
   $self->throw("Unknown boolean operation", $self->operation);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize { }

1;
