# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Formatter::Markup_parser::Command;

package PPresenter::Formatter::Markup_parser;

@EXPORT = qw(parse parseTree);

use strict;
use Exporter;
use base 'Exporter';

sub command_translate($$$;)
{   my ($self, $cmd, $params) = @_;
    my $translations = $self->{logicals};
    return ($cmd, $params) unless exists $translations->{$cmd};
    $translations->{$cmd} =~ /^\s*(\S+)\s*/;
    return ($1, "$' $params");
}

sub parse_command($$)
{   my ($self, $statement) = @_;

    my ($cmd)  = $statement =~ m!^\s*([/\w]+)\s*!;
    my ($realcmd, $paramlist) = command_translate($self, uc $cmd, $');
    my $params = bless {cmd=>uc $cmd, CMD => uc $realcmd}
        , 'PPresenter::Formatter::Markup_parser::Command';

    while(my ($name, undef, $content, undef, $qcontent) =
        $paramlist =~ m/\s*(\w+)(=((["'])([^\4]*?)\4|\S+))?/)
    {   $content = $qcontent if defined $qcontent;
	$content = '1' unless defined $content;
        $paramlist = $';
        $params->{uc $name} = $content;
    }

    return $params;
}

# PARSE
#
# Look for compounds: <CMD PARAMS>...</CMD>
# The result is a nested tree where each level is:
#       "string", [ compound ], "string", [ compound ], ..., "string"

sub parse($$$)
{   my ($self, $slide, $view, $text) = @_;

    return [] unless defined $text;

    # Text falls apart.
    @_ = ('TEXT',split /<\s*([^>]*)>/, $text);
    my @breakup;

    while(@_)
    {   my ($cmd, $string) = (shift, shift);
        my $parsed_cmd = parse_command($self, $cmd);
        $string =~ s/^\n// if $parsed_cmd->{cmd} eq 'PRE';
        push @breakup, $parsed_cmd, $string;
    }

    # Look for end-markings, to detect compounds.
    for(my $endcmdnr=0; $endcmdnr<=$#breakup; $endcmdnr+=2)
    {
        next unless $breakup[$endcmdnr]{cmd} =~ m!^/!;
        my $cmd = substr $breakup[$endcmdnr]{cmd}, 1;

        # Look back for begin.
        my $begincmdnr;
        for($begincmdnr=$endcmdnr-2; $begincmdnr>0; $begincmdnr-=2)
        {   next if ref $breakup[$begincmdnr] eq 'ARRAY';
            last if $breakup[$begincmdnr]{cmd} eq $cmd;
        }

        if($begincmdnr<0)
        {   warn "No start for </$cmd>.\n";
            $breakup[$endcmdnr]{cmd} = 'TEXT';
            next;
        }

        # Make the nesting.
        # "xx",<CMD>,yy,</CMD>,"zz" --> "xx",[<CMD>,"yy" ],"zz"
        my $length  = $endcmdnr-$begincmdnr+1;
        my $nesting = [ @breakup[($begincmdnr)..($endcmdnr-1)] ];
        splice @breakup, $begincmdnr, $length, $nesting;
        $endcmdnr -= ($length-1);
    }

    return \@breakup;
}

# PARSETREE
# Show a parsing.

sub parseTree($;$)
{   my ($self, $leaf, $indent) = @_;
    $indent ||= '';

    my $ret = '';
    for(my $str=0; $str<@$leaf; $str+=2)
    {
        if(ref $leaf->[$str] eq 'ARRAY')
        {   $ret .= "$indent\[ "
                  . $self->parseTree($leaf->[$str], "$indent  ")
                  . "$indent], ";
        }
        else
        {   $ret .= ($str==0 ? "" : $indent)
                  . "$leaf->[$str]{cmd}: "
                  . join ",",
                        map { $_ ne "cmd" && "$_ => $leaf->[$str]{$_}"}
                            sort keys %{$leaf->[$str]};
        }

        $ret .= "$indent\"$leaf->[$str+1]\",\n"
            if defined $leaf->[$str+1];   # only undef on toplevel.
    }

    return $ret;
}

1;
