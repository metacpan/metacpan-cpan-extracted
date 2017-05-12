#===============================================================================
#
#  DESCRIPTION:  Utils for Perl6 Pod
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Utl;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';


=head2  parse_pod [default_pod => 0 ]

=item * default_pod => 0/1 ,

switch on/off ambient mode for para out of =pod blocks. Default 0 (ambient mode)
return ref to tree

=cut

sub parse_pod {
    my ( $src, %args ) = @_;
    my $r = do {
    use Regexp::Grammars;
    use Perl6::Pod::Grammars;

    qr{
       <extends: Perl6::Pod::Grammar::Blocks>
       <matchline>
        \A <File> \Z
    }xms;
    };
    my $tree;
    if ( $src =~ $r ) {
        use Perl6::Pod::Lex;
        $tree = Perl6::Pod::Lex->new(%args)->make_tree( $/{File} );
    }
    else {
        return undef;
    }
    $tree;
}

=head2 strip_vmargin $vmargin, $txt

  =begin pod
  <vmargin=(\s+)> =para 
                  text
  =end pod

=cut

sub strip_vmargin {
    my ( $vmargin, $content ) = @_;

    #get min margin of text
    my $min = $vmargin;
    foreach ( split( /[\n\r]/, $content ) ) {
        if (m/(\s+)/) {
            my $length = length($1);
            $min = $length if $length < $min;
        }
    }

    #remove only if $min > 0
    if ( $min > 0 ) {
        my $new_content = '';
        foreach ( split( /[\n\r]/, $content ) ) {
            $new_content .= substr( $_, $min ) . "\n";
        }
        $content = $new_content;
    }
    return $content;
}

=head2  parse_para $text

parse formatting codes

Optrions:

=item * allow=>[ 'A', 'B']


=cut

sub parse_para {
    use Perl6::Pod::Codeactions;
    my $text = shift || return [];
    my %delim = ( '<' => '>', '«' => '»', '<<' => '>>' );
    my %allow = ( '*' => 1 );

    my %args = @_;
    if ( my $allow = $args{allow} ) {
        my @list = ref($allow) ? @$allow : ($allow);
        %allow = ();

        #fill allowed fcodes
        @allow{@list} = ();
    }
    my $DEFER_REGEX_COMPILATION = "";
    my $r = $args{reg} || do {
        use Regexp::Grammars;
        use Perl6::Pod::Grammars;
    qr{

       <extends: Perl6::Pod::Grammar::FormattingCodes>
       <debug:off>
       <matchline>
       \A  <Text>  \Z
    <token: Text> <[content]>+
    <token: text>  .+?
    <token: hs>[ \t]*
    <token: hash> \#
    <token: content> <MATCH=C_code> 
                    | <MATCH=L_code>
                    | <MATCH=D_code> 
                    | <MATCH=X_code>
                    | <MATCH=P_code>
                    | <MATCH=default_formatting_code> 
                    | <.text>
    <token: ldelim> <%delim>
    <token: rdelim> (??{ quotemeta $delim{$ARG{ldelim}} })
    <token: isValideFCode>
            <require: (?{ 
            ( $ARG{name} && ( $ARG{name} eq  uc($ARG{name} ) ) ) 
                        &&
            ( exists $allow{'*'} ||  exists $allow{$ARG{name}} )
            
            })>
    <rule: C_code>(?! \s+)
       <name=([C])><isValideFCode(:name)>
            <ldelim>     <content=( .*? )>   <rdelim(:ldelim)>
    <rule: D_code>(?! \s+)
      <name=([D])><isValideFCode(:name)>
            <ldelim>  <term=([^\|]*?)> (?: \| <[syns=(\S+)]>+ % ;)?  <rdelim(:ldelim)>
    <rule: L_x_code>(?! \s+)
       <name=(L)><isValideFCode(:name)>
            <ldelim>     <content=( .*? )>   <rdelim(:ldelim)>

    <rule: L_code>(?! \s+)
      <name=(L)><isValideFCode(:name)>
            <ldelim>
            #alternate presentation
     (?: <alt_text=([^\n\|]*?)> \| )? #(.*) \| not work for 
    #L< http://cpan.org > B<sd > L< haname | http:perl.html  >
    # '' => 'L< http://cpan.org > B<sd > L< haname | http:perl.html  >'

    #        (?:<alt_text=(.*?)>)? #hack

                <scheme=([^|\s:]+:)>? #scheme specifier

                (?: <is_external=(//)> )? 
                  <address=([^\|]*?)>?
                 (?:<hash><section=(.*?)> )? #internal addresses
            <rdelim(:ldelim)>
    <rule: X_code_entry> <[entry=([^,\;]+?)]>* % (\s*,\s*)
    <rule: X_code>(?! \s+)
     <name=(X)><isValideFCode(:name)>
            <ldelim>
          # X<text>
          ( <text=([^\n\|]*?)>(?{$MATCH{entry}=$MATCH{text}; $MATCH{form} = 1  })
          |
            <text=([^\n\|]*?)>? \| <[entries=X_code_entry]>* % (\s*\;\s*) 
            (?{$MATCH{form} = 2})
             )
            <rdelim(:ldelim)>

    <rule: P_code>
     <name=(P)><isValideFCode(:name)>
             <ldelim> <.hs> 
                <scheme=([^|\s:]+:)>? #scheme specifier
                (?: <is_external=(//)> )? 
                  <address=([^\|]*?)> 
            <.hs> <rdelim(:ldelim)>

    <token: default_formatting_code> 
      <name=(\w)><isValideFCode(:name)>
            <ldelim> <.hs> <[content]>*? <.hs> <rdelim(:ldelim)>
    $DEFER_REGEX_COMPILATION
}xms;
      };

    if ( $text =~ $r->with_actions( Perl6::Pod::Codeactions->new ) ) {
       return $/{Text};
    }
    else {
        return undef;
    }

}

1;

