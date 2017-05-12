

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |26.12.2004| JSTENZEL | new.
#         |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
# ---------------------------------------------------------------------------------------

# Helper lib for PerlPoint::Package tests.


# package
package testlib;

# inheritance
@ISA=qw(Exporter);

@EXPORT=qw(checkHeadline pfilterChecks docstreamDefaultChecks);

# pragmata
use strict;

# load modules
use Storable;
use Test::More;
use PerlPoint::Constants;


# check headline data
sub checkHeadline
 {
  # get paramaters
  my ($results, $depth, $elongPath, $eshortPath, $elevelPath, $epagePath, $vars)=@_;

  # check path data
  my $pathData=shift(@$results);
  is(ref($pathData), 'ARRAY', 'Headline check: path array data type.');
  is(scalar(@$pathData), 5, "Headline check: path array size.");

  # check headline path
  my $headlinePath=$pathData->[0];
  is(ref($headlinePath), 'ARRAY', 'Headline check: headline path data type.');
  is(scalar(@$headlinePath), $depth, "Headline check: headline path array size.");
  is($headlinePath->[$_], $elongPath->[$_], "Headline check: headline path, ${\($_+1)}. element of $depth (\"${\( defined $headlinePath->[$_] ? $headlinePath->[$_] : 'undefined' )}\").") for 0..($depth-1);

  my $shortcutPath=$pathData->[1];
  is(ref($shortcutPath), 'ARRAY', 'Headline check: shortcut path data type.');
  is(scalar(@$shortcutPath), $depth, 'Headline check: shortcut path array size.');
  is($shortcutPath->[$_], $eshortPath->[$_], "Headline check: shortcut path, ${\($_+1)}. element of $depth (\"${\( defined $shortcutPath->[$_] ? $shortcutPath->[$_] : 'undefined' )}\").") for 0..($depth-1);

  my $levelPath=$pathData->[2];
  is(ref($levelPath), 'ARRAY', 'Headline check: level path data type.');
  is(scalar(@$levelPath), $depth, 'Headline check: level path array size.');
  is($levelPath->[$_], $elevelPath->[$_], "Headline check: level path, ${\($_+1)}. element of $depth (${\( defined $levelPath->[$_] ? $levelPath->[$_] : 'undefined' )}).") for 0..($depth-1);

  my $pagenumPath=$pathData->[3];
  is(ref($pagenumPath), 'ARRAY', 'Headline check: page number path data type.');
  is(scalar(@$pagenumPath), $depth, 'Headline check: page number path array size.');
  is($pagenumPath->[$_], $epagePath->[$_], "Headline check: page number path, ${\($_+1)}. element of $depth (${\( defined $pagenumPath->[$_] ? $pagenumPath->[$_] : 'undefined' )}).") for 0..($depth-1);

  my $variables=$pathData->[4];
  is(ref($variables), 'HASH', 'Headline check: variables data type.');
  is(scalar(keys %$variables), scalar(keys %$vars), 'Headline check: variable names.');
  is($variables->{$_}, $vars->{$_}, "Headline check: value of variable $_ (\"$variables->{$_}\").") for sort keys %$vars;
 }


