# * inprogressProhibitTestPrint -- use diag instead of print with Test::More

#  * inprogressProhibitTestPrint -- diag instead of print with Test::More

# =item inprogressProhibitTestPrint -- use diag instead of print with C<Test::More>
#
# See L<Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint>.




# print <<HERE ... look at body part


# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_perl_filehandle);

# uncomment this to run the ### lines
#use Smart::Comments;


use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp tests);
use constant applies_to           => ('PPI::Token::Word');


# Test::Parser
#
my $test_print_ok_re
  = qr/^([ \t]*#|ok|not |\d+\.\.[^.]|pragma |TAP version |Bail out)/;

sub violates {
  my ($self, $elem, $document) = @_;

  _document_is_test_script($document) or return;
  $elem eq 'print' or return;

  my ($handle, $rest) = _print_handle_and_rest($elem);
  _handle_is_std($handle) or return;

  my $str = _arg_start_string($rest);
  return if $str =~ $test_print_ok_re;

  return $self->violation
    ((_document_is_using_module($document,'Test::More')
      ? '"print"s better as diag() in a Test::More script'
      : '"print"s in a test script better with "#"'),
     '',
     $elem);
}

sub _document_is_test_script {
  my ($document) = @_;
  if (my $filename = $document->filename) {
    if ($filename =~ /\.t$/) { return 1; }
  }
  return (_document_is_using_module($document,'Test::More')
          || _document_is_using_module($document,'Test::Simple'));
}

sub _arg_start_string {
  my ($elem) = @_;
  if ($elem && $elem->isa('PPI::Token::Quote')) { return $elem->string };
  return '';
}

my %comma = (',' => 1, '=>' => 1);
sub _print_handle_and_rest {
  my ($elem) = @_;
  my $handle = $elem->snext_sibling;
  my $rest = $handle && $handle->snext_sibling;
  ### _print_handle_and_rest: $handle
  ###                   rest: $rest

  if (! $rest) {
    # "print FOO" is a func FOO if exists, else handle FOO
    # assume it's a func, except for the builtin perl handles
    if ($handle && is_perl_filehandle($handle)) {
      return ($handle, $rest);
    } else {
      ###   no handle
      return (undef, $handle);
    }
  }

  if (
      # "print 123, ..."
      # "print 123+ ..."
      ($rest->isa('PPI::Token::Operator'))

      # "print 123;"
      || ($rest->isa('PPI::Token::Structure') && $rest eq ';')

      # "print FOO()" is a function call printed to stdout
      || ($rest->isa('PPI::Structure::List')
          # but "print FOO (...)" with whitespace is a handle
          && $handle->next_sibling == $rest)
     ) {
    ###   no handle
    return (undef, $handle);
  } else {
    # "print FOO ..."
    return ($handle, $rest);
  }
}

# return true if $elem is a print handle to STDOUT or STDERR or no handle,
# meaning the currently "select" handle, which is assumed to be STDOUT
#
my %std = (STDOUT => 1, STDERR => 1);
sub _handle_is_std {
  my ($elem) = @_;
  $elem = _handle_destination($elem);
  ### _handle_destination: $elem
  if (! $elem) { return 1 }
  if (ref $elem && ! $elem->isa('PPI::Token::Word')) { return 0; }
  return $std{$elem};
}

# $elem is the handle argument to a "print" statement.
# Return an element which is the destination, usually a PPI::Token::Word or
# PPI::Token::Symbol, but possibly a PPI::Statement for an expression.  If
# there's no explicit destination then return undef.
#
sub _handle_destination {
  my ($elem) = @_;

  if ($elem && $elem->isa('PPI::Structure::Block')) {
    # PPI::Structure::Block       { ... }
    #   PPI::Statement
    #     PPI::Token::Word        'STDOUT'

    # the guts of a "print {FOO}" or "print {$x}"
    $elem = _single_content($elem);

    if ($elem->isa('PPI::Statement')) {
      my @children = $elem->children;
      while (@children && $children[0]->isa('PPI::Token::Cast')) {
        shift @children;
      }
      if (@children == 1) {
        $elem = $children[0];
      }
    }
  }

  if ($elem
      && $elem->isa('PPI::Token::Symbol')

      && $elem->raw_type eq '*') {
    return substr ($elem->content, 1);
  }

  return $elem;
}

# skip down through single-element children of $elem
# the return is an element with either no children, or more than one child
sub _single_content {
  my ($elem) = @_;
  for (;;) {
    if (! $elem->can('schildren')) {
      return $elem;
    }
    my @children = $elem->schildren;
    if (@children != 1) {
      return $elem; # no children, or more than one child
    }
    $elem = $children[0];
  }
}

# return true if $document contains a "use" of $module
sub _document_is_using_module {
  my ($document, $module) = @_;

  my $key = __PACKAGE__ . ".using_$module";
  if (! exists $document->{$key}) {
    $document->{$key} = !! $document->find_first
      (sub {
         my ($document, $elem) = @_;
         if ($elem->isa('PPI::Statement::Include')
             && $elem->type ne 'no'
             && $elem->module eq $module) {
           return 1; # found
         } else {
           return 0; # no-match, and continue looking
         }
       });
    ### _document_is_using_module: $document->{$key}
  }
  return $document->{$key};
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint - don't use arbitrary prints in a test script

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp add-on.  It asks you not to use
a raw C<print> in a test script to avoid any chance of confusing the test
parsers.

    print "now doing $some $thing\n";           # bad

Either a C<#> for a comment or C<diag> from C<Test::More> is better.

    print "# a comment about $some $thing\n";   # ok

    use Test::More;
    diag "blah blah blah";                      # ok

C<diag> has the advantage that it will insert C<#> comment after any
newlines in the output too.

Various C<print>s for explicit test output are allowed,

    print "ok 1\n"                       # ok
    print "not ok 2 - some reason\n"     # ok
    print "pragma +something\n"          # ok
    print "Bail out\n"                   # ok


commentize is that it guarantees the output won't be
misinterpreted by the test harnesses, see L<Test::More/Diagnostics>.



    print "ok now we're starting\n";    # bad
    print STDERR "something\n";         # bad

    # handles for test file setups ok
    print TESTFH "some data";           # ok

 and is under the
C<tests> theme (see L<Perl::Critic/POLICY THEMES>).

As with all things perlcritic, it's largely a matter of personal preference
whether you want this actively enforced.  If you're happy to be careful with
your prints then disable this policy from your F<.perlcriticrc> file in the
usual way (see L<Perl::Critic/CONFIGURATION>),

    [-TestingAndDebugging::inprogressProhibitTestPrint]

=head1 LIMITATIONS

A C<print> to an unspecified destination is assumed to be stdout.  If you
use C<select> to go to a test datafile or similar then this assumption will
be wrong.  Hopefully that sort of thing is rare.

    select MYTESTHANDLE;
    print 123;   # reported, but actually ok

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut
