# ------------------------------------------------------------------
# Petal::Parser::HTB - Fires Petal::Canonicalizer events
# ------------------------------------------------------------------
# A Wrapper class for HTML::TreeBuilder which plugs into Petal
# backend for complete parsing backwards compatibility with Petal
# < 1.10.
# ------------------------------------------------------------------
package Petal::Parser::HTB;
use strict;
use warnings;
use Carp;
use HTML::TreeBuilder;

use Petal;

use vars qw /@NodeStack @MarkedData $Canonicalizer
	     @NameSpaces @XI_NameSpaces/;

$Petal::INPUTS->{HTML}  = 'Petal::Parser::HTB';
$Petal::INPUTS->{XHTML} = 'Petal::Parser::HTB';
our $VERSION = '1.04';

# this avoid silly warnings
sub sillyness
{
    $Petal::NS,
    $Petal::NS_URI;
}


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless { @_ }, $class;
}


sub process
{
    my $self = shift;
    local $Canonicalizer = shift;
    my $data_ref = shift;
    
    local @MarkedData = ();
    local @NodeStack  = ();
    local @NameSpaces = ();
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    
    my $tree = HTML::TreeBuilder->new;
    $tree->p_strict (0);
    $tree->no_space_compacting (1);
    $tree->ignore_unknown (0);
    $tree->store_comments(1);
    $tree->ignore_ignorable_whitespace(0);
    
    eval
    {
	$tree->parse ($$data_ref);
	my @nodes = $tree->guts();
	$tree->elementify();
	$self->generate_events ($_) for (@nodes);
    };
    
    @MarkedData = ();
    @NodeStack  = ();
    $tree->delete;
    carp $@ if (defined $@ and $@);
}


# generate_events();
# ------------------
# Once the HTML::TreeBuilder object is built and elementified, it is
# passed to that subroutine which will traverse it and will trigger
# proper subroutines which will generate the XML events which are used
# by the Petal::Canonicalizer module
sub generate_events
{
    my $self = shift;
    my $tree = shift;

    if (ref $tree)
    {
	my $tag  = $tree->tag;
	my $attr = { $tree->all_external_attr() };
	
	if ($tag eq '~comment')
	{
	    generate_events_comment ($tree->attr ('text'));
	}
	else
	{
	    push @NodeStack, $tree;
	    generate_events_start ($tag, $attr);
	    
	    foreach my $content ($tree->content_list())
	    {
		$self->generate_events ($content);
	    }
	    
	    generate_events_end ($tag);
	    pop (@NodeStack);
	}
    }
    else
    {
	generate_events_text ($tree);
    }
}


sub generate_events_start
{
    $_ = shift;
    $_ = "<$_>";
    %_ = %{shift()};
    delete $_{'/'};
    
    # process the Petal namespace...
    my $ns = (scalar @NameSpaces) ? $NameSpaces[$#NameSpaces] : $Petal::NS;
    foreach my $key (keys %_)
    {
	my $value = $_{$key};
	if ($value eq $Petal::NS_URI)
	{
	    next unless ($key =~ /^xmlns\:/);
	    delete $_{$key};
	    $ns = $key;
	    $ns =~ s/^xmlns\://;
	}
    }

    push @NameSpaces, $ns;
    local ($Petal::NS) = $ns;
    
    # process the XInclude namespace
    my $xi_ns = (scalar @XI_NameSpaces) ? $XI_NameSpaces[$#XI_NameSpaces] : $Petal::XI_NS;
    foreach my $key (keys %_)
    {
	my $value = $_{$key};
	if ($value eq $Petal::XI_NS_URI)
	{
	    next unless ($key =~ /^xmlns\:/);
	    delete $_{$key};
	    $xi_ns = $key;
	    $xi_ns =~ s/^xmlns\://;
	}
    }
    
    push @XI_NameSpaces, $xi_ns;
    local ($Petal::XI_NS) = $xi_ns;
    
    $Canonicalizer->StartTag();
}


sub generate_events_end
{
    $_ = shift;
    $_ = "</$_>";
    local ($Petal::NS) = pop (@NameSpaces);
    local ($Petal::XI_NS) = pop (@XI_NameSpaces);
    $Canonicalizer->EndTag();
}


sub generate_events_text
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $_ = $data;
    
    local ($Petal::NS) = $NameSpaces[$#NameSpaces];
    local ($Petal::XI_NS) = $XI_NameSpaces[$#XI_NameSpaces];
    $Canonicalizer->Text();
}


sub generate_events_comment
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $_ = '<!--' . $data . '-->';
    $Canonicalizer->Text();    
}


1;


__END__


=head1 NAME

Petal::Parser::HTB - XML::Parser::HTB backend for Petal parsing


=head1 SYNOPSIS

  use Petal;
  use Petal::Parser::HTB;


=head1 SUMMARY

Petal used to depend on both XML::Parser and HTML::TreeBuilder for HTML
parsing. This has been changed to MKDoc::XML. If you want the HTML parsing
exactly as it was before though, you can use this module with Petal > 1.10.

Using this module will change $Petal::INPUTS->{HTML} and $Petal::INPUTS->{XHTML}
to 'Petal::Parser::HTB'. This will result in using the same code as in Petal
< 1.10 for HTML / XHTML Parsing.


=head1 EXPORTS

None.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Authors: Jean-Michel Hiver

This module free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal>


Join the Petal mailing list:

  http://lists.webarch.co.uk/mailman/listinfo/petal


Mailing list archives:

  http://lists.webarch.co.uk/pipermail/petal


=cut
