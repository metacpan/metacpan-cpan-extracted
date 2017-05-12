package Syntax::Highlight::Shell;
use strict;
use Shell::Parser;

{ no strict;
  $VERSION = '0.04';
  @ISA = qw(Shell::Parser);
}

=head1 NAME

Syntax::Highlight::Shell - Highlight shell scripts

=head1 VERSION

Version 0.04

=cut

my %classes = (
    metachar      => 's-mta',   # shell metacharacters (; |, >, &, \)
    keyword       => 's-key',   # a shell keyword (if, for, while, do...)
    builtin       => 's-blt',   # a builtin command
    command       => 's-cmd',   # an external command
    argument      => 's-arg',   # command arguments
    quote         => 's-quo',   # single (') and double (") quotes
    variable      => 's-var',   # an expanded variable ($VARIABLE)
    assigned      => 's-avr',   # an assigned variable (VARIABLE=value)
    value         => 's-val',   # a value
    comment       => 's-cmt',   # a comment
    line_number   => 's-lno',   # line number
);

my %defaults = (
    pre     => 1, # add <pre>...</pre> around the result? (default: yes)
    nnn     => 0, # add line numbers (default: no)
    syntax  => 'bourne', # shell syntax (default: Bourne shell)
    tabs    => 4, # convert tabs to this number of spaces; zero to disable
);

=head1 SYNOPSIS

    use Syntax::Highlight::Shell;

    my $highlighter = new Syntax::Highlight::Shell;
    $output = $highlighter->parse($script);

If C<$script> contains the following shell code: 

    # an if statement
    if [ -f /etc/passwd ]; then
        grep $USER /etc/passwd | awk -F: '{print $5}' /etc/passwd
    fi

then the resulting HTML contained in C<$output> will render like this: 

=begin html

