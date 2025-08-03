# This code is part of Perl distribution OODoc version 3.00.
# The POD got stripped from this file by OODoc version 3.00.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Parser::Markov;{
our $VERSION = '3.00';
}

use parent 'OODoc::Parser';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Text::Chapter       ();
use OODoc::Text::Section       ();
use OODoc::Text::SubSection    ();
use OODoc::Text::SubSubSection ();
use OODoc::Text::Subroutine    ();
use OODoc::Text::Option        ();
use OODoc::Text::Default       ();
use OODoc::Text::Diagnostic    ();
use OODoc::Text::Example       ();
use OODoc::Manual              ();

use File::Spec;

my $url_modsearch = "http://search.cpan.org/perldoc?";
my $url_coderoot  = 'CODE';
my @default_rules;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my @rules = @default_rules;
    unshift @rules, @{delete $args->{additional_rules}}
        if exists $args->{additional_rules};

    $self->{OPM_rules} = [];
    $self->rule(@$_) for @rules;
    $self;
}

#------------------

sub setBlock($)
{   my ($self, $ref) = @_;
    $self->{OPM_block} = $ref;
    $self->inDoc(1);
    $self;
}


sub inDoc(;$) { my $s = shift; @_ ? $s->{OPM_in_pod} = shift : $s->{OPM_in_pod} }


sub currentManual(;$) { my $s = shift; @_ ? ($s->{OPM_manual} = shift) : $s->{OPM_manual} }


sub rules() { $_[0]->{OPM_rules} }

#-------------------------------------------

