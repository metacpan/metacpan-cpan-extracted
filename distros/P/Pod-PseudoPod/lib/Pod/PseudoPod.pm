
package Pod::PseudoPod;
use Pod::Simple;
@ISA = qw(Pod::Simple);
use strict;

use vars qw(
  $VERSION @ISA
  @Known_formatting_codes  @Known_directives
  %Known_formatting_codes  %Known_directives
);

@ISA = ('Pod::Simple');
$VERSION = '0.15';

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }

@Known_formatting_codes = qw(A B C E F G H I L M N R S T U X Z);
%Known_formatting_codes = map(($_=>1), @Known_formatting_codes);
@Known_directives       = qw(head0 head1 head2 head3 head4 item over back headrow bodyrows row cell);
%Known_directives       = map(($_=>'Plain'), @Known_directives);

sub new {
  my $self = shift;
  my $new = $self->SUPER::new();

  $new->{'accept_codes'} = { map( ($_=>$_), @Known_formatting_codes ) };
  $new->{'accept_directives'} = \%Known_directives;
  return $new;
}

sub _handle_element_start {
  my ($self, $element, $flags) = @_;

  $element =~ tr/-:./__/;

  my $sub = $self->can('start_' . $element);
  $sub->($self, $flags) if $sub; 
}

sub _handle_text {
  my $self = shift;

  my $sub = $self->can('handle_text');
  $sub->($self, @_) if $sub;
}

sub _handle_element_end {
  my ($self, $element, $flags) = @_;
  $element =~ tr/-:./__/;

  my $sub = $self->can('end_' . $element);
  $sub->($self, $flags) if $sub;
}

sub nix_Z_codes { $_[0]{'nix_Z_codes'} = $_[1] }

# Largely copied from Pod::Simple::_treat_Zs, modified to optionally
# keep Z elements, and so it doesn't complain about Zs with content.
#
sub _treat_Zs {  # Nix Z<...>'s
  my($self,@stack) = @_;

  my($i, $treelet);
  my $start_line = $stack[0][1]{'start_line'};

  # A recursive algorithm implemented iteratively!  Whee!

  while($treelet = shift @stack) {
    for($i = 2; $i < @$treelet; ++$i) { # iterate over children
      next unless ref $treelet->[$i];  # text nodes are uninteresting
      unless($treelet->[$i][0] eq 'Z') {
        unshift @stack, $treelet->[$i]; # recurse
        next;
      }
        
      if ($self->{'nix_Z_codes'}) {
        #DEBUG > 1 and print "Nixing Z node @{$treelet->[$i]}\n";
        splice(@$treelet, $i, 1); # thereby just nix this node.
        --$i;
      }

    }
  }
  
  return;
}

# The _ponder_* methods override the _ponder_* methods from
# Pod::Simple::BlackBox to add or alter functionality.

