# -*- Perl -*-

package SGML::DTDParse::ContentModel;
use strict;
use vars qw($VERSION $CVS);

$VERSION = do { my @r=(q$Revision: 2.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
$CVS = '$Id: ContentModel.pm,v 2.1 2005/07/02 23:51:18 ehood Exp $ ';

use strict;
use Text::DelimMatch;
use SGML::DTDParse::Tokenizer;

require 5.000;
require Carp;

{
    package SGML::DTDParse::ContentModel::Group;

    sub new {
	my($type, $tok) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};
	my(@toks);
	my(@model);
	local($_);

	bless $self, $class;

#	print "Group:\n";
#	$tok->print();
#	print "\n";

	foreach $_ ('CONTENT_MODEL_STRING',
		    'OCCURRENCE') {
	    $self->{$_} = $tok->{$_};
	}

	$self->{'CONNECTOR'} = '';

	@toks = @{$tok->{'CONTENT_MODEL'}->{'MODEL'}};
	if ($toks[1]) { # if there is a connector...
	    if (ref $toks[1] eq 'SGML::DTDParse::Tokenizer::Connector') {
		$self->{'CONNECTOR'} = $toks[1]->{'CONNECTOR'};
	    }
	}

	$self->{'CONTENT_MODEL'} = new SGML::DTDParse::ContentModel $tok->{'CONTENT_MODEL'};

	return $self;
    }

    sub content_model {
	my $self = shift;
	return $self->{'CONTENT_MODEL'};
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, "(connector: ", $self->{'CONNECTOR'}, "\n";
	$self->{'CONTENT_MODEL'}->print($depth+1);
	print "\t" x $depth, ")\n";
    }

    sub xml {
	my($self, $depth) = @_;
	my($con) = $self->{'CONNECTOR'};
	my($occ) = $self->{'OCCURRENCE'};
	my($type) = "";
	my($xml) = "";

	$xml .= "  " x $depth;

	if ($con eq '|') {
	    $type = "or-group";
	} elsif ($con eq '&') {
	    $type = 'and-group';
	} else {
	    $type = 'sequence-group';
	}

	if ($occ) {
	    $xml .= "<$type occurrence=\"$occ\">\n";
	} else {
	    $xml .= "<$type>\n";
	}

	$xml .= $self->{'CONTENT_MODEL'}->xml($depth+1,1);

	$xml .= "  " x $depth;

	$xml .= "</$type>\n";

	return $xml;
    }
}

{
    package SGML::DTDParse::ContentModel::Element;

    sub new {
	my($type, $tok) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};
	my($model);

	bless $self, $class;

	foreach $_ ('ELEMENT',
		    'OCCURRENCE') {
	    $self->{$_} = $tok->{$_};
	}

	return $self;
    }

    sub element {
	my $self = shift;
	return $self->{'ELEMENT'};
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, $self->{'ELEMENT'}, $self->{'OCCURRENCE'}, "\n";
    }

    sub xml {
	my($self, $depth) = @_;
	my($occ) = $self->{'OCCURRENCE'};
	my($xml) = "";

	$xml .= "  " x $depth;

	if ($self->{'ELEMENT'} eq '#PCDATA') {
	    $xml .= "<pcdata/>\n";
	} elsif ($self->{'ELEMENT'} eq 'ANY') {
	    $xml .= "<any/>\n";
	} elsif ($self->{'ELEMENT'} eq 'EMPTY') {
	    $xml .= "<empty/>\n";
	} elsif ($self->{'ELEMENT'} eq 'CDATA') {
	    $xml .= "<cdata/>\n";
	} elsif ($self->{'ELEMENT'} eq 'RCDATA') {
	    $xml .= "<rcdata/>\n";
	} else {
	    $xml .= "<element-name name=\"" . $self->{'ELEMENT'} . "\"";
	    $xml .= " occurrence=\"$occ\"" if $occ;
	    $xml .= "/>\n";
	}

	return $xml;
    }
}

{
    package SGML::DTDParse::ContentModel::ParameterEntity;

    sub new {
	my($type, $tok) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};
	my($model);

	bless $self, $class;

	$self->{'PARAMETER_ENTITY'} = $tok->{'PARAMETER_ENTITY'};

	return $self;
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, "%", $self->{'PARAMETER_ENTITY'}, ";\n";
    }

    sub xml {
	my($self, $depth) = @_;
	my($xml) = "";

	$xml .= "  " x $depth;

	$xml .= "<parament-name name=\"" . $self->{'PARAMETER_ENTITY'} . "\"";
	$xml .= "/>\n";

	return $xml;
    }
}

sub new {
    my($type, $model) = @_;
    my $class = ref($type) || $type;
    my $self = {};
    my(@toks) = ();
    my(@model) = ();

    bless $self, $class;

    $self->{'CONTENT_MODEL_STRING'} = $model->{'CONTENT_MODEL_STRING'};
    @toks = @{$model->{'MODEL'}};

    # Note: we know that the first token will always be a group, unless
    # the content model is declard content. See new() in Tokenizer.
    #
    while (@toks) {
	my($tok) = shift @toks;

	if (ref $tok eq 'SGML::DTDParse::Tokenizer::Group') {
	    push (@model, new SGML::DTDParse::ContentModel::Group $tok);
	} elsif (ref $tok eq 'SGML::DTDParse::Tokenizer::Element') {
	    push (@model, new SGML::DTDParse::ContentModel::Element $tok);
	} elsif (ref $tok eq 'SGML::DTDParse::Tokenizer::ParameterEntity') {
	    push (@model, new SGML::DTDParse::ContentModel::ParameterEntity $tok);
	} elsif (ref $tok eq 'SGML::DTDParse::Tokenizer::Connector') {
	    #nop;
	} else {
	    die "Bad token in SGML::DTDParse::ContentModel";
	}
    }

    @{$self->{'MODEL'}} = @model;

    return $self;
}

sub type {
    my $self = shift;
    my $depth = shift;
    my @model = @{$self->{'MODEL'}};

    $depth = 0 if !defined($depth);

    while (@model) {
	my $tok = shift @model;
	if ((ref $tok) =~ /Element$/) {
	    return 'mixed' if $tok->element() eq '#PCDATA';
	    if ($depth == 0) {
		return 'cdata' if $tok->element() eq 'CDATA';
		return 'rcdata' if $tok->element() eq 'RCDATA';
		return 'empty' if $tok->element() eq 'RCDATA';
	    }
	} elsif ((ref $tok) =~ /Group$/) {
	    my $cm = $tok->content_model();
	    return $cm->type($depth+1);
	}
    }

    return 'element';
}

sub print {
    my($self) = shift;
    my($depth) = shift || 1;
    my(@model) = @{$self->{'MODEL'}};
    local($_);

    foreach $_ (@model) {
	$_->print($depth);
    }
}

sub xml {
    my($self) = shift;
    my($depth) = shift || 1;
    my($internal) = shift;
    my(@model) = @{$self->{'MODEL'}};
    my($xml) = "";
    my($tag);
    local($_);

    if (!$internal) {
	$tag = $depth;
	$depth = 1;

#	$xml .= "<$tag string=\"";
#	$xml .= $self->{'CONTENT_MODEL_STRING'};
#	$xml .= "\">\n";
    }

    foreach $_ (@model) {
	$xml .= $_->xml($depth);
    }

#    if (!$internal) {
#	$xml .= "</$tag>\n";
#    }

    return $xml;
}

1;
