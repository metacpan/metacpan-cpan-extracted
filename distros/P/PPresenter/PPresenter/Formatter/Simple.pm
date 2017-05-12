# Copyright (C) 2000-2002, Free Software Foundation FSF.

# Simple formatter is a simplification of the markup formatter: you
# specify nesting with dashes, that's all.

package PPresenter::Formatter::Simple;

use strict;
use PPresenter::Formatter::Markup;
use base 'PPresenter::Formatter::Markup';

use Tk;

use constant ObjDefaults =>
{ -name    => 'simple'
, -aliases => undef
};

sub strip($$$;)
{   my ($self, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    return $string;
}

#
# Parse
#

sub parse($$$)
{   my ($self, $slide, $view, $contents) = @_;

    my @indents    = (0);
    my $indent     = 0;
    my $markup;

    foreach my $line (split /\n/, $contents)
    {
        my ($prefix, $dash, $text) = $line =~ /^(\s*(-)?\s*)(.*)\s*$/;
        my $prefix_length = length($prefix);

        # Detect indentation changes.

        if($prefix_length > $indents[-1])
        {   # Increase nesting.
            push @indents, $prefix_length;
            $markup .= "<UL>\n";
        }
        elsif($prefix_length==$indents[-1])
        { } # Keep indentation.
        else
        {   # Back from nestings.
            while($#indents)
            {   if($indents[-1] < $prefix_length)
                {   warn
  "Do not understand indentation on slide $slide, line\n  $line";
                    last;
                }
                last if $prefix_length == $indents[-1];
                $markup .= "</UL>\n";
                pop @indents;
            }
        }

        $markup .= (defined $dash ? '<LI>' : '') . $text . "<BR>\n";
    }

    $self->SUPER::parse($slide, $view, $markup);
}

sub titleFormat($$)
{   my ($self, $slide, $title) = @_;
    "<TITLE>$title";
}

sub footerFormat($$)
{   my ($self, $slide, $footer) = @_;
    "<FOOTER>$footer";
}

1;
