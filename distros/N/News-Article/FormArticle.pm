# -*- Perl -*-
###########################################################################
# Written and maintained by Andrew Gierth <andrew@erlenstar.demon.co.uk>
#
# Copyright 1997 Andrew Gierth. Redistribution terms at end of file.
#
# $Id: FormArticle.pm 1.7 2000/04/14 15:12:28 andrew Exp $
#

=head1 NAME

News::FormArticle - derivative of News::Article

=head1 SYNOPSIS

  use News::FormArticle;

See below for functions available.

=head1 DESCRIPTION

Like News::Article, but designed to be constructed from a file
containing form text with substitutions.

Currently, the source text is substituted as follows:

Variables are denoted by $NAME or @NAME (where NAME is any simple
identifier). (The sequences $$ and @@ denote literal $ and @
characters.) Variables of the form $NAME are expected to supply
scalar values which are interpolated; variables of the form @NAME
are expected to supply lists (or references to arrays) which are
interpolated with separating newlines.

Values of variables are found by consulting the list of sources
supplied. Each source may be either a reference to a hash, or a
reference to code. 

Source hashes may contain as values either the desired value (scalar
or reference to array), or a typeglob, or a code reference which will
be called to return the result. (Since typeglobs are allowed values,
it is possible to supply a reference to a module symbol table as a
valid source.)

Code references supplied as sources are invoked with the variable
name (including the leading $ or @) as the only parameter. In the
degenerate case, all variables accessible in the source scope may be
made available for interpolation by supplying the following as a
source:

  sub { eval shift }

If multiple sources are supplied, then each is consulted in turn until
a defined value is found.

=head1 USAGE

  use News::FormArticle;

Exports nothing.

=cut

package News::FormArticle;

use strict;

use News::Article;
use FileHandle ();

use vars qw(@ISA);
use subs qw(process_line);

@ISA = qw(News::Article);

# $obj = new News::FormArticle(filename, substs)

=head1 Constructor

=over 4

=item new ( FILE [, SOURCE [...]] )

Construct an article from the specified file, performing variable
substitution with values supplied by the C<SOURCE> parameters (see
Description). FILE is any form of data recognised by News::Article\'s
read() method.

=cut

sub new
{
    my $class = shift;
    my $file = shift;
    my $substs = \@_;
    my $src = News::Article::source_init($file);
    return undef unless defined($src);

    $class->SUPER::new(sub { process_line($src,$substs) });
}

###########################################################################
# Private functions
###########################################################################

sub subst_scalar
{
    my ($name, $substs) = @_;
    my $val = undef;

    for (@$substs)
    {
	if (ref($_) eq 'HASH')
	{
	    $val = $$_{$name};
	}
	elsif (ref($_) eq 'CODE')
	{
	    $val = &$_("\$".$name);
	}
	if (ref(\$val) eq 'GLOB')
	{
	    $val = defined($ {*$val}) ? $ {*$val} : undef;
	}
	elsif (ref($val) eq 'CODE')
	{
	    $val = &$val();
	}
	last if defined($val);
    }
    $val;
}

sub subst_array
{
    my ($name, $substs) = @_;
    my $val = undef;

    for (@$substs)
    {
	if (ref($_) eq 'HASH')
	{
	    $val = $$_{$name};
	}
	elsif (ref($_) eq 'CODE')
	{
	    $val = [ &$_("\@".$name) ];
	    $val = $val->[0] if @$val == 1 && ref($val->[0]);
	}
	if (ref(\$val) eq 'GLOB')
	{
	    $val = defined(@{*$val}) ? \@{*$val} : undef;
	}
	elsif (ref($val) eq 'CODE')
	{
	    $val = [ &$val() ];
	}
	last if defined($val);
    }
    join("\n",@$val);
}

sub process_line
{
    my ($src, $substs) = @_;

    local $_ = &$src();
    return undef unless defined($_);
    chomp;
    $_ .= "\n";

    # look for substitution patterns. We recognize:
    #  ?WORD
    # where ? is either $ or @. Also, $$ = $ and @@ = @.

    s{ ([\$\@]) (\1|\w+) }
     { (($1 eq $2) ? $1 : (($1 eq "\$") ? subst_scalar($2,$substs)
                                        : subst_array($2,$substs))) }gex;

    $_;
}

1;

__END__

=head1 AUTHOR

Andrew Gierth <andrew@erlenstar.demon.co.uk>

=head1 COPYRIGHT

Copyright 1997 Andrew Gierth <andrew@erlenstar.demon.co.uk>

This code may be used and/or distributed under the same terms as Perl
itself.

=cut