sub _ponder_paragraph_buffer {

  # Para-token types as found in the buffer.
  #   ~Verbatim, ~Para, ~end, =head1..4, =for, =begin, =end,
  #   =over, =back, =item
  #   and the null =pod (to be complained about if over one line)
  #
  # "~data" paragraphs are something we generate at this level, depending on
  # a currently open =over region

  # Events fired:  Begin and end for:
  #                   directivename (like head1 .. head4), item, extend,
  #                   for (from =begin...=end, =for),
  #                   over-bullet, over-number, over-text, over-block,
  #                   item-bullet, item-number, item-text,
  #                   Document,
  #                   Data, Para, Verbatim
  #                   B, C, longdirname (TODO -- wha?), etc. for all directives
  # 

  my $self = $_[0];
  my $paras;
  return unless @{$paras = $self->{'paras'}};
  my $curr_open = ($self->{'curr_open'} ||= []);

  DEBUG > 10 and print "# Paragraph buffer: <<", pretty($paras), ">>\n";

  # We have something in our buffer.  So apparently the document has started.
  unless($self->{'doc_has_started'}) {
    $self->{'doc_has_started'} = 1;
    
    my $starting_contentless;
    $starting_contentless =
     (
       !@$curr_open  
       and @$paras and ! grep $_->[0] ne '~end', @$paras
        # i.e., if the paras is all ~ends
     )
    ;
    DEBUG and print "# Starting ", 
      $starting_contentless ? 'contentless' : 'contentful',
      " document\n"
    ;
    
    $self->_handle_element_start('Document',
      {
        'start_line' => $paras->[0][1]{'start_line'},
        $starting_contentless ? ( 'contentless' => 1 ) : (),
      },
    );
  }

  my($para, $para_type);
  while(@$paras) {
    last if @$paras == 1 and
      ( $paras->[0][0] eq '=over' or $paras->[0][0] eq '~Verbatim'
        or $paras->[0][0] eq '=item' )
    ;
    # Those're the three kinds of paragraphs that require lookahead.
    #   Actually, an "=item Foo" inside an <over type=text> region
    #   and any =item inside an <over type=block> region (rare)
    #   don't require any lookahead, but all others (bullets
    #   and numbers) do.

# TODO: winge about many kinds of directives in non-resolving =for regions?
# TODO: many?  like what?  =head1 etc?

    $para = shift @$paras;
    $para_type = $para->[0];

    DEBUG > 1 and print "Pondering a $para_type paragraph, given the stack: (",
      $self->_dump_curr_open(), ")\n";
    
    if($para_type eq '=for') {
      next if $self->_ponder_for($para,$curr_open,$paras);
    } elsif($para_type eq '=begin') {
      next if $self->_ponder_begin($para,$curr_open,$paras);
    } elsif($para_type eq '=end') {
      next if $self->_ponder_end($para,$curr_open,$paras);
    } elsif($para_type eq '~end') { # The virtual end-document signal
      next if $self->_ponder_doc_end($para,$curr_open,$paras);
    }


    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    if(grep $_->[1]{'~ignore'}, @$curr_open) {
      DEBUG > 1 and
       print "Skipping $para_type paragraph because in ignore mode.\n";
      next;
    }
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

    if($para_type eq '=pod') {
      $self->_ponder_pod($para,$curr_open,$paras);
    } elsif($para_type eq '=over') {
      next if $self->_ponder_over($para,$curr_open,$paras);
    } elsif($para_type eq '=back') {
      next if $self->_ponder_back($para,$curr_open,$paras);
    } elsif($para_type eq '=row') {
      next if $self->_ponder_row_start($para,$curr_open,$paras);
      
    } else {
      # All non-magical codes!!!
      
      # Here we start using $para_type for our own twisted purposes, to
      #  mean how it should get treated, not as what the element name
      #  should be.

      DEBUG > 1 and print "Pondering non-magical $para_type\n";

      # In tables, the start of a headrow or bodyrow also terminates an 
      # existing open row.
      if($para_type eq '=headrow' || $para_type eq '=bodyrows') {
        $self->_ponder_row_end($para,$curr_open,$paras);
      }

      # Enforce some =headN discipline
      if($para_type =~ m/^=head\d$/s
         and ! $self->{'accept_heads_anywhere'}
         and @$curr_open
         and $curr_open->[-1][0] eq '=over'
      ) {
        DEBUG > 2 and print "'=$para_type' inside an '=over'!\n";
        $self->whine(
          $para->[1]{'start_line'},
          "You forgot a '=back' before '$para_type'"
        );
        unshift @$paras, ['=back', {}, ''], $para;   # close the =over
        next;
      }


      if($para_type eq '=item') {
        next if $self->_ponder_item($para,$curr_open,$paras);
        $para_type = 'Plain';
        # Now fall thru and process it.

      } elsif($para_type eq '=extend') {
        # Well, might as well implement it here.
        $self->_ponder_extend($para);
        next;  # and skip
      } elsif($para_type eq '=encoding') {
        # Not actually acted on here, but we catch errors here.
        $self->_handle_encoding_second_level($para);

        next;  # and skip
      } elsif($para_type eq '~Verbatim') {
        $para->[0] = 'Verbatim';
        $para_type = '?Verbatim';
      } elsif($para_type eq '~Para') {
        $para->[0] = 'Para';
        $para_type = '?Plain';
      } elsif($para_type eq 'Data') {
        $para->[0] = 'Data';
        $para_type = '?Data';
      } elsif( $para_type =~ s/^=//s
        and defined( $para_type = $self->{'accept_directives'}{$para_type} )
      ) {
        DEBUG > 1 and print " Pondering known directive ${$para}[0] as $para_type\n";
      } else {
        # An unknown directive!
        DEBUG > 1 and printf "Unhandled directive %s (Handled: %s)\n",
         $para->[0], join(' ', sort keys %{$self->{'accept_directives'}} )
        ;
        $self->whine(
          $para->[1]{'start_line'},
          "Unknown directive: $para->[0]"
        );

        # And maybe treat it as text instead of just letting it go?
        next;
      }

      if($para_type =~ s/^\?//s) {
        if(! @$curr_open) {  # usual case
          DEBUG and print "Treating $para_type paragraph as such because stack is empty.\n";
        } else {
          my @fors = grep $_->[0] eq '=for', @$curr_open;
          DEBUG > 1 and print "Containing fors: ",
            join(',', map $_->[1]{'target'}, @fors), "\n";
          
          if(! @fors) {
            DEBUG and print "Treating $para_type paragraph as such because stack has no =for's\n";
            
          #} elsif(grep $_->[1]{'~resolve'}, @fors) {
          #} elsif(not grep !$_->[1]{'~resolve'}, @fors) {
          } elsif( $fors[-1][1]{'~resolve'} ) {
            # Look to the immediately containing for
          
            if($para_type eq 'Data') {
              DEBUG and print "Treating Data paragraph as Plain/Verbatim because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
              $para->[0] = 'Para';
              $para_type = 'Plain';
            } else {
              DEBUG and print "Treating $para_type paragraph as such because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
            }
          } else {
            DEBUG and print "Treating $para_type paragraph as Data because the containing =for ($fors[-1][1]{'target'}) is a non-resolver\n";
            $para->[0] = $para_type = 'Data';
          }
        }
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if($para_type eq 'Plain') {
        $self->_ponder_Plain($para);
      } elsif($para_type eq 'Verbatim') {
        $self->_ponder_Verbatim($para);
      } elsif($para_type eq 'Data') {
        $self->_ponder_Data($para);
      } else {
        die "\$para type is $para_type -- how did that happen?";
        # Shouldn't happen.
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      $para->[0] =~ s/^[~=]//s;

      DEBUG and print "\n", Pod::Simple::BlackBox::pretty($para), "\n";

      # traverse the treelet (which might well be just one string scalar)
      $self->{'content_seen'} ||= 1;
      $self->_traverse_treelet_bit(@$para);
    }
  }
  
  return;
}

sub _ponder_for {
  my ($self,$para,$curr_open,$paras) = @_;

  # Fake it out as a begin/end
  my $target;

  if(grep $_->[1]{'~ignore'}, @$curr_open) {
    DEBUG > 1 and print "Ignoring ignorable =for\n";
    return 1;
  }

  for(my $i = 2; $i < @$para; ++$i) {
    if($para->[$i] =~ s/^\s*(\S+)\s*//s) {
      $target = $1;
      last;
    }
  }
  unless(defined $target) {
    $self->whine(
      $para->[1]{'start_line'},
      "=for without a target?"
    );
    return 1;
  }

  if (@$para > 3 or $para->[2]) {
    # This is an ordinary =for and should be handled in the Pod::Simple way

    DEBUG > 1 and
     print "Faking out a =for $target as a =begin $target / =end $target\n";
  
    $para->[0] = 'Data';
  
    unshift @$paras,
      ['=begin',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
      $para,
      ['=end',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
    ;
  
  } else {
    # This is a =for with an =end tag

    DEBUG > 1 and
     print "Faking out a =for $target as a =begin $target\n";
  
    unshift @$paras,
      ['=begin',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
    ;

  }
  return 1;
}

sub _ponder_begin {
  my ($self,$para,$curr_open,$paras) = @_;

  unless ($para->[2] =~ /^\s*(?:table|sidebar|figure|listing)/) {
    return $self->SUPER::_ponder_begin($para,$curr_open,$paras);
  }

  my $content = join ' ', splice @$para, 2;
  $content =~ s/^\s+//s;
  $content =~ s/\s+$//s;

  my ($target, $title) = $content =~ m/^(\S+)\s*(.*)$/;
  $title =~ s/^(picture|html)\s*// if ($target eq 'table');
  $para->[1]{'title'} = $title if ($title);
  $para->[1]{'target'} = $target;  # without any ':'

  return 1 unless $self->{'accept_targets'}{$target};

  $para->[0] = '=for';  # Just what we happen to call these, internally
  $para->[1]{'~really'} ||= '=begin';
#  $para->[1]{'~ignore'}  = 0;
  $para->[1]{'~resolve'} = 1;

  push @$curr_open, $para;
  $self->{'content_seen'} ||= 1;
  $self->_handle_element_start($target, $para->[1]);

  return 1;
}

sub _ponder_end {
  my ($self,$para,$curr_open,$paras) = @_;
  my $content = join ' ', splice @$para, 2;
  $content =~ s/^\s+//s;
  $content =~ s/\s+$//s;
  DEBUG and print "Ogling '=end $content' directive\n";
  
  unless(length($content)) {
    if (@$curr_open and $curr_open->[-1][1]{'~really'} eq '=for') {
      # =for allows an empty =end directive
      $content = $curr_open->[-1][1]{'target'};
    } else {
      # Everything else should complain about an empty =end directive
      my $complaint = "'=end' without a target?";
      if ( @$curr_open and $curr_open->[-1][0] eq '=for' ) {
        $complaint .= " (Should be \"=end " . $curr_open->[-1][1]{'target'} . '")';
      }
      $self->whine( $para->[1]{'start_line'}, $complaint);
      DEBUG and print "Ignoring targetless =end\n";
      return 1;
    }
  }
  
  unless($content =~ m/^\S+$/) {  # i.e., unless it's one word
    $self->whine(
      $para->[1]{'start_line'},
      "'=end $content' is invalid.  (Stack: "
      . $self->_dump_curr_open() . ')'
    );
    DEBUG and print "Ignoring mistargetted =end $content\n";
    return 1;
  }
  
  $self->_ponder_row_end($para,$curr_open,$paras) if $content eq 'table';

  unless(@$curr_open and $curr_open->[-1][0] eq '=for') {
    $self->whine(
      $para->[1]{'start_line'},
      "=end $content without matching =begin.  (Stack: "
      . $self->_dump_curr_open() . ')'
    );
    DEBUG and print "Ignoring mistargetted =end $content\n";
    return 1;
  }
  
  unless($content eq $curr_open->[-1][1]{'target'}) {
    if ($content eq 'for' and $curr_open->[-1][1]{'~really'} eq '=for') {
      # =for allows a "=end for" directive
      $content = $curr_open->[-1][1]{'target'};
    } else {
      $self->whine(
        $para->[1]{'start_line'},
        "=end $content doesn't match =begin " 
        . $curr_open->[-1][1]{'target'}
        . ".  (Stack: "
        . $self->_dump_curr_open() . ')'
      );
      DEBUG and print "Ignoring mistargetted =end $content at line $para->[1]{'start_line'}\n";
      return 1;
    }
  }

  # Else it's okay to close...
  if(grep $_->[1]{'~ignore'}, @$curr_open) {
    DEBUG > 1 and print "Not firing any event for this =end $content because in an ignored region\n";
    # And that may be because of this to-be-closed =for region, or some
    #  other one, but it doesn't matter.
  } else {
    $curr_open->[-1][1]{'start_line'} = $para->[1]{'start_line'};
      # what's that for?
    
    $self->{'content_seen'} ||= 1;
    if ($content eq 'table' or $content eq 'sidebar' or $content eq 'figure' or $content eq 'listing') {
      $self->_handle_element_end( $content );
    } else {
      $self->_handle_element_end( 'for', { 'target' => $content } );
    }
  }
  DEBUG > 1 and print "Popping $curr_open->[-1][0] $curr_open->[-1][1]{'target'} because of =end $content\n";
  pop @$curr_open;

  return 1;
} 

sub _ponder_row_start {
  my ($self,$para,$curr_open,$paras) = @_;

  $self->_ponder_row_end($para,$curr_open,$paras);

  push @$curr_open, $para;

  $self->{'content_seen'} ||= 1;
  $self->_handle_element_start('row', $para->[1]);

  return 1;
}

sub _ponder_row_end {
  my ($self,$para,$curr_open,$paras) = @_;
  # PseudoPod doesn't have a row closing entity, so "=row" and "=end
  # table" have to double for it.

  if(@$curr_open and $curr_open->[-1][0] eq '=row') {
    $self->{'content_seen'} ||= 1;
    my $over = pop @$curr_open;
    $self->_handle_element_end( 'row' );
  }
  return 1;
}

1; 

__END__

=head1 NAME

Pod::PseudoPod - A framework for parsing PseudoPod

=head1 SYNOPSIS

  use strict;
  package SomePseudoPodFormatter;
  use base qw(Pod::PseudoPod);

  sub handle_text {
    my($self, $text) = @_;
    ...
  }

  sub start_head1 {
    my($self, $flags) = @_;
    ...
  }
  sub end_head1 {
    my($self) = @_;
   ...
  }

  ...and start_*/end_* methods for whatever other events you
  want to catch.

=head1 DESCRIPTION

PseudoPod is an extended set of Pod tags used for book manuscripts.
Standard Pod doesn't have all the markup options you need to mark up
files for publishing production. PseudoPod adds a few extra tags for
footnotes, tables, sidebars, etc.

This class adds parsing support for the PseudoPod tags. It also
overrides Pod::Simple's C<_handle_element_start>, C<_handle_text>, and
C<_handle_element_end> methods so that parser events are turned into
method calls.

In general, you'll only want to use this module as the base class for
a PseudoPod formatter/processor.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::PseudoPod::HTML>, L<Pod::PseudoPod::Tutorial>

=head1 COPYRIGHT

Copyright (C) 2003-2009 Allison Randal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal <allison@perl.org>

=cut

