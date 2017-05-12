# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Format;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Object';

use strict;
use warnings;

use OODoc::Manifest;
use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my $name = $self->{OF_project} = delete $args->{project}
        or error __x"formatter knows no project name";

    $self->{OF_version} = delete $args->{version}
        or error __x"formatter for {name} does not know the version", name => $name;

    $self->{OF_workdir} = delete $args->{workdir}
        or error __x"no working directory specified for {name}", name => $name;

    $self->{OF_manifest} = delete $args->{manifest} || OODoc::Manifest->new;

    $self;
}

#-------------------------------------------


sub project() {shift->{OF_project}}


sub version() {shift->{OF_version}}
sub workdir() {shift->{OF_workdir}}
sub manifest() {shift->{OF_manifest}}

#-------------------------------------------


sub createManual(@) {panic}


sub cleanup($$)
{   my ($self, $manual, $string) = @_;
    $manual->parser->cleanup($self, $manual, $string);
}


sub showChapter(@)
{   my ($self, %args) = @_;
    my $chapter  = $args{chapter} or panic;
    my $manual   = $args{manual}  or panic;
    my $show_ch  = $args{show_inherited_chapter}    || 'REFER';
    my $show_sec = $args{show_inherited_section}    || 'REFER';
    my $show_ssec= $args{show_inherited_subsection} || 'REFER';
warn "show $chapter in $manual ($show_ch, $show_sec, ", ref($self), ")\n"
   if ref $self =~ m/pod/i;

    if($manual->inherited($chapter))
    {    return $self if $show_ch eq 'NO';
         $self->showStructureRefer(%args, structure => $chapter);
         return $self;
    }

    $self->showStructureExpand(%args, structure => $chapter);

    foreach my $section ($chapter->sections)
    {   if($manual->inherited($section))
        {   next if $show_sec eq 'NO';
            $self->showStructureRefer(%args, structure => $section), next
                unless $show_sec eq 'REFER';
        }

        $self->showStructureExpand(%args, structure => $section);

        foreach my $subsection ($section->subsections)
        {   if($manual->inherited($subsection))
            {   next if $show_ssec eq 'NO';
                $self->showStructureRefer(%args, structure=>$subsection), next
                    unless $show_ssec eq 'REFER';
            }

            $self->showStructureExpand(%args, structure => $subsection);
        }
    }
}

#-------------------------------------------


sub showStructureExpanded(@) {panic}


sub showStructureRefer(@) {panic}

#-------------------------------------------

sub chapterName(@)        {shift->showRequiredChapter(NAME        => @_)}
sub chapterSynopsis(@)    {shift->showOptionalChapter(SYNOPSIS    => @_)}
sub chapterInheritance(@) {shift->showOptionalChapter(INHERITANCE => @_)}
sub chapterDescription(@) {shift->showRequiredChapter(DESCRIPTION => @_)}
sub chapterOverloaded(@)  {shift->showOptionalChapter(OVERLOADED  => @_)}
sub chapterMethods(@)     {shift->showOptionalChapter(METHODS     => @_)}
sub chapterExports(@)     {shift->showOptionalChapter(EXPORTS     => @_)}
sub chapterDiagnostics(@) {shift->showOptionalChapter(DIAGNOSTICS => @_)}
sub chapterDetails(@)     {shift->showOptionalChapter(DETAILS     => @_)}
sub chapterReferences(@)  {shift->showOptionalChapter(REFERENCES  => @_)}
sub chapterCopyrights(@)  {shift->showOptionalChapter(COPYRIGHTS  => @_)}

#-------------------------------------------


sub showRequiredChapter($@)
{   my ($self, $name, %args) = @_;
    my $manual  = $args{manual} or panic;
    my $chapter = $manual->chapter($name);

    unless(defined $chapter)
    {   alert "missing required chapter $name in $manual";
        return;
    }

    $self->showChapter(chapter => $chapter, %args);
}


sub showOptionalChapter($@)
{   my ($self, $name, %args) = @_;
    my $manual  = $args{manual} or panic;

    my $chapter = $manual->chapter($name);
    return unless defined $chapter;

    $self->showChapter(chapter => $chapter, %args);
}


sub createOtherPages(@) {shift}


