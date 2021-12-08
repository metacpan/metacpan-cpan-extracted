# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Parser::Markov;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Parser';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Text::Chapter;
use OODoc::Text::Section;
use OODoc::Text::SubSection;
use OODoc::Text::SubSubSection;
use OODoc::Text::Subroutine;
use OODoc::Text::Option;
use OODoc::Text::Default;
use OODoc::Text::Diagnostic;
use OODoc::Text::Example;
use OODoc::Manual;

use File::Spec;
use IO::File;

my $url_modsearch = "http://search.cpan.org/perldoc?";
my $url_coderoot  = 'CODE';


#-------------------------------------------

my @default_rules =
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


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my @rules = @default_rules;
    unshift @rules, @{delete $args->{additional_rules}}
        if exists $args->{additional_rules};

    $self->{OP_rules} = [];
    $self->rule(@$_) for @rules;
    $self;
}

#-------------------------------------------


sub rule($$)
{   my ($self, $match, $action) = @_;
    push @{$self->{OP_rules}}, [$match, $action];
    $self;
}

#-------------------------------------------


sub findMatchingRule($)
{   my ($self, $line) = @_;

    foreach ( @{$self->{OP_rules}} )
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

    my $in     = IO::File->new($input, 'r')
       or die "ERROR: cannot read document from $input: $!\n";

    my $out    = IO::File->new($output, 'w')
       or die "ERROR: cannot write stripped code to $output: $!\n";

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

            # I would like to use 'our' here, but in some cases, that will
            # cause compaints about double declaration with our.
            $out->print("\nuse vars '\$VERSION';\n\$VERSION = '$version';\n");
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
        {

            if(ref $action)
            {   $action->($self, $match, $line, $input, $ln)
                  or $out->print($line);
            }
            else
            {   no strict 'refs';
                $self->$action($match, $line, $input, $ln)
                  or $out->print($line);
            }
        }
        elsif($line =~ m/^=(over|back|item|for|pod|begin|end|head4|encoding)\b/)
        {   ${$self->{OPM_block}} .= "\n". $line;
            $self->inDoc(1);
        }
        elsif(substr($line, 0, 1) eq '=')
        {   warn "WARNING: unknown markup in $input line $ln:\n $line";
            ${$self->{OPM_block}} .= $line;
            $self->inDoc(1);
        }
        elsif($pure_pod || $self->inDoc)
        {   # add the line to the currently open text block
            my $block = $self->{OPM_block};
            unless($block)
            {   warn "WARNING: no block for line $ln in file $input\n $line";
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

    warn "WARNING: doc did not end in $input.\n"
        if $self->inDoc && ! $pure_pod;

    $self->closeChapter;
    $in->close && $out->close;

    @manuals;
}

#-------------------------------------------


sub setBlock($)
{   my ($self, $ref) = @_;
    $self->{OPM_block} = $ref;
    $self->inDoc(1);
    $self;
}

#-------------------------------------------


sub inDoc(;$)
{   my $self = shift;
    $self->{OPM_in_pod} = shift if @_;
    $self->{OPM_in_pod};
}

#-------------------------------------------


sub currentManual(;$)
{   my $self = shift;
    @_ ? $self->{OPM_manual} = shift : $self->{OPM_manual};
}

#-------------------------------------------


sub docCut($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    if($self->currentManual->isPurePod)
    {   warn "The whole file $fn is pod, so =cut in line $ln is useless.\n";
        return;
    }

    warn "WARNING: $match does not terminate any doc in $fn line $ln.\n"
        unless $self->inDoc;

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

    my $manual = $self->currentManual;
    die "ERROR: chapter $line before package statement in $fn line $ln\n"
       unless defined $manual;

    my $chapter = $self->{OPM_chapter} = OODoc::Text::Chapter->new
     ( name    => $line
     , manual  => $manual
     , linenr  => $ln
     );

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

    my $chapter = $self->{OPM_chapter};
    die "ERROR: section `$line' outside chapter in $fn line $ln\n"
       unless defined $chapter;

    my $section = $self->{OPM_section} = OODoc::Text::Section->new
     ( name     => $line
     , chapter  => $chapter
     , linenr   => $ln
     );

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

    my $section = $self->{OPM_section};
    defined $section
        or die "ERROR: subsection `$line' outside section in $fn line $ln\n";

    my $subsection = $self->{OPM_subsection} = OODoc::Text::SubSection->new
     ( name     => $line
     , section  => $section
     , linenr   => $ln
     );

    $section->subsection($subsection);
    $self->setBlock($subsection->openDescription);
    $subsection;
}

sub closeSubSection()
{   my $self       = shift;
    my $subsection = delete $self->{OPM_subsection};
    $self;
}


#-------------------------------------------
# SUBSECTION


sub docSubSubSection($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;
    $line =~ s/^\=(subsubsection|head4)\s+//;
    $line =~ s/\s+$//;

    $self->closeSubSubSection;

    my $subsection = $self->{OPM_subsection};
    defined $subsection
     or die "ERROR: subsubsection `$line' outside subsection in $fn line $ln\n";

    my $subsubsection
      = $self->{OPM_subsubsection} = OODoc::Text::SubSubSection->new
      ( name       => $line
      , subsection => $subsection
      , linenr     => $ln
      );

    $subsection->subsubsection($subsubsection);
    $self->setBlock($subsubsection->openDescription);
    $subsubsection;
}

sub closeSubSubSection()
{   my $self = shift;
    delete $self->{OPM_subsubsection};
    $self;
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

    my $container = $self->{OPM_subsection}
                 || $self->{OPM_section}
	         || $self->{OPM_chapter};

    die "ERROR: subroutine $name outside chapter in $fn line $ln\n"
       unless defined $container;

    $type    = 'i_method' if $type eq 'method';
    my $sub  = $self->{OPM_subroutine} = OODoc::Text::Subroutine->new
     ( type       => $type
     , name       => $name
     , parameters => $params
     , linenr     => $ln
     , container  => $container
     );

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
    {   warn "WARNING: option line incorrect in $fn line $ln:\n$line";
        return;
    }
    my ($name, $parameters) = ($1, $2);

    my $sub  = $self->{OPM_subroutine};
    die "ERROR: option $name outside subroutine in $fn line $ln\n"
       unless defined $sub;

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


sub docDefault($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    unless($line =~ m/^\=default\s+(\S+)\s+(.+?)\s*$/ )
    {   warn "WARNING: default line incorrect in $fn line $ln:\n$line";
        return;
    }

    my ($name, $value) = ($1, $2);

    my $sub  = $self->{OPM_subroutine};
    die "ERROR: default for option $name outside subroutine in $fn line $ln\n"
       unless defined $sub;

    my $default  = OODoc::Text::Default->new
     ( name       => $name
     , value      => $value
     , linenr     => $ln
     , subroutine => $sub
     );

    $sub->default($default);
    $sub;
}

sub docRequires($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    unless($line =~ m/^\=requires\s+(\w+)\s+(.+?)\s*$/ )
    {   warn "WARNING: requires line incorrect in $fn line $ln:\n$line";
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
    {   warn "WARNING: no diagnostic message supplied in $fn line $ln";
        return;
    }

    my $sub  = $self->{OPM_subroutine};
    die "ERROR: diagnostic $type outside subroutine in $fn line $ln\n"
       unless defined $sub;

    my $diag  = OODoc::Text::Diagnostic->new
     ( type       => ucfirst($type)
     , name       => $line
     , linenr     => $ln
     , subroutine => $sub
     );

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

    die "ERROR: example outside chapter in $fn line $ln\n"
       unless defined $container;

    my $example  = OODoc::Text::Example->new
     ( name      => ($line || '')
     , linenr    => $ln
     , container => $container
     );

    $self->setBlock($example->openDescription);
    $container->example($example);
    $example;
}

#-------------------------------------------


sub debugRemains($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    warn "WARNING: Debugging remains in $fn line $ln\n"
       unless $self->inDoc || $self->currentManual->isPurePod;

    undef;
}

#-------------------------------------------


sub forgotCut($$$$)
{   my ($self, $match, $line, $fn, $ln) = @_;

    warn "WARNING: You may have accidentally captured code in doc $fn line $ln\n"
       if $self->inDoc && ! $self->currentManual->isPurePod;

    undef;
}

#-------------------------------------------


sub decomposeM($$)
{   my ($self, $manual, $link) = @_;

    my ($subroutine, $option)
      = $link =~ s/(?:^|\:\:) (\w+) \( (.*?) \)$//x ? ($1, $2)
      :                                               ('', '');

    my $man;
       if(not length($link)) { $man = $manual }
    elsif(defined($man = $self->manual($link))) { ; }
    else
    {   eval "no warnings; require $link";
        if(  ! $@
          || $@ =~ m/attempt to reload/i
          || $self->skipManualLink($link)
          ) { ; }
        elsif($@ =~ m/Can't locate/ )
        {  warn "WARNING: module $link is not on your system, found in $manual\n";
        }
        else
        {  $@ =~ s/ at \(eval.*//;
           warn "WARNING: use problem for module $link in $manual;\n$@";
           warn " Did you use an 'M' tag on something which is not a module?\n";
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

    return (undef, $man)
        unless defined $subroutine && length $subroutine;

    my $package = $self->manual($man->package);
    unless(defined $package)
    {   my $want = $man->package;
        warn "WARNING: no manual for $want (correct casing?)\n";
        return (undef, "$want subroutine $subroutine");
    }

    my $sub     = $package->subroutine($subroutine);
    unless(defined $sub)
    {   warn "WARNING: subroutine $subroutine() is not defined by $package, but linked to in $manual\n";
        return ($package, "$package subroutine $subroutine");
    }

    my $location = $sub->manual;
    return ($location, $sub)
        unless defined $option && length $option;

    my $opt = $sub->findOption($option);
    unless(defined $opt)
    {   warn "WARNING: option \"$option\" unknown for $subroutine() in $location, found in $manual\n";
        return ($location, "$package subroutine $subroutine option $option");
    }

    ($location, $opt);
}


sub decomposeL($$)
{   my ($self, $manual, $link) = @_;
    my $text = $link =~ s/^([^|]*)\|// ? $1 : undef;

    unless(length $link)
    {   warn "WARNING: empty L link in $manual";
        return ();
    }

    if($link  =~ m/^[a-z]+\:[^:]/ )
    {   $text         = $link unless defined $text;
        return (undef, undef, $link, $text);
    }

    my ($name, $item) = $link =~ m[(.*?)(?:/(.*))?$];

    ($name, $item)    = (undef, $name) if $name =~ m/^".*"$/;
    $item     =~ s/^"(.*)"$/$1/        if defined $item;

    my $man   = length $name ? ($self->manual($name) || $name) : $manual;

    my $dest;
    if(!ref $man)
    {   unless(defined $text && length $text)
        {  $text = "manual $man";
           $text .= " entry $item" if defined $item && length $item;
        }

        if($man !~ m/\(\d.*\)\s*$/)
        {   (my $escaped = $man) =~ s/\W+/_/g;
            $dest = "$url_modsearch$escaped";
        }
    }
    elsif(!defined $item)
    {   $dest  = $man;
        $text  = $man->name unless defined $text;
    }
    elsif(my @obj = $man->all(findEntry => $item))
    {   $dest  = shift @obj;
        $text  = $item unless defined $text;
    }
    else
    {   warn "WARNING: Manual $manual links to unknown entry \"$item\" in $man\n";
        $dest = $man;
        $text = "$man" unless defined $text;
    }

    ($man, $dest, undef, $text);
}


sub cleanupPod($$$)
{   my ($self, $formatter, $manual, $string) = @_;
    return '' unless defined $string && length $string;

    my @lines   = split /^/, $string;
    my $protect;

    for(my $i=0; $i < @lines; $i++)
    {   $protect = $1  if $lines[$i] =~ m/^=(for|begin)\s+\w/;

        undef $protect if $lines[$i] =~ m/^=end/;

        undef $protect if $lines[$i] =~ m/^\s*$/
                       && $protect && $protect eq 'for';

        next if $protect;

        $lines[$i] =~
             s/\bM\<([^>]*)\>/$self->cleanupPodM($formatter,$manual,$1)/ge;

        $lines[$i] =~
             s/\bL\<([^>]*)\>/$self->cleanupPodL($formatter,$manual,$1)/ge
                if substr($lines[$i], 0, 1) eq ' ';

        # permit losing blank lines around pod statements.
        if(substr($lines[$i], 0, 1) eq '=')
        {   if($i > 0 && $lines[$i-1] ne "\n")
            {   splice @lines, $i-1, 0, "\n";
                $i++;
            }
            elsif($i < $#lines && $lines[$i+1] ne "\n"
                  && substr($lines[$i], 0, 5) ne "=for ")
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
{   my ($self, $formatter, $manual, $link) = @_;
    my ($toman, $to) = $self->decomposeM($manual, $link);
    ref $to ? $formatter->link($toman, $to, $link) : $to;
}


sub cleanupPodL($$$)
{   my ($self, $formatter, $manual, $link) = @_;
    my ($toman, $to, $href, $text) = $self->decomposeL($manual, $link);
    $text;
}

#-------------------------------------------


sub cleanupHtml($$$;$)
{   my ($self, $formatter, $manual, $string, $is_html) = @_;
    return '' unless defined $string && length $string;

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
        if($type =~ m/^\:(text|pod)\b/ )
        {   $type    = 'text';
            $capture = $self->cleanupPod($formatter, $manual, $capture);
        }
        elsif($type =~ m/^\:?html\b/ )
        {   $type    = 'html';
            $capture = $self->cleanupHtml($formatter, $manual, $capture, 1);
        }

        my $take = $type eq 'text' ? "<pre>\n". $capture . "</pre>\n"
                 : $type eq 'html' ? $capture
                 :                   '';   # ignore

        return $self->cleanupHtml($formatter, $manual, $before)
             . $take
             . $self->cleanupHtml($formatter, $manual, $after);
    }

    for($string)
    {   unless($is_html)
        {   s#\&#\&amp;#g;
            s#(?<!\b[LFCIBEM])\<#&lt;#g;
            s#\-\>#-\&gt;#g;
        }
        s/\bM\<([^>]*)\>/$self->cleanupHtmlM($formatter, $manual, $1)/ge;
        s/\bL\<([^>]*)\>/$self->cleanupHtmlL($formatter, $manual, $1)/ge;
        s#\bC\<([^>]*)\>#<code>$1</code>#g;
        s#\bI\<([^>]*)\>#<em>$1</em>#g;
        s#\bB\<([^>]*)\>#<b>$1</b>#g;
        s#\bE\<([^>]*)\>#\&$1;#g;
        s#^\=over\s+\d+\s*#\n<ul>\n#gms;
        s#(?:\A|\n)\=item\s*(?:\*\s*)?([^\n]*)#\n<li><b>$1</b><br />#gms;
        s#(?:\A|\s*)\=back\b#\n</ul>#gms;
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
{   my ($self, $formatter, $manual, $link) = @_;
    my ($toman, $to) = $self->decomposeM($manual, $link);
    ref $to ? $formatter->link($toman, $to, $link) : $to;
}


sub cleanupHtmlL($$$)
{   my ($self, $formatter, $manual, $link) = @_;
    my ($toman, $to, $href, $text) = $self->decomposeL($manual, $link);

     defined $href ? qq[<a href="$href" target="_blank">$text</a>]
   : !defined $to  ? $text
   : ref $to       ? $formatter->link($toman, $to, $text)
   :                 qq[<a href="$to">$text</a>]
}

#-------------------------------------------


1;
