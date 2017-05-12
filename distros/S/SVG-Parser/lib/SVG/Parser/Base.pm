package SVG::Parser::Base;
use strict;

use vars qw($VERSION);
$VERSION="1.03";

#-------------------------------------------------------------------------------

# XML declaration defaults
use constant SVG_DEFAULT_DECL_VERSION     => "1.0";
use constant SVG_DEFAULT_DECL_ENCODING    => "UTF-8";
use constant SVG_DEFAULT_DECL_STANDALONE  => "yes";

# Document type definition defaults
use constant SVG_DEFAULT_DOCTYPE_NAME     => "svg";
use constant SVG_DEFAULT_DOCTYPE_SYSID    => "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd";
use constant SVG_DEFAULT_DOCTYPE_PUBID    => "-//W3C//DTD SVG 1.0//EN";

#-------------------------------------------------------------------------------

# debug: simple debug method
sub debug ($$;@) {
    my ($self,$what,@msgs)=@_;
    return unless $self->{-debug};

    my $first=1;
    my $name||=ref($self);
    my $length||=length($name);
    if (@msgs) {
        foreach (@msgs) {
            next unless defined $_;
            printf STDERR "+++%s %-8s: %s\n",
                ($first?$name:" "x$length),
                ($first?$what:"       "),$_;
            $first=0;
        }
    } else {
        printf STDERR "+++%s %s\n",$name,$what;
    }
}

#-------------------------------------------------------------------------------

use constant ARG_IS_STRING                => "string";
use constant ARG_IS_HANDLE                => "handle";
use constant ARG_IS_HASHRF                => "hash";
use constant ARG_IS_INVALID               => "nonsuch";

#-------------------------------------------------------------------------------

# is it a bird...is it a plane?
sub identify ($$) {
    my ($self,$source)=@_;

    return ARG_IS_INVALID unless $source;

    # assume a string unless we determine differently
    my $type=ARG_IS_STRING;

    # check for various filehandle cases
    if (ref $source) {
        my $class = ref($source);

        if (UNIVERSAL::isa($source,'IO::Handle')) {
            # it's a new-style filehandle
            $type=ARG_IS_HANDLE;
        } elsif (tied($source)) {
            # it's a tied filehandle?
            no strict 'refs'; 
            $type=ARG_IS_HANDLE if defined &{"${class}::TIEHANDLE"};
        }
    } else {
        # it's an old-style filehandle?
        no strict 'refs';
        $type=ARG_IS_HANDLE if eval { *{$source}{IO} };
    }

    # possibly a hash argument is called via parse_file (SAX)
    $type=ARG_IS_HASHRF if ref($source) and $type eq ARG_IS_STRING;

    return $type;
}

#-------------------------------------------------------------------------------
# Additional SVG.pm processing

sub process_attrs ($$) {
    my ($parser,$attrs)=@_;

    if (exists $attrs->{style}) {
        my %styles=split /\s*[:;]\s*/,$attrs->{style};
        $attrs->{style}=\%styles;
    }
}

#---------------------------------------------------------------------------------------
# Shared Expat/SAX Handlers

# create and set SVG document object as root element
sub StartDocument {
    my $parser=shift;

    # gather SVG constuctor attributes
    my %svg_attr;
    %svg_attr=%{delete $parser->{__svg_attr}} if exists $parser->{__svg_attr};
    $svg_attr{-nostub}=1;
    # instantiate SVG document object
    $parser->{__svg}=new SVG(%svg_attr);
    # empty element list
    $parser->{__elements}=[];
    # empty unassigned attlist list (for internal DTD subset handling)
    $parser->{__unassigned_attlists}=[];
    # cdata count
    $parser->{__in_cdata}=0;

    $parser->debug("Start",$parser."/".$parser->{__svg});
}

# handle start of element - extend chain by one
sub StartTag {
    my ($parser,$type,%attrs)=@_;
    my $elements=$parser->{__elements};
    my $svg=$parser->{__svg};

    # some attributes need extra processing
    $parser->process_attrs(\%attrs);

    if (@$elements) {
        my $parent=$elements->[-1];
        push @$elements, $parent->element($type,%attrs);
    } else {
        $svg->{-inline}=1 if $type ne "svg"; #inlined
        my $el=$svg->element($type,%attrs);
        $svg->{-document} = $el;
        push @$elements, $el;
    }

    $parser->debug("Element",$type);
}

# handle end of element - shorten chain by one
sub EndTag {
    my ($parser,$type)=@_;
    my $elements=$parser->{__elements};
    pop @$elements;
}

# handle cannonical data (text)
sub Text {
    my ($parser,$text)=@_;
    my $elements=$parser->{__elements};

    return if $text=~/^\s*$/s; #ignore redundant whitespace
    my $parent=$elements->[-1];

    # are we in a CDATA section? (see CdataStart/End below)
    if ($parser->{__in_cdata}) {
        my $current=$parent->{-CDATA} || '';
        $parent->CDATA($current.$parser->{__svg}{-elsep}.$text);
    } else {
        my $current=$parent->{-cdata} || '';
        $parent->cdata($current.$parser->{__svg}{-elsep}.$text);
    }

    $parser->debug("CDATA","\"$text\"");
}

# handle cannonical data (CDATA sections)
sub CdataStart {
    my $parser=shift;
    $parser->{__in_cdata}++;

    $parser->debug("CDATA","start->");
}

