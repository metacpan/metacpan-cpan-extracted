#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Writer.pm,v 1.2 1998/01/18 00:21:17 ken Exp $
#

package SGML::Writer;

use strict;

=head1 NAME

SGML::Writer - write an SGML or XML grove

=head1 SYNOPSIS

  $writer = $SGML::Writer->new ([file_handle => $fh]
				[, depth => $depth ]);
  $grove->accept ($writer);

=head1 DESCRIPTION

C<SGML::Writer> writes a limited representation of a grove.
I<file_handle> can be a file handle or a scalar reference, if it is a
scalar reference Writer will append to it.  Writer writes to standard
output if I<file_handle> is not specified.

XXX this code could do more, see L<sgmlnorm(1)>.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), SGML::Grove(3), sgmlnorm(1)

=cut

sub new {
    my $type = shift;
    my $self = bless {@_}, $type;

    if (!defined $self->{'file_handle'}) {
	if (!defined %FileHandle::) {
	    require FileHandle;
	    import FileHandle;
	}

	# default to stdout
	$self->{'file_handle'} = FileHandle->new ('>-');
    }

    $self->{'depth'} = 0
	if (!defined $self->{'depth'});

    return $self;
}

sub print_ {
    my $self = shift; my $text = shift;

    if (ref ($self->{'file_handle'}) eq 'SCALAR') {
	${$self->{'file_handle'}} .= $text;
    } else {
	$self->{'file_handle'}->print ($text);
    }
}

sub visit_SGML_Grove {
    my $self = shift; my $grove = shift;

    my ($name, $public_id, $system_id);
    eval { $name = $grove->name };
    eval { $public_id = $grove->public_id };
    eval { $system_id = $grove->system_id };

    if (defined $name) {
	my @doctype;
	push (@doctype, "<!DOCTYPE", $name);
	if (defined $public_id) {
	    push (@doctype, "PUBLIC", qq{"$public_id"});
	} else {
	    # XXX is SYSTEM not req if PUBLIC also? see sgmlnorm(StartDtdEvent)
	    push (@doctype, "SYSTEM");
	}
	if (defined $system_id) {
	    if ($system_id =~ /\"/) {
		push (@doctype, qq{'$system_id'});
	    } else {
		push (@doctype, qq{"$system_id"});
	    }
	}
	$self->print_ (join ("  ", @doctype) . ">\n");
    }

    $grove->root->accept ($self, @_);
}

sub visit_SGML_Element {
    my $self = shift;
    my $element = shift;

    # XXX could format lots better
    $self->print_ ("<" . $element->gi);
    my ($key, $value);
    my $attributes = $element->attributes;
    if (defined $attributes) {
	while (($key, $value) = each (%$attributes)) {
	    if (ref ($value) eq 'ARRAY') {
		$self->print_ (" $key=\"");
		my $chunk;
		foreach $chunk (@$value) {
		    if (!ref ($chunk)) {
			$self->print_ ($chunk);
		    } else {
			$chunk->accept ($self, @_);
		    }
		}
		$self->print_ ('"');
	    }
	}
    }
    $self->print_ (">");
    $element->children_accept ($self, @_);
    # XXX EMPTY
    $self->print_ ("</" . $element->gi . ">");
}

sub visit_SGML_SData {
    my $self = shift;
    my $sdata = shift;

    $self->print_ ("&" . $sdata->name . ";");
}

sub visit_SGML_PI {
    my $self = shift;
    my $pi = shift;

    $self->print_ ("<?" . $pi->data . ">");
}

sub visit_SGML_Entity {
    my $self = shift;
    my $entity = shift;

    $self->print_ ("&" . $entity->name . ";");
}

sub visit_SGML_ExtEntity {
    my $self = shift;
    my $ext_entity = shift;

    $self->print_ ("&" . $ext_entity->name . ";");
}

sub visit_SGML_SubDocEntity {
    my $self = shift;
    my $subdoc_entity = shift;

    $self->print_ ("&" . $subdoc_entity->name . ";");
}

# XXX this is wrong, except in some cases
my %chars = ( "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;",
	     "\r" => "\n" );
sub visit_scalar {
    my $self = shift;
    my $scalar = shift;

    $scalar = $scalar->delegate
	if (ref($scalar));
    $scalar =~ s/([&<>\"\r])/$chars{$1}/ge;
    $self->print_ ($scalar);
}

1;
