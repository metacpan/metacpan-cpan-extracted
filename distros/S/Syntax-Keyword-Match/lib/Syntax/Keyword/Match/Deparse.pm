#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Match::Deparse 0.15;

use v5.14;
use warnings;

use B qw( opnumber OPf_KIDS OPf_STACKED );

require B::Deparse;

use constant {
   OP_AND         => opnumber('and'),
   OP_COND_EXPR   => opnumber('cond_expr'),
   OP_CUSTOM      => opnumber('custom'),
   OP_ENTER       => opnumber('enter'),
   OP_LINESEQ     => opnumber('lineseq'),
   OP_MATCH       => opnumber('match'),
   OP_NULL        => opnumber('null'),
   OP_OR          => opnumber('or'),
   OP_PADSV       => opnumber('padsv'),
   OP_PADSV_STORE => opnumber('padsv_store'),
   OP_SASSIGN     => opnumber('sassign'),
};

=head1 NAME

C<Syntax::Keyword::Match::Deparse> - L<B::Deparse> support for L<Syntax::Keyword::Match>

=head1 DESCRIPTION

Loading this module will apply some hacks onto L<B::Deparse> that attempts to
provide deparse support for code which uses the syntax provided by
L<Syntax::Keyword::Match>.

=cut

my $orig_pp_leave;
{
   no warnings 'redefine';
   no strict 'refs';
   $orig_pp_leave = *{"B::Deparse::pp_leave"}{CODE};
   *{"B::Deparse::pp_leave"} = \&pp_leave;
}

sub op_dump
{
   my $o = shift;
   my $ret = $o->name;

   my $kid = $o->flags & OPf_KIDS ? $o->first : undef;
   if( $kid && !B::Deparse::null($kid) ) {
      $ret .= "[\n";
      while( $kid && !B::Deparse::null($kid) ) {
         $ret .= join( "\n", map { "  $_" } split m/\n/, op_dump($kid) ) . "\n";
         $kid = $kid->sibling;
      }
      $ret .= "]";
   }

   return $ret;
}

my %operator_for_name = (
   eq    => "==",
   seq   => "eq",
   match => "=~",
   isa   => "isa",
);

sub operator_name
{
   my ( $o ) = @_;
   my $opname = $o->name;
   return $operator_for_name{$opname} // die "TODO: operator name of $opname";
}

sub is_match_on_topic
{
   my ( $o, $topicix ) = @_;

   $o->type == OP_MATCH or return 0;

   if( $^V ge v5.22.0 ) {
      # Perl 5.22 could do OP_MATCH on targ
      return $o->targ == $topicix;
   }
   elsif( $o->flags & OPf_STACKED ) {
      my $kid = $o->first;
      return $kid->type == OP_PADSV && $kid->targ == $topicix;
   }
   else {
      return 0;
   }
}

sub pp_leave
{
   my $self = shift;
   my ( $op ) = @_;

   my $enter = $op->first;
   $enter->type == OP_ENTER or
      return $self->$orig_pp_leave( @_ );

   my $assign = $enter->sibling;
   my $topicix; my $topicop;
   if( $^V ge v5.38.0 ) {
      # Since perl 5.38.0 we had OP_PADSV_STORE
      $assign->type == OP_PADSV_STORE or
         return $self->$orig_pp_leave( @_ );

      my $varname = $self->padname( $topicix = $assign->targ );
      $varname eq '$(Syntax::Keyword::Match/topic)' or
         return $self->$orig_pp_leave( @_ );

      $topicop = $assign->first;
   }
   else {
      # Earlier perls had regular OP_SASSIGN with OP_PADSV target
      $assign->type == OP_SASSIGN or
         return $self->$orig_pp_leave( @_ );

      $topicop = $assign->first;

      my $padsvop = $topicop->sibling;
      $padsvop->type == OP_PADSV or
         return $self->$orig_pp_leave( @_ );

      my $varname = $self->padname( $topicix = $padsvop->targ );
      $varname eq '$(Syntax::Keyword::Match/topic)' or
         return $self->$orig_pp_leave( @_ );
   }

   my $cmpop;
   my @caseblocks;
   my $kid = $assign->sibling;
   while( !B::Deparse::null($kid) ) {
      if( $kid->type == OP_NULL ) {
         $kid = $kid->first;
      }

      if( $kid->type == OP_LINESEQ ) {
         push @caseblocks, "default {" . B::Deparse::scopeop( 1, $self, $kid, 0 ) . "}";
         last;
      }

      my ( $condop, $block );
      if( $kid->type == OP_COND_EXPR ) {
         $condop = $kid->first;
         $block = $condop->sibling;
         $kid = $block->sibling;
      }
      elsif( $kid->type == OP_AND ) {
         $condop = $kid->first;
         $block = $condop->sibling;
         $kid = $block->sibling; # should be NULL
      }
      else {
         warn op_dump($kid);
         die "TODO: not sure how to handle kid=", $kid->name;
      }

      my @cases;
      while( $condop and !B::Deparse::null($condop) ) {
         if( $condop->type == OP_NULL ) {
            $condop = $condop->first;
         }

         my $cond1;
         if( $condop->type == OP_OR ) {
            $cond1 = $condop->first;
            $condop = $cond1->sibling;
         }
         else {
            $cond1 = $condop;
            $condop = undef;
         }

         my $condlhs = $cond1->first;
         if( is_match_on_topic( $cond1, $topicix ) ) {
            die "Unsure how to handle mismatched case cond ops"
               if $cmpop and $cmpop->type != $cond1->type;
            $cmpop //= $cond1;
            # Need to mangle out the target name
            my $pattern = $self->deparse( $cond1, @_ );
            $pattern =~ s{^\(\$\(Syntax::Keyword::Match/topic\) =~ (.*)\)$}{m$1};
            push @cases, "case ($pattern)";
         }
         elsif( !B::Deparse::null($condlhs) and $condlhs->type == OP_PADSV and $condlhs->targ == $topicix ) {
            # There's no way perl code could see the topic padname, so this
            # must be a plain case(EXPR)
            my $condval = $condlhs->sibling;

            # TODO: custom ops might be weird
            die "Unsure how to handle mismatched case cond ops"
               if $cmpop and $cmpop->type != $cond1->type;
            $cmpop //= $cond1;

            push @cases, "case (" . $self->deparse( $condval, @_ ) . ")";
         }
         else {
            my $cond = $self->deparse( $cond1, @_ );
            $cond =~ s/^\((.*)\)$/$1/; # trim surrounding () so we don't get two
            push @cases, "case if ($cond)";
         }
      }

      push @caseblocks, join( ", ", @cases ) .
         " {" . B::Deparse::scopeop( 1, $self, $block, 0 ) . "}";
   }

   my $topic = $self->deparse( $topicop, @_ );

   # Ugh it'd be great if B::Deparse had a solution to this
   my $cmp = operator_name( $cmpop );

   return "match ($topic : $cmp) {\n\t" . join( "\n", @caseblocks ) . "\n\b}";
}

=head1 TODO

=over 4

=item *

Integrate with custom ops (C<equ>, C<eqr>, etc..)

=item *

Handle the experimental dispatch op feature

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