# Paragraph filter tests.
sub pfilterChecks
 {
  # get parameters
  my ($results, $startLevel, $startPage, $varhash)=@_;

  # headline
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, '01: A filtered headline', '');
  {
   my $docstreams=shift(@$results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@$results, 1, ['01: A filtered headline'], ['01: A filtered headline'], [$startLevel], [$startPage], $varhash);
  }
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '01: A filtered headline');
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # block
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '10: A');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '11: filtered');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '12: block.');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '13:');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '14: With a');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '15: continuation.');
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);

  # another filtered block
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '80: Another');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '81: filtered');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '82: block.');
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);

  # non filtered block
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'With a non filtered');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'successor.');
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);

  # filtered verbatim block
  is(shift(@$results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  01: A\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  02:\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  03: filtered\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  04:\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  05: verbatim block.\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  06:\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  07: With special characters like \"\\\" and \">\".\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  08: All right?\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_COMPLETE);

  # text
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '01');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': A filtered text with special characters like "');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '\\');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '" and "');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '>".');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # list
  is(shift(@$results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
  is(shift(@$results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '01: A filtered bullet list point.');
  is(shift(@$results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

  is(shift(@$results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, (0) x 4);
  is(shift(@$results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '02: A filtered ordered list point.');
  is(shift(@$results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, (0) x 4);

  is(shift(@$results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_START, (0) x 5);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A filtered definition');
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'list point. (03)');
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_COMPLETE, (0) x 5);

  # filtered block following a filtered list
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '01: A');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '02: filtered');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '03: block');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '04: - following a filtered list.');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '05: ');
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This should work!');
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);

  # unfiltered text
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'B');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A Tag');
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'B');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'starts the successor paragraph (should cause no trouble).');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # next list
  is(shift(@$results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
  is(shift(@$results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '01: A filtered bullet list point.');
  is(shift(@$results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

  is(shift(@$results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, (0) x 4);
  is(shift(@$results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '02: A filtered ordered list point.');
  is(shift(@$results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, (0) x 4);

  is(shift(@$results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_START, (0) x 5);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A filtered definition');
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'list point. (03)');
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_COMPLETE);
  is(shift(@$results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_COMPLETE, (0) x 5);

  # unfiltered text
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'B');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A Tag');
  is(shift(@$results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'B');
  {
   my $pars=shift(@$results);
   is(ref($pars), 'HASH');
   is(join(' ', sort keys %$pars), '');
  }
  is(shift(@$results), 1);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'starts the successor paragraph (should cause no trouble).');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
 }


# docstream default checks
sub docstreamDefaultChecks
 {
  # get parameters
  my ($results, $docstreamStartLevel, $docstreamStartPage, $varhash)=@_;

  # checks
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A two stream doc', '');
  {
   my $docstreams=shift(@$results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), 'The 2nd object The first object');
   checkHeadline(\@$results, 1, ['A two stream doc'], ['A two stream doc'], [$docstreamStartLevel], [$docstreamStartPage], $varhash);
  }
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A two stream doc');
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This document compares two imaginary objects');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The first object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Manufacturer, price, and more common data of the 1st item');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The 2nd object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Manufacturer, price, and more common data of the 2nd item');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'Advantages', '');
  {
   my $docstreams=shift(@$results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), 'The 2nd object The first object');
   checkHeadline(\@$results, 2, ['A two stream doc', 'Advantages'], ['A two stream doc', 'Advantages'], [$docstreamStartLevel, 1], [$docstreamStartPage, $docstreamStartPage+1], $varhash);
  }
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Advantages');
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'What they are good in');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The first object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Advantages of this 1st item');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The 2nd object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Advantages of this 2nd item');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'Suggestions', '');
  {
   my $docstreams=shift(@$results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), 'The 2nd object The first object');
   checkHeadline(\@$results, 2, ['A two stream doc', 'Suggestions'], ['A two stream doc', 'Suggestions'], [$docstreamStartLevel, 2], [$docstreamStartPage, $docstreamStartPage+2], $varhash);
  }
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Suggestions');
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Talks about things to be improved');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The first object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '1st item can be improved this way');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The 2nd object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '2nd item can be improved this way');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'Conclusion', '');
  {
   my $docstreams=shift(@$results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), 'The 2nd object The first object');
   checkHeadline(\@$results, 2, ['A two stream doc', 'Conclusion'], ['A two stream doc', 'Conclusion'], [$docstreamStartLevel, 3], [$docstreamStartPage, $docstreamStartPage+3], $varhash);
  }
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Conclusion');
  is(shift(@$results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'What the editors think and suggest');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The first object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A short summary about item 1');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@$results), $_) foreach (DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, 'The 2nd object');

  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A short summary about item 2');
  is(shift(@$results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@$results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
 }


# flag successfull load
1;


