package Pod::PseudoPod::CrossReference;
use strict;
use base qw( Pod::PseudoPod );

use Carp;

use vars qw( $VERSION );
$VERSION = '0.02';

sub new {
    my $self  = shift;
    my $index = shift;
    my $new   = $self->SUPER::new(@_);
    $new->accept_targets_as_text(
        qw(author blockquote comment caution
          editor epigraph example figure important note production
          programlisting screen sidebar table tip warning)
    );
    $new->{'scratch'} = '';
    $new->{'title'}   = '';
    map { $new->{_HNDL_TYPES}->{$_} = 1 }
      qw( Z head0 head1 head2 head3 head4 figure table );
    $new;
}

sub _end {
    my ($self, $type) = @_;
    my $handler = $self->{'Handlers'}->{$type};
    $self->{'title'}   = $handler->($self, $self->{'scratch'}) if $handler;
    $self->{'reftype'} = $type;
    $self->{'scratch'} = '';
    $self->{'capture'} = 0;
}

sub start_Z { $_[0]{'capture'} = 1; }

sub end_Z {
    my $self    = shift;
    my $handler = $self->{'Handlers'}->{'Z'};
    $handler->($self, $self->{'scratch'}) if $handler;
    $self->{'scratch'} = '';
    $self->{'capture'} = 0;
}

sub handle_text { $_[0]{'scratch'} .= $_[1] if $_[0]{'capture'}; }

sub start_head0 { $_[0]{'capture'} = 1; }
sub start_head1 { $_[0]{'capture'} = 1; }
sub start_head2 { $_[0]{'capture'} = 1; }
sub start_head3 { $_[0]{'capture'} = 1; }
sub start_head4 { $_[0]{'capture'} = 1; }

sub end_head0 { _end($_[0], 'head0') }
sub end_head1 { _end($_[0], 'head1') }
sub end_head2 { _end($_[0], 'head2') }
sub end_head3 { _end($_[0], 'head3') }
sub end_head4 { _end($_[0], 'head4') }

sub start_figure {
    my $handler = $_[0]->{'Handlers'}->{'figure'};
    $_[0]{'title'} = $handler->($_[0], $_[1]->{'title'}) if $handler;
    $_[0]{'reftype'} = 'figure';
}

sub start_table {
    my $handler = $_[0]->{'Handlers'}->{'table'};
    $_[0]{'title'} = $handler->($_[0], $_[1]->{'title'}) if $handler;
    $_[0]{'reftype'} = 'table';
}

#--- borrowed from XML::Parser
sub set_handlers {
    my ($self, @handler_pairs) = @_;
    croak("Uneven number of arguments to set_handlers method")
      if (int(@handler_pairs) & 1);
    my @ret;
    while (@handler_pairs) {
        my $type    = shift @handler_pairs;
        my $handler = shift @handler_pairs;
        unless (defined($self->{_HNDL_TYPES}->{$type})) {
            my @types = sort keys %{$self->{_HNDL_TYPES}};
            croak("Unknown Parser handler type: $type\n Valid types: @types");
        }
        push(@ret, $type, $self->{'Handlers'}->{$type});
        $self->{'Handlers'}->{$type} = $handler;
    }
    @ret;
}

1;

__END__

=head1 NAME

Pod::PseudoPod::CrossReference -- a framework for extracting information from 
PseudoPOD files for cross-referencing.

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 use strict;
 
 use Pod::PseudoPod::CrossReference;
 use File::Spec;
 use File::Basename;
 use Storable;
 
 my $id;
 my $index = { };
 my @head;
 my $indir = $ARGV[0];
 for my $file (<$indir/*pod>) {
     my $p = Pod::PseudoPod::CrossReference->new;
     $p->set_handlers('Z', \&Z); 
     $p->set_handlers('head0', \&head0); 
     $p->set_handlers('head1', \&head1); 
     $p->set_handlers('head2', \&head2); 
     $p->set_handlers('head3', \&head3); 
     $p->set_handlers('head4', \&head4); 
     $id = basename($file,'.pod');
     $p->parse_file($file);
 }
 store $index, File::Spec->catfile($indir,'ref.stor');
 
 sub Z {
     $index->{$_[1]} = {
         title => $_[0]->{'title'},
         id => $id,
         type => $_[0]->{'reftype'},
     }
 }
 
 sub head0 { handler(0) }
 sub head1 { handler(1) }
 sub head2 { handler(2) }
 sub head3 { handler(3) }
 sub head4 { handler(4) }
 
 sub handler { 
     my $index = shift;
     $head[$index]++; 
     for (my $i=$index-1; $i>0; $i--) {
         $head[$i] = 0;
     }
     "Section ".join('.',@head[0..$index]); 
 }

=head1 DESCRIPTION

This module is a framework for extracting information from PseudoPOD files for 
cross-referencing. It implements a callback mechanism that developers can use 
to hook occurrences of certain PseudoPOD markup to create a data table of 
cross reference information. Rather the predetermining how an identifier is 
labeled, Pod::PseudoPod::CrossReference provides a framework that lets you 
decided how identifiers are labeled and stored. The data collected from this 
process can be used to create links that are more accurate and adaptable 
to document revisions.

The inline Z element is used to mark a section for cross-refencing. It's good 
form to place this marker immediately after the start of the block. For example:

 =head0 In The Beginning
 
 Z<the_beginning>

Here the section 'In The Beginning' is given a marker of 'the_beginning' which 
can be used to link back to this section. 

Not placing the Z element right after the start of the section it is associated 
to I<may> cause the cross reference processor to return incorrect results.

Typically the Z handler is used to record labels in a data structure. What 
information the Z handler has to work with is setup by all of the other block 
handlers.

=head1 METHODS

This is a subclass of L<Pod::PseudoPod> and inherits all its methods. This 
module ads one important method that makes cross-referencing possible.

=over

=item $ref->set_handlers(element,coderef[,element,coderef,...])

This method is used to register the callback handlers for the Z and recognized 
block element types for the parser to return. All block handlers must return a 
string that will be used (presumably) as the title for that section if a 
marker exists. The Z handler ignores any values that are returned.

I<element> is the PseudoPOD block element name the callback is for. I<coderef> 
is a reference to the subroutine that should be called as each instance of 
I<element> is processed.

Multiple elements/coderef pairs can be passed with one call or each handler can be 
set individually.

No specific handler is required though without any handlers this module is 
rather pointless.

=back

=head1 HANDLERS

The following handlers are recognized by the processor.

=over

=item head0

=item head1

=item head2

=item head3

=item head4

=item table

=item figure

=back

=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::PseudoPod::Tutorial>

=head1 LICENSE

The software is released under the Artistic License. The
terms of the Artistic License are described at 
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Pod::PseudoPod::CrossReference is Copyright
2005, Timothy Appnel, tima@cpan.org. All rights reserved.

=cut