<style type="text/css">
<!--
.s-mta,                                           /* shell metacharacters */
.s-quo,                                           /* quotes               */
.s-key,                                           /* shell keywords       */
.s-blt  { color: #993333; font-weight: bold;  }   /* shell builtins commands */
.s-var  { color: #6633cc;                     }   /* expanded variables   */
.s-avr  { color: #339999;                     }   /* assigned variables   */
.s-val  { color: #cc3399;                     }   /* values inside quotes */
.s-cmt  { color: #338833; font-style: italic; }   /* comment              */
.s-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */
-->
</style>

<pre>
<span class="s-cmt"># an if statement</span>
<span class="s-key">if</span> [ -f /etc/passwd ]<span class="s-mta">;</span> <span class="s-key">then</span>
    grep <span class="s-var">$USER</span> /etc/passwd <span class="s-mta">|</span> awk -F: <span class="s-quo">'</span><span class="s-val">{print $5}</span><span class="s-quo">'</span> /etc/passwd
<span class="s-key">fi</span>
</pre>

=end html

=head1 DESCRIPTION

This module is designed to take shell scripts and highlight them in HTML 
with meaningful colours using CSS. The resulting HTML output is ready for 
inclusion in a web page. Note that no reformating is done, all spaces are 
preserved. 

=head1 METHODS

=over 4

=item new()

The constructor. Returns a C<Syntax::Highlight::Shell> object, which derives 
from C<Shell::Parser>. 

B<Options>

=over 4

=item *

C<nnn> - Activate line numbering. Default value: 0 (disabled). 

=item *

C<pre> - Surround result by C<< <pre>...</pre> >> tags. Default value: 1 (enabled). 

=item *

C<syntax> - Selects the shell syntax. Check the documentation about the 
C<syntax()> method in C<Shell::Parser> documentation for more information 
on the available syntaxes. Default value: C<bourne>. 

=item *

C<tabs> - When given a non-nul value, converts tabulations to this number of 
spaces. Default value: 4. 

=back

B<Example>

To avoid surrounding the result by the C<< <pre>...</pre> >> tags:

    my $highlighter = Syntax::Highlight::Shell->new(pre => 0);

=cut

sub new {
    my $self = __PACKAGE__->SUPER::new(handlers => {
        default => \&_generic_highlight
    });
    my $class = ref $_[0] || $_[0]; shift;
    bless $self, $class;
    
    $self->{_shs_options} = { %defaults };
    my %args = @_;
    for my $arg (keys %defaults) {
        $self->{_shs_options}{$arg} = $args{$arg} if defined $args{$arg}
    }
    
    $self->syntax($self->{_shs_options}{syntax});
    $self->{_shs_output} = '';
    
    return $self
}

=item parse()

Parse the shell code given in argument and returns the corresponding HTML 
code, ready for inclusion in a web page. 

B<Examples>

    $html = $highlighter->parse(q{ echo "hello world" });

    $html = $highlighter->parse(<<'END');
        # find my name
        if [ -f /etc/passwd ]; then
            grep $USER /etc/passwd | awk -F: '{print $5}' /etc/passwd
        fi
    END

=cut

sub parse {
    my $self = shift;
    
    ## parse the shell command
    $self->{_shs_output} = '';
    $self->SUPER::parse($_[0]);
    $self->eof;
    
    ## add line numbering?
    if($self->{_shs_options}{nnn}) {
        my $i = 1;
        $self->{_shs_output} =~ s|^|<span class="$classes{line_number}">@{[sprintf '%3d', $i++]}</span> |gm;
    }
    
    ## add <pre>...</pre>?
    $self->{_shs_output} = "<pre>\n" . $self->{_shs_output} . "</pre>\n" if $self->{_shs_options}{pre};
    
    ## convert tabs?
    $self->{_shs_output} =~ s/\t/' 'x$self->{_shs_options}{tabs}/ge if $self->{_shs_options}{tabs};
    
    return $self->{_shs_output}
}

=back

=head2 Internal Methods

The following methods are for internal use only. 

=over 4

=item _generic_highlight()

C<Shell::Parser> callback that does all the work of highlighting the code. 

=cut

sub _generic_highlight {
    my $self = shift;
    my %args = @_;
    
    if(index('metachar,keyword,builtin,command,variable,comment', $args{type}) >= 0) {
        $self->{_shs_output} .= qq|<span class="$classes{$args{type}}">| 
                              . $args{token} . qq|</span>|
    
    } else {
        if($args{token} =~ /^(["'])([^"']*)\1$/) {
            $self->{_shs_output} .= qq|<span class="$classes{quote}">$1</span>|
                                  . qq|<span class="$classes{value}">$2</span>|
                                  . qq|<span class="$classes{quote}">$1</span>|
        
        } elsif($args{type} eq 'assign')  {
            $args{token} =~ s|^([^=]*)=|<span class="$classes{assigned}">$1</span>=<span class="$classes{value}">|;
            $args{token} =~ s|$|</span>|;
            $self->{_shs_output} .= $args{token}
        
        } else {
            $self->{_shs_output} .= $args{token}
        }
    }
}

=back

=head1 NOTES

The resulting HTML uses CSS to colourize the syntax. Here are the classes 
that you can define in your stylesheet. 

=over 4

=item *

C<.s-key> - for shell keywords, like C<if>, C<for>, C<while>, C<do>...

=item *

C<.s-blt> - for the builtins commands

=item *

C<.s-cmd> - for the external commands

=item *

C<.s-arg> - for the command arguments

=item *

C<.s-mta> - for shell metacharacters, like C<|>, C<< > >>, C<\>, C<&>

=item *

C<.s-quo> - for the single (C<'>) and double (C<">) quotes

=item *

C<.s-var> - for expanded variables: C<$VARIABLE>

=item *

C<.s-avr> - for assigned variables: C<VARIABLE=value>

=item *

C<.s-val> - for shell values (inside quotes)

=item *

C<.s-cmt> - for shell comments

=back

An example stylesheet can be found in F<examples/shell-syntax.css>.

=head1 EXAMPLE

Here is an example of generated HTML output. It was generated with the 
script F<eg/highlight.pl>. 

The following shell script 

    #!/bin/sh
    
    user="$1"
    
    case "$user" in
      # check if the user is root
      'root')
        echo "You are the BOFH."
        ;;
    
      # for normal users, grep throught /etc/passwd
      *)
        passwd=/etc/passwd
        if [ -f $passwd ]; then 
            grep "$user" $passwd | awk -F: '{print $5}'
        else
            echo "No $passwd"
        fi
    esac

will be rendered like this (using the CSS stylesheet F<eg/shell-syntax.css>): 

=begin html

<pre>
<span class="s-lno">  1</span> <span class="s-cmt">#!/bin/sh</span>
<span class="s-lno">  2</span> 
<span class="s-lno">  3</span> <span class="s-avr">user</span>=<span class="s-val">"$1"</span>
<span class="s-lno">  4</span> 
<span class="s-lno">  5</span> <span class="s-key">case</span> <span class="s-quo">"</span><span class="s-val">$user</span><span class="s-quo">"</span> <span class="s-key">in</span>
<span class="s-lno">  6</span>   <span class="s-cmt"># check if the user is root</span>
<span class="s-lno">  7</span>   <span class="s-quo">'</span><span class="s-val">root</span><span class="s-quo">'</span><span class="s-mta">)</span>
<span class="s-lno">  8</span>     echo <span class="s-quo">"</span><span class="s-val">You are the BOFH.</span><span class="s-quo">"</span>
<span class="s-lno">  9</span>     <span class="s-mta">;</span><span class="s-mta">;</span>
<span class="s-lno"> 10</span> 
<span class="s-lno"> 11</span>   <span class="s-cmt"># for normal users, grep throught /etc/passwd</span>
<span class="s-lno"> 12</span>   *<span class="s-mta">)</span>
<span class="s-lno"> 13</span>     <span class="s-avr">passwd</span>=<span class="s-val">/etc/passwd</span>
<span class="s-lno"> 14</span>     <span class="s-key">if</span> [ -f <span class="s-var">$passwd</span> ]<span class="s-mta">;</span> <span class="s-key">then</span> 
<span class="s-lno"> 15</span>         grep <span class="s-quo">"</span><span class="s-val">$user</span><span class="s-quo">"</span> <span class="s-var">$passwd</span> <span class="s-mta">|</span> awk -F: <span class="s-quo">'</span><span class="s-val">{print $5}</span><span class="s-quo">'</span>
<span class="s-lno"> 16</span>     <span class="s-key">else</span>
<span class="s-lno"> 17</span>         echo <span class="s-quo">"</span><span class="s-val">No $passwd</span><span class="s-quo">"</span>
<span class="s-lno"> 18</span>     <span class="s-key">fi</span>
<span class="s-lno"> 19</span> <span class="s-key">esac</span>
</pre>

=end html

=head1 CAVEATS

C<Syntax::Highlight::Shell> relies on C<Shell::Parser> for parsing the shell 
code and therefore suffers from the same limitations. 

=head1 SEE ALSO

L<Shell::Parser>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-syntax-highlight-shell@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Highlight-Shell>. 
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Syntax::Highlight::Shell