@default_rules =
  ( [ '=cut'        => 'docCut'        ]
  , [ '=chapter'    => 'docChapter'    ]
  , [ '=section'    => 'docSection'    ]
  , [ '=subsection' => 'docSubSection' ]
  , [ '=subsubsection' => 'docSubSubSection' ]
  , [ '=method'     => 'docSubroutine' ]
  , [ '=i_method'   => 'docSubroutine' ]
  , [ '=c_method'   => 'docSubroutine' ]
  , [ '=ci_method'  => 'docSubroutine' ]
  , [ '=function'   => 'docSubroutine' ]
  , [ '=tie'        => 'docSubroutine' ]
  , [ '=overload'   => 'docSubroutine' ]
  , [ '=option'     => 'docOption'     ]
  , [ '=default'    => 'docDefault'    ]
  , [ '=requires'   => 'docRequires'   ]
  , [ '=example'    => 'docExample'    ]
  , [ '=examples'   => 'docExample'    ]
  , [ '=error'      => 'docDiagnostic' ]
  , [ '=warning'    => 'docDiagnostic' ]
  , [ '=notice'     => 'docDiagnostic' ]
  , [ '=debug'      => 'docDiagnostic' ]
 
  # deprecated
  , [ '=head1'      => 'docChapter'    ]
  , [ '=head2'      => 'docSection'    ]
  , [ '=head3'      => 'docSubSection' ]
 
  # problem spotter
  , [ qr/^(warn|die|carp|confess|croak)\s/ => 'debugRemains' ]
  , [ qr/^( sub \s+ \w
          | (?:my|our) \s+ [\($@%]
          | (?:package|use) \s+ \w+\:
          )
        /x => 'forgotCut' ]
  );


sub rule($$)
{   my ($self, $match, $action) = @_;
    push @{$self->rules}, [$match, $action];
    $self;
}


sub findMatchingRule($)
{   my ($self, $line) = @_;

    foreach ( @{$self->rules} )
    {   my ($match, $action) = @$_;
        if(ref $match)
        {   return ($&, $action) if $line =~ $match;
        }
        elsif(substr($line, 0, length($match)) eq $match)
        {   return ($match, $action);
        }
    }

    ();
}


sub parse(@)
{   my ($self, %args) = @_;

    my $input   = $args{input}
       or error __x"no input file to parse specified";

    my $output  = $args{output} || File::Spec->devnull;
    my $version = $args{version}      or panic;
    my $distr   = $args{distribution} or panic;

    open my $in, '<:encoding(utf8)', $input
        or fault __x"cannot read document from {file}", file => $input;

    open my $out, '>:encoding(utf8)', $output
        or fault __x"cannot write stripped code to {file}", file => $output;

    # pure doc files have no package statement included, so it shall
    # be created beforehand.

    my ($manual, @manuals);

    my $pure_pod = $input =~ m/\.pod$/;
    if($pure_pod)
    {   $manual = OODoc::Manual->new
          ( package  => $self->filenameToPackage($input)
          , pure_pod => 1
          , source   => $input
          , parser   => $self

          , distribution => $distr
          , version      => $version
          );

        push @manuals, $manual;
        $self->currentManual($manual);
        $self->inDoc(1);
    }
    else
    {   $out->print($args{notice}) if $args{notice};
        $self->inDoc(0);
    }

    # Read through the file.

    while(my $line = $in->getline)
    {   my $ln = $in->input_line_number;

        if(    !$self->inDoc
            && $line !~ m/^\s*package\s*DB\s*;/
            && $line =~ s/^(\s*package\s*([\w\-\:]+)\s*\;)//
          )
        {   $out->print($1);
            my $package = $2;

            # Wrap VERSION declaration in a block to avoid any problems with
            # double declaration
            $out->print("{\nour \$VERSION = '$version';\n}\n");
            $out->print($line);

            $manual = OODoc::Manual->new
              ( package  => $package
              , source   => $input
              , stripped => $output
              , parser   => $self

              , distribution => $distr
              , version      => $version
              );
            push @manuals, $manual;
            $self->currentManual($manual);
        }
        elsif(!$self->inDoc && $line =~ m/^=package\s*([\w\-\:]+)\s*$/)
        {   my $package = $1;
            $manual = OODoc::Manual->new
              ( package  => $package
              , source   => $input
              , stripped => $output
              , parser   => $self
              , distribution => $distr
              , version      => $version
              );
            push @manuals, $manual;
            $self->currentManual($manual);
        }
        elsif(my($match, $action) = $self->findMatchingRule($line))
        {   $self->$action($match, $line, $input, $ln)
                or $out->print($line);
        }
        elsif($line =~ m/^=(over|back|item|for|pod|begin|end|head4|encoding)\b/)
        {   ${$self->{OPM_block}} .= "\n". $line;
            $self->inDoc(1);
        }
        elsif(substr($line, 0, 1) eq '=')
        {   warning __x"unknown markup in {file} line {linenr}:\n {line}", file => $input, linenr => $ln, line => $line;
            ${$self->{OPM_block}} .= $line;
            $self->inDoc(1);
        }
        elsif($pure_pod || $self->inDoc)
        {   # add the line to the currently open text block
            my $block = $self->{OPM_block};
            unless($block)
            {   warning __x"no block for line {linenr} in file {file}\n {line}", file => $input, linenr => $ln, line => $line;
                my $dummy = '';
                $block = $self->setBlock(\$dummy);
            }
            $$block  .= $line;
        }
        elsif($line eq "__DATA__\n")  # flush rest file
        {   $out->print($line, $in->getlines);
        }
        else
        {   $out->print($line);
        }
    }

    ! $self->inDoc || $pure_pod
        or warning __x"doc did not end in {file}", file => $input;

    $self->closeChapter;
    $in->close && $out->close;

    @manuals;
}


sub docCut($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    if($self->currentManual->isPurePod)
    {   warn "The whole file $fn is pod, so =cut in line $ln is useless.\n";
        return;
    }

    $self->inDoc
        or warning __x"Pod tag {tag} does not terminate any doc in {file} line {line}", tag => $match, file => $fn, line => $ln;

    $self->inDoc(0);
    1;
}

#-------------------------------------------
# CHAPTER


sub docChapter($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;
    $line =~ s/^\=(chapter|head1)\s+//;
    $line =~ s/\s+$//;

    $self->closeChapter;

    my $manual = $self->currentManual
        or error __x"chapter {name} before package statement in {file} line {line}", name => $line, file => $fn, line => $ln;

    my $chapter = $self->{OPM_chapter} =
        OODoc::Text::Chapter->new(name => $line, manual => $manual, linenr => $ln);

    $self->setBlock($chapter->openDescription);
    $manual->chapter($chapter);
    $chapter;
}

sub closeChapter()
{   my $self = shift;
    my $chapter = delete $self->{OPM_chapter} or return;
    $self->closeSection()->closeSubroutine();
}

#-------------------------------------------
# SECTION


sub docSection($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;
    $line =~ s/^\=(section|head2)\s+//;
    $line =~ s/\s+$//;

    $self->closeSection;

    my $chapter = $self->{OPM_chapter}
        or error __x"section '{name}' outside chapter in {file} line {line}", name => $line, file => $fn, line => $ln;

    my $section = $self->{OPM_section} =
        OODoc::Text::Section->new(name => $line, chapter => $chapter, linenr => $ln);

    $chapter->section($section);
    $self->setBlock($section->openDescription);
    $section;
}

sub closeSection()
{   my $self    = shift;
    my $section = delete $self->{OPM_section} or return $self;
    $self->closeSubSection();
}

#-------------------------------------------
# SUBSECTION


sub docSubSection($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;
    $line =~ s/^\=(subsection|head3)\s+//;
    $line =~ s/\s+$//;

    $self->closeSubSection;

    my $section = $self->{OPM_section}
        or error __x"subsection '{name}' outside section in {file} line {line}", name => $line, file => $fn, line => $ln;

    my $subsection = $self->{OPM_subsection} =
        OODoc::Text::SubSection->new(name => $line, section => $section, linenr => $ln);

    $section->subsection($subsection);
    $self->setBlock($subsection->openDescription);
    $subsection;
}

sub closeSubSection()
{   my $self       = shift;
    my $subsection = delete $self->{OPM_subsection};
    $self->closeSubSubSection;
}

#-------------------------------------------
# SUBSECTION


sub docSubSubSection($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;
    $line =~ s/^\=(subsubsection|head4)\s+//;
    $line =~ s/\s+$//;

    $self->closeSubSubSection;

    my $subsection = $self->{OPM_subsection}
        or error __x"subsubsection '{name}' outside section in {file} line {line}", name => $line, file => $fn, line => $ln;

    my $subsubsection = $self->{OPM_subsubsection} =
        OODoc::Text::SubSubSection->new(name => $line, subsection => $subsection, linenr => $ln);

    $subsection->subsubsection($subsubsection);
    $self->setBlock($subsubsection->openDescription);
    $subsubsection;
}

sub closeSubSubSection()
{   my $self = shift;
    delete $self->{OPM_subsubsection};
    $self->closeSubroutine;
}

#-------------------------------------------
# SUBROUTINES


sub docSubroutine($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    chomp $line;
    $line    =~ s/^\=(\w+)\s+//;
    my $type = $1;

    my ($name, $params)
     = $type eq 'overload' ? ($line, '')
     :                       $line =~ m/^(\w*)\s*(.*?)\s*$/;

    my $container = $self->{OPM_subsection} || $self->{OPM_section} || $self->{OPM_chapter}
        or error __x"subroutine {name} outside chapter in {file} line {line}", name => $name, file => $fn, line => $ln;

    $type    = 'i_method' if $type eq 'method';
    my $sub  = $self->{OPM_subroutine} =
       OODoc::Text::Subroutine->new(type => $type, name => $name, parameters => $params, linenr => $ln, container => $container);

    $self->setBlock($sub->openDescription);
    $container->addSubroutine($sub);
    $sub;
}

sub closeSubroutine()
{   my $self = shift;
    delete $self->{OPM_subroutine};
    $self;
}

#-------------------------------------------
# SUBROUTINE ADDITIONALS


sub docOption($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    unless($line =~ m/^\=option\s+(\S+)\s+(.+?)\s*$/ )
    {   warning __x"option line incorrect in {file} line {linenr}:\n {line}", file => $fn, linenr => $ln, line => $line;
        return;
    }
    my ($name, $parameters) = ($1, $2);

    my $sub  = $self->{OPM_subroutine}
        or error __x"option {name} outside subroutine in {file} line {line}", name => $name, file => $fn, line => $ln;

    my $option  = OODoc::Text::Option->new
      ( name       => $name
      , parameters => $parameters
      , linenr     => $ln
      , subroutine => $sub
      );

    $self->setBlock($option->openDescription);
    $sub->option($option);
    $sub;
}

#-------------------------------------------
# DEFAULT


sub docDefault($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    unless($line =~ m/^\=default\s+(\S+)\s+(.+?)\s*$/ )
    {   warning __x"default line incorrect in {file} line {linenr}:\n {line}", file => $fn, linenr => $ln, line => $line;
        return;
    }

    my ($name, $value) = ($1, $2);

    my $sub = $self->{OPM_subroutine}
       or error __x"default for option {name} outside subroutine in {file} line {line}", name => $name, file => $fn, line => $ln;

    my $default = OODoc::Text::Default->new(name => $name, value => $value, linenr => $ln, subroutine => $sub);

    $sub->default($default);
    $sub;
}

sub docRequires($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    unless($line =~ m/^\=requires\s+(\w+)\s+(.+?)\s*$/ )
    {   warning __x"requires line incorrect in {file} line {linenr}:\n {line}", file => $fn, linenr => $ln, line => $line;
        return;
    }

    my ($name, $param) = ($1, $2);
    $self->docOption ($match, "=option  $name $param", $fn, $ln);
    $self->docDefault($match, "=default $name <required>", $fn, $ln);
}

#-------------------------------------------
# DIAGNOSTICS


sub docDiagnostic($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    $line =~ s/^\=(\w+)\s*//;
    my $type = $1;

    $line =~ s/\s*$//;
    unless(length $line)
    {   warning __x"no diagnostic message supplied in {file} line {line}", file => $fn, line => $ln;
        return;
    }

    my $sub  = $self->{OPM_subroutine}
        or error __x"diagnostic {type} outside subroutine in {file} line {line}", type => $type, file => $fn, line => $ln;

    my $diag  = OODoc::Text::Diagnostic->new(type => ucfirst($type), name => $line, linenr => $ln, subroutine => $sub);

    $self->setBlock($diag->openDescription);
    $sub->diagnostic($diag);
    $sub;
}

#-------------------------------------------
# EXAMPLE


sub docExample($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    $line =~ s/^=examples?\s*//;
    $line =~ s/^\#.*//;

    my $container = $self->{OPM_subroutine}
                 || $self->{OPM_subsubsection}
                 || $self->{OPM_subsection}
                 || $self->{OPM_section}
                 || $self->{OPM_chapter};

    defined $container
        or error __x"example outside chapter in {file} line {line}", file => $fn, line => $ln;

    my $example  = OODoc::Text::Example->new(name => ($line || ''), linenr => $ln, container => $container);

    $self->setBlock($example->openDescription);
    $container->example($example);
    $example;
}


sub debugRemains($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    $self->inDoc || $self->currentManual->isPurePod
        or warning __x"Debugging remains in {file} line {line}", file => $fn, line => $ln;

    undef;
}


sub forgotCut($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    $self->inDoc && ! $self->currentManual->isPurePod
        and warning __x"You may have accidentally captured code in doc {file} line {line}", file => $fn, line => $ln;

    undef;
}

#-------------------------------------------

sub decomposeM($$)
{   my ($self, $manual, $link) = @_;

    my ($subroutine, $option) = $link =~ s/(?:^|\:\:) (\w+) \( (.*?) \)$//x ? ($1, $2) : ('', '');

    my $man;
       if(not length($link)) { $man = $manual }
    elsif(defined($man = $self->findManual($link))) { ; }
    else
    {   eval "no warnings; require $link";
        if(  ! $@
          || $@ =~ m/attempt to reload/i
          || $self->skipManualLink($link)
          ) { ; }
        elsif($@ =~ m/Can't locate/ )
        {   warning __x"module {name} is not on your system, found in {manual}", name => $link, manual => $manual;
        }
        else
        {  $@ =~ s/ at \(eval.*//;
           warning __x"use problem for module {name} in {manual};\n{err}", name => $link, manual => $manual, err => $@;
        }
        $man = $link;
    }

    unless(ref $man)
    {   return ( $manual
               , $man
                 . (length($subroutine) ? " subroutine $subroutine" : '')
                 . (length($option)     ? " option $option" : '')
               );
    }

    defined $subroutine && length $subroutine
        or return (undef, $man);

    my $package = $self->findManual($man->package);
    unless(defined $package)
    {   my $want = $man->package;
        warning __x"no manual for {package} (correct casing?)", package => $want;
        return (undef, "$want subroutine $subroutine");
    }

    my $sub     = $package->subroutine($subroutine);
    unless(defined $sub)
    {   warning __x"subroutine {call}() is not defined by {pkg}, but linked to in {manual}",
            call => $subroutine, pkg => $package, manual => $manual;
        return ($package, "$package subroutine $subroutine");
    }

    my $location = $sub->manual;
    defined $option && length $option
        or return ($location, $sub);

    my $opt = $sub->findOption($option);
    unless(defined $opt)
    {   warning __x"option '{name}' unknown for {call}() in {where}, found in {manual}",
            name => $option, call => $subroutine, where => $location, manual => $manual;
        return ($location, "$package subroutine $subroutine option $option");
    }

    ($location, $opt);
}


sub decomposeL($$)
{   my ($self, $manual, $link) = @_;
    my $text  = $link =~ s/^([^|]*)\|// ? $1 : undef;

    length $link
        or (warning __x"empty L link in {manual}", manual => $manual), return ();

    return (undef, undef, $link, $text // $link)
        if $link  =~ m/^[a-z]+\:[^:]/;

    my ($name, $item) = $link =~ m[(.*?)(?:/(.*))?$];

    ($name, $item)    = (undef, $name) if $name =~ m/^".*"$/;
    $item     =~ s/^"(.*)"$/$1/        if defined $item;

    my $man   = length $name ? ($self->findManual($name) || $name) : $manual;

    my $dest;
    if(!ref $man)
    {   unless(defined $text && length $text)
        {   $text  = "manual $man";
            $text .= " entry $item" if defined $item && length $item;
        }

        if($man !~ m/\(\d.*\)\s*$/)
        {   (my $escaped = $man) =~ s/\W+/_/g;
            $dest = "$url_modsearch$escaped";
        }
    }
    elsif(!defined $item)
    {   $dest   = $man;
        $text //= $man->name;
    }
    elsif(my @obj = $man->all(findEntry => $item))
    {   $dest   = shift @obj;
        $text //= $item;
    }
    else
    {   warning __x"manual {manual} links to unknown entry '{item}' in {other_manual}",
            manual => $manual, entry => $item, other_manual => $man;
        $dest   = $man;
        $text //= "$man";
    }

    ($man, $dest, undef, $text);
}

sub cleanupPod($$$)
{   my ($self, $manual, $string, %args) = @_;
    defined $string && length $string or return '';

    my @lines   = split /^/, $string;
    my $protect;

    for(my $i=0; $i < @lines; $i++)
    {   $protect = $1  if $lines[$i] =~ m/^=(for|begin)\s+\w/;

        undef $protect if $lines[$i] =~ m/^=end/;
        undef $protect if $lines[$i] =~ m/^\s*$/ && $protect && $protect eq 'for';
        next if $protect;

        $lines[$i] =~ s/\bM\<([^>]*)\>/$self->cleanupPodM($manual, $1, \%args)/ge;

        $lines[$i] =~ s/\bL\<([^>]*)\>/$self->cleanupPodL($manual, $1, \%args)/ge
            if substr($lines[$i], 0, 1) eq ' ';

        # permit losing blank lines around pod statements.
        if(substr($lines[$i], 0, 1) eq '=')
        {   if($i > 0 && $lines[$i-1] ne "\n")
            {   splice @lines, $i-1, 0, "\n";
                $i++;
            }
            elsif($i < $#lines && $lines[$i+1] ne "\n" && substr($lines[$i], 0, 5) ne "=for ")
            {   splice @lines, $i+1, 0, "\n";
            }
        }
        else
        {   $lines[$i] =~ s/^\\\=/\=/;
        }

        # Remove superfluous blanks
        if($i < $#lines && $lines[$i] eq "\n" && $lines[$i+1] eq "\n")
        {   splice @lines, $i+1, 1;
        }
    }

    # remove leading and trailing blank lines
    shift @lines while @lines && $lines[0]  eq "\n";
    pop   @lines while @lines && $lines[-1] eq "\n";

    @lines ? join('', @lines) : '';
}


sub cleanupPodM($$$)
{   my ($self, $manual, $link, $args) = @_;
    my ($toman, $to) = $self->decomposeM($manual, $link);
    ref $to ? $args->{create_link}->($toman, $to, $link, $args) : $to;
}


sub cleanupPodL($$$)
{   my ($self, $manual, $link, $args) = @_;
    my ($toman, $to, $href, $text) = $self->decomposeL($manual, $link);
    $text;
}

sub cleanupHtml($$$)
{   my ($self, $manual, $string, %args) = @_;
    defined $string && length $string or return '';

	my $is_html = $args{is_html};

    if($string =~ m/(?:\A|\n)                   # start of line
                    \=begin\s+(:?\w+)\s*        # begin statement
                    (.*?)                       # encapsulated
                    \n\=end\s+\1\s*             # related end statement
                    /xs
     || $string =~ m/(?:\A|\n)                  # start of line
                     \=for\s+(:?\w+)\b          # for statement
                     (.*?)\n                    # encapsulated
                     (\n|\Z)                    # end of paragraph
                    /xs
      )
    {   my ($before, $type, $capture, $after) = ($`, lc($1), $2, $');
        if($type =~ m/^\:?html\b/ )
        {   $type    = 'html';
            $capture = $self->cleanupHtml($manual, $capture, is_html => 1);
        }

        return $self->cleanupHtml($manual, $before)
             . $capture
             . $self->cleanupHtml($manual, $after);
    }

    for($string)
    {   unless($is_html)
        {   s#\&#\&amp;#g;
            s#(\s|^)\<([^>]+)\>#$1&lt;$2&gt;#g;
            s#(?<!\b[LFCIBEMX])\<#&lt;#g;
            s#([=-])\>#$1\&gt;#g;
        }
        s/\bM\<([^>]*)\>/$self->cleanupHtmlM($manual, $1, \%args)/ge;
        s/\bL\<([^>]*)\>/$self->cleanupHtmlL($manual, $1, \%args)/ge;
        s#\bI\<([^>]*)\>#<em>$1</em>#g;
        s#\bB\<([^>]*)\>#<b>$1</b>#g;
        s#\bE\<([^>]*)\>#\&$1;#g;
        s#^\=over\s+\d+\s*#\n<ul>\n#gms;
        s#(?:\A|\n)\=item\s*(?:\*\s*)?([^\n]*)#\n<li>$1<br />#gms;
        s#(?:\A|\s*)\=back\b#\n</ul>#gms;
        s#\bC\<([^>]*)\>#<code>$1</code>#g;  # introduces a '<', hence last
        s#^=pod\b##gm;

        # when F<> contains a URL, it will be used. However, when it
        # contains a file, we cannot do anything with it yet.
        s#\bF\<(\w+\://[^>]*)\>#<a href="$1">$1</a>#g;
        s#\bF\<([^>]*)\>#<tt>$1</tt>#g;

        my ($label, $level, $title);
        s#^\=head([1-6])\s*([^\n]*)#
          ($title, $level) = ($1, $2);
          $label = $title;
          $label =~ s/\W+/_/g;
          qq[<h$level class="$title"><a name="$label">$title</a></h$level>];
         #ge;

        next if $is_html;

        s!(?:(?:^|\n)
              [^\ \t\n]+[^\n]*      # line starting with blank: para
          )+
         !<p>$&</p>!gsx;

        s!(?:(?:^|\n)               # start of line
              [\ \t]+[^\n]+         # line starting with blank: pre
          )+
         !<pre>$&\n</pre>!gsx;

        s#</pre>\n<pre>##gs;
        s#<p>\n#\n<p>#gs;
    }

    $string;
}


sub cleanupHtmlM($$$)
{   my ($self, $manual, $link, $args) = @_;
    my ($toman, $to) = $self->decomposeM($manual, $link);
    ref $to ? $args->{create_link}->($toman, $to, $link, $args) : $to;
}


sub cleanupHtmlL($$$)
{   my ($self, $manual, $link, $args) = @_;
    my ($toman, $to, $href, $text) = $self->decomposeL($manual, $link);

     defined $href ? qq[<a href="$href" target="_blank">$text</a>]
   : !defined $to  ? $text
   : ref $to       ? $args->{create_link}->($toman, $to, $text, $args)
   :                 qq[<a href="$to">$text</a>]
}

#-------------------------------------------

1;
