=head1 NAME

Bio::Polloc::GroupCriteria::operator::seq - A sequence operator

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::GroupCriteria::operator::seq;
use base qw(Bio::Polloc::GroupCriteria::operator);
use strict;
use Bio::Seq;
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

A L<Bio::Seq> object.

=cut

sub operate {
   my $self = shift;
   return $self->val if defined $self->val;
   $self->throw('Bad operators', $self->operators)
   	unless ref($self->operators)
	and ref($self->operators)=~/ARRAY/;
   if($self->operation =~ /^\s*sequence\s*$/i){
      my $locus = $self->operators->[0]->operate;
      $self->operators->[1] = 0 + ($self->operators->[1] || 0);
      $self->operators->[2] = 0 + ($self->operators->[2] || 0);
      $self->operators->[3] = 0 + ($self->operators->[3] || 0);
      my($from, $to);
      if($self->operators->[1]<0){
         $from = $locus->from + $self->operators->[2];
	 $to = $locus->from + $self->operators->[3];
      }elsif($self->operators->[1]>0){
         $from = $locus->to + $self->operators->[2];
	 $to = $locus->to + $self->operators->[3];
      }else{
         $from = $locus->from + $self->operators->[2];
	 $to = $locus->to - $self->operators->[3];
      }
      my($start, $end) = ($from<=$to) ? ($from, $to) : ($to, $from);
      $start = 1 unless $start>0;
      $end = $locus->seq->length unless $end < $locus->seq->length;
      my $seq = Bio::Seq->new(-seq=>$locus->seq->subseq($start, $end));
      return $seq->revcom if $from > $to;
      return $seq;
   }
   if($self->operation =~ /^\s*reverse\s*$/i){
      $self->throw('Unexpected operator', $self->operators->[0]) unless
      		UNIVERSAL::isa($self->operators->[0], 'isa')
		and $self->operators->[0]->isa('Bio::Seq');
      return $self->operators->[0]->revcom;
   }
   $self->throw("Unknown numeric operation", $self->operation);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize { }

1;
