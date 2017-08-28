package Spp;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(repl lint update spp);

=head1 NAME

Spp - String prepare Parser

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

Spp is a tool which parse string, according grammar write with Spp language.

    > spp

then shell would ouput:

    This is Spp REPL. type 'exit' to exit.
    >>>
    
Lint grammar.file:

    > spp grammar.file

Parse text.file according grammar.file

    > spp grammar.file text.file
    
Spp also could use as Module:

    use 5.012;
    use Spp qw(spp);
    
    my $ast = spp($grammar_file, $string_file);
    say to_json($ast);

=head1 EXPORT

    spp
    lint
    update
    repl

=cut

use 5.012;
use Spp::Ast::SppAst qw(get_spp_ast);
use Spp::Tools;
use Spp::IsAtom;
use Spp::LintAst qw(lint_ast);
use Spp::Cursor;
use Spp::MatchGrammar qw(match_grammar error_report);
use Spp::OptSppAst qw(opt_spp_ast);
use Spp::Rule::SppRule qw(get_spp_rule);

sub get_ast_table {
   my $ast   = shift;
   my $table = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      if (exists $table->{$name}) {
         say("repeat token define $name");
      }
      $table->{$name} = $rule;
   }
   return $table;
}

sub get_spp_parser {
  my $ast   = get_spp_ast();
  my $door  = first(first($ast));
  my $table = get_ast_table($ast);
  return [$door, $table];
}

sub get_grammar_ast {
  my $grammar_text = shift;
  my $spp_parser = get_spp_parser();
  my ($door, $table) = @{ $spp_parser }; 
  my $cursor = new_cursor($grammar_text, $table);
  my $match = match_grammar($door, $cursor);
  error_report($cursor) if is_false($match);
  my $ast    = opt_spp_ast($match);
  return $ast;
}

sub get_grammar_parser {
  my $grammar_text = shift;
  my $ast = get_grammar_ast($grammar_text);
  my $table = get_ast_table($ast);
  my $door = $ast->[0][0];
  return [ $door, $table ];
}

sub to_ast_func {
   my $code = shift;
   my $str  = <<'EOFF';
## Create by Spp::to_ast_func()   
package Spp::Ast::SppAst;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_spp_ast);

use JSON::XS qw(decode_json);

sub get_spp_ast {
   return decode_json(<<'EOF'
EOFF
   return $str . to_json($code) . "\nEOF\n) }\n1;";
}

sub parse {
  my ($parser, $text) = @_;
  my ($door, $table) = @{ $parser };
  my $cursor = new_cursor($text, $table);
  my $match = match_grammar($door, $cursor);
  error_report($cursor) if is_false($match);
  return $match;
}

sub parse_ast {
  my $ast = shift;
  my $door = $ast->[0][0];
  my $table = get_ast_table($ast);
  if (exists $table->{'text'}) {
    my $text = get_text($table->{'text'});
    my $cursor = new_cursor($text, $table);
    return match_grammar($door, $cursor);
  }
  if (exists $table->{'file'}) {
    my $file = get_text($table->{'file'});
    my $text = read_file($file);
    my $cursor = new_cursor($text, $table);
    return match_grammar($door, $cursor);
  }
  return $ast;
}

sub get_text {
  my $rule = shift;
  return $rule->[1] if is_str_atom($rule);
  error("could not get $rule text");
}

## test basic parse rule
sub repl {
   my $spp_parser = get_spp_parser();
   my ($door, $table) = @{ $spp_parser }; 
   say("This is Spp REPL, type enter to exit.");
   while (1) {
      print(">> ");
      my $line = <STDIN>;
      $line = trim($line);
      exit() if $line eq '';
      my $cursor = new_cursor($line, $table);
      my $match = match_grammar($door, $cursor);
      if (is_false($match)) {
         $cursor->{debug} = 1;
         $cursor->{off}   = 0;
         match_grammar($door, $cursor);
      }
      else {
         # say(to_json($match));
         my $ast = opt_spp_ast($match);
         $ast = parse_ast($ast);
         say(to_json($ast));
      }
   }
}

sub update {
  my $rule_str  = get_spp_rule();
  my $ast = get_grammar_ast($rule_str);
  lint_ast($ast);
  my $code = to_ast_func($ast);
  write_file("SppAst.pm", $code);
  say("write SppAst.pm ok!");
}

sub lint {
  my $spp_file  = shift;
  my $spp_code  = read_file($spp_file);
  my $ast = get_grammar_ast($spp_code);
  lint_ast($ast);
}

sub spp {
   my ($grammar_file, $text_file) = @_;
   my $grammar = read_file($grammar_file);
   my $text    = read_file($text_file);
   my $grammar_parser = get_grammar_parser($grammar);
   my $ast = parse($grammar_parser, $text);
   return $ast;
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
