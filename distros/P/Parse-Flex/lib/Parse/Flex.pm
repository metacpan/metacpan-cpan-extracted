# Copyright (C) 2003 Ioannis Tambouras <ioannis@earthlink.net> . All rights reserved.
# LICENSE:  Latest version of GPL. Read licensing terms at  http://www.fsf.org .
 
package Parse::Flex;

use 5.006;
use Scalar::Util qw( reftype );
use Fatal qw(open);
use base 'Exporter';
use warnings;
use strict;


our $VERSION  = '0.12';
our @EXPORT   = qw( typeme );
#yyget_lineno yyin yylex yyget_lineno  yyget_leng  yyset_debug yyset_in



sub manual {
        return unless my ($soname) = reverse sort  <auto/*so>;
        my $path =  $ENV{PWD} . "/$soname";
        my $libref = DynaLoader::dl_load_file( $path, DynaLoader::dl_load_flags() );
        croak("unresolved symbols")  if DynaLoader::dl_undef_symbols();

        my $sym = DynaLoader::dl_find_symbol( $libref, 'boot_Parse__Flex' );
        my $xs  = DynaLoader::dl_install_xsub('Parse::Flex::bootstrap', $sym );
        &$xs ;
};


# Note:  @INC has been changed earlier (in the BEGIN block)
#manual()  or  bootstrap Parse::Flex $VERSION;;



sub typeme {
        my $param = shift ;
        my $type = reftype $param;
        my $typeref = reftype \$param;
        (! defined $type) and  return $typeref ;
        ($type eq 'SCALAR') and  return 'REF_SCALAR';
        ($type eq 'ARRAY' ) and  return 'REF_ARRAY';
        ($type eq 'GLOB'  ) and  return 'GLOB';
        undef;
}


1;
__END__

=head1 NAME

Parse::Flex - The Fastest Lexer in the West 

=head1 SYNOPSIS

 # First, you must create your custom lexer:
 $ makelexer.pl -n Flex01  grammar.l

 # Then, interface with the lexer you just created:

 use Flex01;
 my $w= gen_walker( 'data.text');
 print $w->();
 print $w->();

 or,
 use Flex01;
 walkthrough( 'data.txt' );

=head1 DESCRIPTION

Parse::Flex works similar to Parse::Lex, but it uses XS for faster performance. 

This module allows you to construct a lexer analyzer with your custom rules.
Parse::Flex is not intended to be used directly; instead, use the script
makelexer.pl to submit your grammar file. The output of the script is
a custom shared library and a custom .pm module which, among other things,
will transparently load the library and provide interface to your (custom) lexer. 
In other words, you supply a grammar.l file to makelexer.pl and you 
receive Flex01.pm and Flex02.so . Then, use only the Flex01.pm 
- since Flex01.pm will automatically load Flex01.so.

The grammar.l file requires the same syntax as flex(1); that is, the actions
are written in C . See the flex(1) documentation to learn the syntax, or fetch 
the sample t/grammar.l file inside this package.

=head2  Interfacing with Parsers 

Almost all Perl parsers expect that your lexer provides
either a list of two values ( token type and token value), or a reference
to such list.  Parse::Flex can provides the right response since it 
consults wantarray context.  

In the particular case when interfacing with Parse::Yapp, you could also
this interface (if you already have a custom parser) :

 my $p = yapp_new  'MyParser'  ;
 print $p->yapp_parse(  'data.txt' ) ;


 


=head2  Loading the Custom Library


As mentioned earlier, your custom Flex01.pm will use bootstrap to automatically
load Flex01.so. Keep the .so where bootstrap can find it; the current
directory is always a good option.

=head2 METHODS

All the following methods are defined inside the shared library for
every custom lexer. Most methods take arguments that are not shown bellow.
They are identical to the equivalent flex(1) functions. For now, consult
the source code at lib/Parse/Flex/Generate.pm (the $xs_content variable).

=over

=item  yylex()
Fetch the the next token. (Your grammar should return 0 at the
end of input).

=item  yyin()
Sets the next input file.

=item  yyset_in()
Sets the next input file.

=item  yyget_in()
Receives a glob to whatever yyin is currently pointing.

=item  yyout()
Sets the where ECHO command should go.

=item  yyset_out()
Sets the where ECHO command should go.

=item  yyget_out()
Receives a glob to whatever yyout is currently pointing.

=item  yyget_text()
The semantic value of the token.

=item  yyget_leng()
The length of the string that holds the semantic value.

=item  yyget_lineno()
The current value of yylineno. ( But first enable it via %option .)

=item  yyset_lineno()
Sets the value for yylineno. ( But first enable it via %option .)

=item  yyset_debug()
If set to non-zero (already the default), the scanner will output debugging info
(provided, of course, you have also enabled it via %option .)

=item  yyget_debug()
Fetch the current value of yy_flex_debug .

=item  yy_scan_string()
The lexer will read its data from this string.

=item  yy_scan_bytes()
The lexer will read n bytes from this string (which could contain nulls).

=item  yyrestart()
Restart scanning from this file.

=item  create_push_buffer()
Create a buffer and push it on buffer_state. Don't forget to pop it from
your grammar rules (when you have to).

=item  yypop_buffer_state()
Remove the top buffer from buffer_state .

=back


=head2 Internal Methods

=over

=item typeme() 

Is an internal method of no interest to the user.

=back

=head1 EXPORT

typeme

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<flex(1)>, L<Parse::Lex>

=cut