sub showSubroutines(@)
{   my ($self, %args) = @_;

    my @subs   = $args{subroutines} ? sort @{$args{subroutines}} : [];
    return unless @subs;

    my $manual = $args{manual} or panic;
    my $output = $args{output}    || select;

    # list is also in ::Pod3
    $args{show_described_options} ||= 'EXPAND';
    $args{show_described_subs}    ||= 'EXPAND';
    $args{show_diagnostics}       ||= 'NO';
    $args{show_examples}          ||= 'EXPAND';
    $args{show_inherited_options} ||= 'USE';
    $args{show_inherited_subs}    ||= 'USE';
    $args{show_option_table}      ||= 'ALL';
    $args{show_subs_index}        ||= 'NO';

    $self->showSubsIndex(%args, subroutines => \@subs);

    for(my $index=0; $index<@subs; $index++)
    {   my $subroutine = $subs[$index];
        my $show = $manual->inherited($subroutine)
                 ? $args{show_inherited_subs}
                 : $args{show_described_subs};

        $self->showSubroutine 
        ( %args
        , subroutine             => $subroutine
        , show_subroutine        => $show
        , last                   => ($index==$#subs)
        );
    }
}


sub showSubroutine(@)
{   my ($self, %args) = @_;

    my $subroutine = $args{subroutine} or panic;
    my $manual = $args{manual} or panic;
    my $output = $args{output} || select;

    #
    # Method use
    #

    my $use    = $args{show_subroutine} || 'EXPAND';
    my ($show_use, $expand)
     = $use eq 'EXPAND' ? ('showSubroutineUse',  1)
     : $use eq 'USE'    ? ('showSubroutineUse',  0)
     : $use eq 'NAMES'  ? ('showSubroutineName', 0)
     : $use eq 'NO'     ? (undef,                0)
     : error __x"illegal value for show_subroutine: {value}", value => $use;

    $self->$show_use(%args, subroutine => $subroutine)
       if defined $show_use;
 
    return unless $expand;

    $args{show_inherited_options} ||= 'USE';
    $args{show_described_options} ||= 'EXPAND';

    #
    # Subroutine descriptions
    #

    my $descr       = $args{show_sub_description} || 'DESCRIBED';
    my $description = $subroutine->findDescriptionObject;
    my $show_descr  = 'showSubroutineDescription';

       if(not $description || $descr eq 'NO') { $show_descr = undef }
    elsif($descr eq 'REFER')
    {   $show_descr = 'showSubroutineDescriptionRefer'
           if $manual->inherited($description);
    }
    elsif($descr eq 'DESCRIBED')
         { $show_descr = undef if $manual->inherited($description) }
    elsif($descr eq 'ALL') {;}
    else { error __x"illegal value for show_sub_description: {v}", v => $descr}
    
    $self->$show_descr(%args, subroutine => $description)
          if defined $show_descr;

    #
    # Options
    #

    my $options = $subroutine->collectedOptions;

    my $opttab  = $args{show_option_table} || 'NAMES';
    my @options = @{$options}{ sort keys %$options };

    # Option table

    my @opttab
     = $opttab eq 'NO'       ? ()
     : $opttab eq 'DESCRIBED'? (grep {not $manual->inherits($_->[0])} @options)
     : $opttab eq 'INHERITED'? (grep {$manual->inherits($_->[0])} @options)
     : $opttab eq 'ALL'      ? @options
     : error __x"illegal value for show_option_table: {v}", v => $opttab;
    
    $self->showOptionTable(%args, options => \@opttab)
       if @opttab;

    # Option expanded

    my @optlist;
    foreach (@options)
    {   my ($option, $default) = @$_;
        my $check
          = $manual->inherited($option) ? $args{show_inherited_options}
          :                               $args{show_described_options};
        push @optlist, $_ if $check eq 'USE' || $check eq 'EXPAND';
    }

    $self->showOptions(%args, options => \@optlist)
        if @optlist;

    # Examples

    my @examples = $subroutine->examples;
    my $show_ex  = $args{show_examples} || 'EXPAND';
    $self->showExamples(%args, examples => \@examples)
        if $show_ex eq 'EXPAND';
    
    # Diagnostics

    my @diags    = $subroutine->diagnostics;
    my $show_diag= $args{show_diagnostics} || 'NO';
    $self->showDiagnostics(%args, diagnostics => \@diags)
        if $show_diag eq 'EXPAND';
}


sub showExamples(@) {shift}


sub showSubroutineUse(@) {shift}


sub showSubroutineName(@) {shift}


sub showSubroutineDescription(@) {shift}


sub showOptionTable(@)
{   my ($self, %args) = @_;
    my $options = $args{options} or panic;
    my $manual  = $args{manual}  or panic;
    my $output  = $args{output}  or panic;

    my @rows;
    foreach (@$options)
    {   my ($option, $default) = @$_;
        my $optman = $option->manual;
        my $link   = $manual->inherited($option)
                   ? $self->link(undef, $optman)
                   : '';
        push @rows, [ $self->cleanup($manual, $option->name)
                    , $link
                    , $self->cleanup($manual, $default->value)
                    ];
    }

    my @header = ('Option', 'Defined in', 'Default');
    unless(grep {length $_->[1]} @rows)
    {   # removed empty "defined in" column
        splice @$_, 1, 1 for @rows, \@header;
    }

    $output->print("\n");
    $self->writeTable
     ( output => $output
     , header => \@header
     , rows   => \@rows
     , widths => [undef, 15, undef]
     );

    $self
}


sub showOptions(@)
{   my ($self, %args) = @_;

    my $options = $args{options} or panic;
    my $manual  = $args{manual}  or panic;

    foreach (@$options)
    {   my ($option, $default) = @$_;
        my $show = $manual->inherited($option)
          ? $args{show_inherited_options}
          : $args{show_described_options};

        my $action
          = $show eq 'USE'   ? 'showOptionUse'
          : $show eq 'EXPAND'? 'showOptionExpand'
          : error __x"illegal show option choice: {v}", v => $show;
 
        $self->$action(%args, option => $option, default => $default);
    }
    $self;
}


sub showOptionUse(@) {shift}


sub showOptionExpand(@) {shift}


1;

