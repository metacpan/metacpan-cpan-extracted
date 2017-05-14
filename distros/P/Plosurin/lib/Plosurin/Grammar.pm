#===============================================================================
#
#  DESCRIPTION:  grammars
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Plosurin::Grammar - Grammars for Closure Templates 

=head1 SYNOPSIS

        use Regexp::Grammars;
        use Plosurin::Grammar;

=head1 DESCRIPTION

Plosurin::Grammar - Grammars for Closure Templates 

=cut
package Plosurin::Grammar;
use strict;
use warnings;
use v5.10;
use Regexp::Grammars;

=head2 Plosurin::Template::Grammar - template file grammar

    qr{
    my $r = qr{
       <extends: Plosurin::Template::Grammar>
        <matchline>
        \A <File> \Z
    }xms;
    if ( $txt =~ $r) {
        ...
    } 
    
=cut
qr{
    <grammar: Plosurin::Template::Grammar>
    <objrule: Plo::File>
    <namespace>(?{ $MATCH{file} = $file//"linein"})
    <[templates=template]>+ % <_sep=(\s+)> \s+
    <objtoken: Plo::template> <header> <template_block>
    <rule: namespace> \{namespace <id>\} \n+
    <rule: id>  [\.\w]+
    <rule: header>
        <javadoc_start>
        <[h_comment]>+ % (\s+)
        (?: <[h_params]>+ % (\s+) )?
        <javadoc_end>
    <rule: javadoc_start>\/\*\*?
        | \/\*\n<matchline><fatal:(?{say "JavaDoc must start with /**! at $file line $MATCH{matchline} : $CONTEXT" })>

    <rule: javadoc_end>     \*\/
#        | <matchline><fatal:(?{say "JavaDoc must end with */!  at $file line $MATCH{matchline} : $CONTEXT" })>

    <rule: h_comment>       \* <raw_str>?
    <rule: raw_str>         [^@\n]+
    <objrule: Plo::h_params> \* \@param<is_notreq=(\?)>? <id> <raw_str>
    
    <rule: template_block>
            <matchpos>
            <matchline>
            <start_template>
            <raw_template=(.*?)>
            <stop_template>
    <rule: raw_template>  (!? <stop_template> ) .*?

    <rule: start_template> \{template <name=(\.\w+)>\} 
    | <matchline><fatal:(?{say "Bad template definition at $file line $MATCH{matchline} : $CONTEXT" })>
    <rule: stop_template>  \{\/template\}
  }xms;

=head2 Plosurin::Grammar - soy grammar

    my $r = qr{
     <extends: Plosurin::Grammar>
    \A  <[content]>* \Z
    }xms;
    if ( $txt =~ $r) {
        ...
    } 
    
=cut

qr{
     <grammar: Plosurin::Grammar>
#    \A  <[content]>* \Z
    <objtoken: Soy::Node=content>
        <matchpos>
        <matchline>
        (?:

         <obj=raw_text>
        |<obj=command_include>
        |<obj=command_if>
        |<obj=command_call_self>
        |<obj=command_call>
        |<obj=command_import>
        |<obj=command_foreach>
        |<obj=command_print>
        |<obj=raw_text_add>

        )

    <objrule: Soy::raw_text=raw_text_add>
            <matchpos>      (.+?)

#    <require: (?{ length($CAPTURE) > 0 })>
#        <fatal:(?{say "May be command ? $MATCH{raw_text_add} at $MATCH{matchpos}"})>

    <objrule: Soy::command_print>
             \{<is_explicit=(print)>? <expression>\}

    <objrule: Soy::command_include>
              \{include <[attribute]>{2} % <_sep=(\s+)> \}
             |\{include 
                <matchpos>
                <fatal:(?{say "'Include' require 2 attrs at $MATCH{matchpos}"})>

    <token: attribute>
        <name=(\w+)>
        =
        ['"] <value=(?: ([^'"]+) )>  ['"]

    <token: variable>            \$?\w+ 
    <objtoken: Soy::expressiong>  .*?
    <objrule:  Soy::raw_text>    [^\{]+


    <objrule: Soy::command_if>
        \{if <expression>\} <[content]>+?
         (?:
          <[commands_elseif=command_elseif]>*
          <command_else>
          )?
         \{\/if\}

    <objrule: Soy::command_elseif>
        <matchpos>
        <matchline>
        \{elseif <expression>\}
        <[content]>+?

    <objrule: Soy::command_else>
        <matchpos>
        <matchline>
        \{else\}
        <[content]>+?

    #self-ending call block
    <objrule: Soy::command_call_self>
        \{call 
            <tmpl_name=([\.\w]+)> 
            <[attribute]>* % <_sep=(\s+)> 
         \/\}

    <objrule: Soy::command_call>
        \{call <tmpl_name=([\.\w]+)> \}
            <[content=param]>*
        \{\/call\}

    <objtoken: Soy::Node=param> 
        <matchpos>
        <matchline> 
        (?:
            <obj=command_param_self>
          | <obj=command_param>
        )

    <objrule: Soy::command_param_self>
        \{param
            <name=variable> : <value=(.*?)> 
         \/\}

    <objrule: Soy::command_param>
        \{param <name=(.*?)> \}
            <[content]>+?
        \{\/param\}
                  
    # {import file="test.pod6" rule=":public"}
    # {import file="test.pod6" }
    <objrule: Soy::command_import>
        \{import <[attribute]>+ % <_sep=(\s+)> \/?\}

    #{foreach ...}...{ifempty}...{/foreach}
    <objrule: Soy::command_foreach> 
            \{foreach <local_var=expression> in <expression> \}
                <[content]>+?
                (?:
                 <command_foreach_ifempty>
                )?
            \{\/foreach\}

     <objrule: Soy::command_foreach_ifempty>
        <matchpos>
        <matchline> 
        \{ifempty\}<[content]>+?

}xms;

=head2 Plosurin::Exp::Grammar - Expression grammar


=cut

qr{
     <grammar: Plosurin::Exp::Grammar>

#level 
    #ternary
    <rule: expr> <Main=add> \? <True=add> \: <False=add>
            | <MATCH=list> 
            | <MATCH=map>
            | <MATCH=add>
#list and map 
    <objrule: Exp::list>\[ <[expr]>* % (,) \]
    <objrule: Exp::map>\[ <[content=keyval]>* % (,) \]

    <objrule: Exp::keyval> <key> : <val=expr>
    <token: key>  <MATCH=String> | <MATCH=Var> | <MATCH=Digit>
#level 
    <objrule: Exp::add>
                <a=mult> <op=([+-])> <b=expr> 
                | <MATCH=mult> 

    <objrule: Exp::mult> 
                <a=term> <op=([*/])> <b=mult>
                | <MATCH=term>

     <objrule: term> 
              <MATCH=Literal> 
            | <Sign=([+-])> \( <expr>\) #unary
            | \( <MATCH=expr> \)

    <token: Literal>
                    <MATCH=Bool>   |
                    <MATCH=Var>    |
                    <MATCH=String> |
                    <MATCH=Digit> 

    <token: Ident>
            <MATCH=([a-z,A-Z_](?: [a-zA-Z_0-9])* )>

    <objtoken: Exp::Var>
            \$ <Ident>

    <objtoken: Exp::Bool>
            true | false

    <objtoken: Exp::Digit>
            [+-]? \d++ (?: \. \d++ )?+

    <objtoken: Exp::String> 
        \'
       <value=(
         (?:
         [^'\\\n\r] 
        | \\ [nrtbf'"] 
         # TODO \ua3ce
        | \s
         )*)>
      \'
}xms;

1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