sub CdataEnd {
    my $parser=shift;
    my $elements=$parser->{__elements};
    my $parent=$elements->[-1];

    my $current=$parent->{-CDATA} || '';
    $parent->CDATA($current.$parser->{__svg}{-elsep});
    $parser->{__in_cdata}--;

    $parser->debug("CDATA","<-end");
}

# handle processing instructions
sub PI {
    my ($parser,$target,$data)=@_;
    my $elements=$parser->{__elements};

    if (my $parent=$elements->[-1]) {
        /^<\?(.*)\?>/;
        $parent->pi($1);
    };

    $parser->debug("PI",$_);
}

# handle XML Comments
sub Comment {
    my ($parser,$data)=@_;

    my $elements=$parser->{__elements};
    if (my $parent=$elements->[-1]) {
        # SVG.pm doesn't handle comment prior to document start
        $parent->comment($data);
    }

    $parser->debug("Comment",$data);
}

# return root SVG document object as result of parse()
sub FinishDocument {
    my $parser=shift;
    my $svg=$parser->{__svg};

    # add any attlists that were seen before their element
    if (my $attlists=$parser->{__unassigned_attlists}) {
        foreach my $unassigned_attlist (@$attlists) {
            # if the element is still missing this will complain (if the parser didn't)
            $svg->attlist_decl(@$unassigned_attlist);
        }
    }

    $parser->debug("Done");

    return $parser->{__svg};
}

#---------------------------------------------------------------------------------------

# handle XML declaration, if present
sub XMLDecl {
    my ($parser,$version,$encoding,$standalone)=@_;
    my $svg=$parser->{__svg};

    $svg->{-version}=$version || $parser->SVG_DEFAULT_DECL_VERSION;
    $svg->{-encoding}=$encoding || $parser->SVG_DEFAULT_DECL_ENCODING;
    $svg->{-standalone}=$standalone?"yes":"no";

    $parser->debug("XMLDecl","-version=\"$svg->{-version}\"",
	"-encoding=\"$svg->{-encoding}\"","-standalone=\"$svg->{-standalone}\"");
}

# handle Doctype declaration, if present
sub Doctype {
    my ($parser,$name,$sysid,$pubid,$internal)=@_;
    my $svg=$parser->{__svg};

    $svg->{-docroot}=$name || $parser->SVG_DEFAULT_DOCTYPE_NAME;
    $svg->{-sysid}=$sysid || $parser->SVG_DEFAULT_DOCTYPE_SYSID;
    $svg->{-pubid}=$pubid || $parser->SVG_DEFAULT_DOCTYPE_PUBID;

    $parser->debug("Doctype",
        "-docroot=\"$svg->{-docroot}\"",
        "-sysid=\"$svg->{-sysid}\"",
	"-pubid=\"$svg->{-pubid}\"",
    );
}

#---------------------------------------------------------------------------------------

# Unparsed (Expat, Entity, Base, Sysid, Pubid, Notation)
sub Unparsed {
    my ($parser,$name,$base,$sysid,$pubid,$notation)=@_;
    my $svg=$parser->{__svg};

    my %entity=(name=>$name, sysid=>$sysid, notation=>$notation);
    $entity{base}=$base if defined $base;
    $entity{sysid}=$sysid if defined $sysid;

    $svg->entity_decl(%entity);
}

# Notation (Expat, Notation, Base, Sysid, Pubid)
sub Notation {
    my ($parser,$name,$base,$sysid,$pubid)=@_;
    my $svg=$parser->{__svg};

    my %notation=(name=>$name);
    $notation{base}=$base if defined $base;
    $notation{sysid}=$sysid if defined $sysid;
    $notation{pubid}=$pubid if defined $pubid;

    $svg->notation_decl(%notation);
}

# Entity (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
sub Entity {
    my ($parser,$name,$val,$sysid,$pubid,$data,$isp)=@_;
    my $svg=$parser->{__svg};
    $isp||=0;

    if (defined $val) {
        $svg->entity_decl(name=>$name, value=>$val, isp=>$isp);
    } elsif (defined $pubid) {
        $svg->entity_decl(name=>$name, sysid=>$sysid, pubid=>$pubid, ndata=>$data, isp=>$isp);
    } else {
        $svg->entity_decl(name=>$name, sysid=>$sysid, ndata=>$data, isp=>$isp);
    }
}

# Element (Expat, Name, Model)
sub Element {
    my ($parser,$name,$model)=@_;
    my $svg=$parser->{__svg};

    if (defined $model) {
	# convert model to string context
        $svg->element_decl(name=>$name, model=>qq{$model});
    } else {
        $svg->element_decl(name=>$name);
    }
}

# Attlist (Expat, Elname, Attname, Type, Default, Fixed)
sub Attlist {
    my ($parser,$name,$attr,$type,$default,$fixed)=@_;
    my $svg=$parser->{__svg};

    if ($svg->getElementDeclByName($name)) {
        $svg->attlist_decl(
            name=>$name, attr=>$attr, type=>$type, default=>$default, fixed=>($fixed?1:0)
        );
    } else {
        push @{$parser->{__unassigned_attlists}}, [
            name=>$name, attr=>$attr, type=>$type, default=>$default, fixed=>($fixed?1:0)
        ];
    }
}

#---------------------------------------------------------------------------------------

1;
