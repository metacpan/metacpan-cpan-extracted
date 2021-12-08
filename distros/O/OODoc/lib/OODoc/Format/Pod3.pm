# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

use strict;
use warnings;

package OODoc::Format::Pod3;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Format::Pod';

use Log::Report      'oodoc';

use OODoc::Template  ();
use List::Util       qw/first/;


my $default_template;
{   local $/;
    $default_template = <DATA>;
    close DATA;
}

sub createManual(@)
{   my ($self, %args) = @_;
    $self->{O_template} = delete $args{template} || \$default_template;
    $self->SUPER::createManual(%args);
}

sub formatManual(@)
{   my ($self, %args) = @_;
    my $output    = delete $args{output};

    my $template  = OODoc::Template->new
     ( markers    => [ '<{', '}>' ]
     , manual_obj => delete $args{manual}
     , chapter_order =>
         [ qw/NAME INHERITANCE SYNOPSIS DESCRIPTION OVERLOADED METHODS
              FUNCTIONS CONSTANTS EXPORTS DIAGNOSTICS DETAILS REFERENCES
              COPYRIGHTS/
         ]
     , %args
     );

    $output->print
      (  scalar $template->process
         ( $self->{O_template}
         , manual         => sub { shift; ( {}, @_ ) }
         , chapters       => sub { $self->chapters($template, @_) }
         , sections       => sub { $self->sections($template, @_) }
         , subsections    => sub { $self->subsections($template, @_) }
         , subsubsections => sub { $self->subsubsections($template, @_) }
         , subroutines    => sub { $self->subroutines($template, @_) }
         , diagnostics    => sub { $self->diagnostics($template, @_) }
         )
      );
}


sub structure($$$)
{   my ($self, $template, $type, $object) = @_;

    my $manual = $template->valueFor('manual_obj');
    my $descr  = $self->cleanup($manual, $object->description);
    my $name   = $object->name;

    $descr =~ s/\n*$/\n\n/
        if defined $descr && length $descr;

    my @examples;
    foreach my $example ($object->examples)
    {   my $title = $example->name || 'Example';
		$title = "Example: $example" if $title !~ /example/i;
		$title =~ s/\s+$//;

        push @examples,
         +{ title => $title
          , descr => $self->cleanup($manual, $example->description)
          };
    }

    my @extends;

    unless($name eq 'NAME' || $name eq 'SYNOPSIS') 
    {   @extends = map +{manual => $_->manual, header => $name}
           , $object->extends;
    }

    +{ $type        => $name
     , $type.'_obj' => $object
     , description  => $descr
     , examples     => \@examples
     , extends      => \@extends
     };
}

sub chapters($$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;
    my $manual = $template->valueFor('manual_obj');

    my @chapters
       = map $self->structure($template, chapter => $_)
           , $manual->chapters;

    if(my $order = $attrs->{order})
    {   my @order = ref $order eq 'ARRAY' ? @$order : split( /\,\s*/, $order);
        my %order;

        # first the pre-defined names, then the other
        my $count = 1;
        $order{$_} = $count++ for @order;
        $order{$_->{chapter}} ||= $count++ for @chapters;

        @chapters = sort { $order{$a->{chapter}} <=> $order{$b->{chapter}} }
           @chapters;
    }

    ( \@chapters, $attrs, $then, $else );
}

sub sections($$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;
    my $chapter = $template->valueFor('chapter_obj');

    return ([], $attrs, $then, $else)
        unless first {!$_->isEmpty} $chapter->sections;

    my @sections
       = map { $self->structure($template, section => $_) }
             $chapter->sections;

    ( \@sections, $attrs, $then, $else );
}

sub subsections($$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;
    my $section = $template->valueFor('section_obj');

    return ([], $attrs, $then, $else)
        unless first {!$_->isEmpty} $section->subsections;

    my @subsections
       = map { $self->structure($template, subsection => $_) }
             $section->subsections;

    ( \@subsections, $attrs, $then, $else );
}

sub subsubsections($$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;
    my $subsection = $template->valueFor('subsection_obj');

    return ([], $attrs, $then, $else)
        unless first {!$_->isEmpty} $subsection->subsubsections;

    my @subsubsections
       = map { $self->structure($template, subsubsection => $_) }
             $subsection->subsubsections;

    ( \@subsubsections, $attrs, $then, $else );
}

sub subroutines($$$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;

    my $parent
      = $template->valueFor('subsubsection_obj')
     || $template->valueFor('subsection_obj')
     || $template->valueFor('section_obj')
     || $template->valueFor('chapter_obj');

    defined $parent
        or return ();

    my $out  = '';
    open OUT, '>',\$out;

    my @show = map +($_ => scalar $template->valueFor($_)),
       qw/show_described_options show_described_subs show_diagnostics
          show_examples show_inherited_options show_inherited_subs
          show_option_table show_subs_index/;

    # This is quite weak: the whole POD section for a sub description
    # is produced outside the template.  In the future, this may get
    # changed: if there is a need for it: of course, we can do everything
    # in the template system.

    $self->showSubroutines
      ( subroutines => [ $parent->subroutines ]
      , manual      => $parent->manual
      , output      => \*OUT
      , @show
      );

    close OUT;
    length $out or return;

    $out =~ s/\n*$/\n\n/;
    ($out);
}

sub diagnostics($$$$$$)
{   my ($self, $template, $tag, $attrs, $then, $else) = @_;
    my $manual = $template->valueFor('manual_obj');
    
    my $out  = '';
    open OUT, '>',\$out;
    $self->chapterDiagnostics(%$attrs, manual => $manual, output => \*OUT);
    close OUT;

    $out =~ s/\n*$/\n\n/;
    ($out);
}

1;

__DATA__
=encoding utf8

<{macro name=structure}>\
   <{description}>\
   <{extends}>\
Extends L<"<{header}>" in <{manual}>|<{manual}>/"<{header}>">.
 
\
   <{/extends}>\
   <{template macro=examples}>\
   <{subroutines}>\
<{/macro}>\


<{macro name=examples}>\
<{examples}>\
   <{template macro=example}>

<{/examples}>\
<{/macro}>\


<{macro name=example}>\
B<. <{title}>>

<{descr}>
<{/macro}>\


<{manual}>\
  <{chapters order=$chapter_order}>\

=head1 <{chapter}>

\
    <{template macro=structure}>\
    <{sections}>\

=head2 <{section}>

\
      <{template macro=structure}>\
      <{subsections}>\

=head3 <{subsection}>

\
        <{template macro=structure}>\
        <{subsubsections}>\

=head4 <{subsubsection}>

\
          <{template macro=structure}>\
        <{/subsubsections}>\

      <{/subsections}>\

    <{/sections}>\

  <{/chapters}>\

  <{diagnostics}>\
  <{append}>\

<{/manual}>
