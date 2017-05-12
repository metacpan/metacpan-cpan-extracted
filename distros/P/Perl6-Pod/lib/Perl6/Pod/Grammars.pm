#===============================================================================
#
#  DESCRIPTION:  Pod6 Grammars
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Grammars;
=pod

=head1 NAME

Perl6::Pod::Grammars - set of grammars for Pod6

=head1 SYNOPSIS

    my $r =  qr{
       <extends: Perl6::Pod::Grammar::Blocks>
       <matchline>
        \A <File> \Z
    }xms;
    my $tree ;
    if ( $src =~ $r  ) {
     $tree = Perl6::Pod::Lex->new(%args)->make_tree( $/{File} );
    }
    else {
        return undef;
    }


=head1 DESCRIPTION

Perl6::Pod::Grammars - set of grammars for Pod6

=cut
our $VERSION = '0.01';

use strict;
use warnings;
use v5.10;
use Regexp::Grammars;
qr{
    <grammar: Perl6::Pod::Grammar::Blocks>
    <token: hs>[ \t]*
    <token: hs1>[ \t]
    <token: hsp>[ \t]+
    <token: newline> <.hs1>* \n
    <token: emptyline> ^ <.hs> \n 

    <rule: File>(?{$MATCH{type}="file"})<[content=block_content]>+
    <rule: directives> begin | for | END | end | config
    <rule: raw_content_blocks> 
               code 
            #io blocks
            | input 
            | output
            | comment
            | table
            # Named blocks 
           |  <MATCH=(\w++)>  <require: (?{ ( $MATCH ne uc($MATCH) )
                                                 &&
                                        ( $MATCH ne lc($MATCH) )  })>
    <rule: raw_content> 
#                .*?
                        (?:(?!^<spaces=hs>?=\w+).)*   # match everythig, except
                                                      # it looks like directive
                    (?{ $MATCH{type} = "raw"})

    <rule: block_content> 
         <MATCH=paragraph_block> 
        | <MATCH=delimblock_raw>
        | <MATCH=delimblock> 
        | <MATCH=config_directive>
        | <MATCH=encoding_directive>
        | <MATCH=alias_directive>
        | <MATCH=abbr_block>
        | <MATCH=text_content> 
#        | <MATCH=ambient_content>

    <token: ambient_content>             <matchpos><matchline>
                                          (?{ $MATCH{type} = "ambient"})
                                         \s+
    <rule: config_directive>             <matchpos><matchline>
                                        (?{ $MATCH{type} = "directive"})
       ^ <spaces=hs>? =<name=(config)>  <block_name=(\S+)>
     ( ( <.newline>  = )? <.hs>  <[attr=pair]>+ % <.hs> )* <.newline>
    <rule: encoding_directive>             <matchpos><matchline>
                                        (?{ $MATCH{type} = "directive"})
       ^ <spaces=hs>? =<name=(encoding)>  <encode_name=(\S+)>  <.newline>

    <token: alias_directive>             <matchpos><matchline>
                                        (?{ $MATCH{type} = "directive"})
       ^ <spaces=hs>? =<name=(alias)> <.hsp> <alias_name=(\w+)> 
     ( ( <.newline>  = )? <.hsp>  <[text=([^\n\r]+)]>  )+ <.newline>

    <token: items><MATCH=(\d+)> 
            | \' <MATCH=([^']+)> \' 
            | \" <MATCH=([^"]+)> \" 
            | <MATCH=(\w+)>
    <token: kv>  <key=items> (?:\=\>) <value=items>
    <rule: pair> \: <not=(\!)>? <name=(\w+)> 
            (?{ $MATCH{type} = 'bool' })
            ( 
    
              # :key[1,2,3]
              \[ <[items]>+ % [,\s] \]
              (?{ $MATCH{type} = 'list' })
            
            | # :key('str')
              \( <items> \)  
              (?{ $MATCH{type} = 'string' })

            | # :key<str>
              \< <items> \>   
              (?{ $MATCH{type} = 'string' })

            | # :key<1 2 3>
              \< <[items]>+ % [\s]  \>   
              (?{ $MATCH{type} = 'list' })

            | # :key{1=>1, 2=> 3 }
              \{ <[items=kv]>+ % <.delim=([,\s]+)>  \}
              (?{ $MATCH{type} = 'hash' })

            )?
            
            (?{ 
                $MATCH{type} eq 'bool' 
                && ( 
                    $MATCH{items} = $MATCH{not} ? 0 : 1  
                    ) 
            })

    <token: delimblock_raw>             <matchpos><matchline>
                                        (?{ $MATCH{type} = "block"})
    ^ <spaces=hs>? =begin <.hs> <!directives> <name=raw_content_blocks>
     ( ( <.newline>  = )? <.hs>  <[attr=pair]>+ % <.hs> )* <.newline>

            <[content=raw_content]>?

     ^ <spacesend=hs>?  =end <.hsp> <\_name> <.hs> <.newline>?

    <token: delimblock>                 <matchpos><matchline>
                                        (?{ $MATCH{type} = "block"})
    ^ <spaces=hsp>? =begin <.hs> <!directives>  <name=(\w+)> 
     ( ( <.newline>  = )? <.hs>  <[attr=pair]>+ % <.hs> )* <.newline>
                   <[content=block_content]>*
                   <.emptyline>*
     ^ <spacesend=hs>?  =end <.hs> <\_name> <.hs> <.newline>?

    <token: paragraph_block>             <matchpos><matchline>
                                    (?{ $MATCH{type} = "block"})
    ^ <spaces=hsp>? =for <.hs> <!directives>   
            (  <name=raw_content_blocks>
               (?{ $MATCH{content_type} = "raw"})
              | <name=(\w+)>  )
     ( ( <.newline>  = )? <.hs>  <[attr=pair]>+ % <.hs> )* <.newline>
                    <[content=text_content(:content_type)]>*
      <.newline>?

    <token: text_content>                <matchpos><matchline>
          (^ <spaces=hsp>? (?! <.emptyline> | <hs>? \=\w+ ) # not start with directive
            [^\n]+ <.newline>)+
           (?{ $MATCH{type} = $ARG{content_type} // "text"})

    <token: text_abbr_content> 
          ( (?! <.emptyline> | <hs>? \=\w+ ) # not start with directive
            [^\n]+ <.newline>)+
           (?{ $MATCH{type} = $ARG{content_type} // "text"})


     <token: abbr_block>                 <matchpos><matchline>
                                     (?{ $MATCH{type} = "block"})
    ^ <spaces=hsp>? =<!directives> (  <name=raw_content_blocks>
               (?{ $MATCH{content_type} = "raw" })
              | <name=(\w+)>  ) <hs> <.newline>?
                    <[content=text_abbr_content(:content_type)]>*
         <.emptyline>?
};

qr{
    <grammar: Perl6::Pod::Grammar::FormattingCodes>
};
1;

__END__


=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

