#---------------------------------------------------------------------
package Pod::Elemental::MakeSelector;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 5 Jun 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Build complex selectors as a single sub
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

our $VERSION = '0.12';
# This file is part of Pod-Elemental-MakeSelector 0.12 (October 17, 2015)

use Carp qw(croak);

use Sub::Exporter -setup => {
  exports => [ qw(make_selector) ],
  groups  => { default => [ qw(make_selector) ]},
};

#=====================================================================
# Recturn true if the first element of the arrayref is not a string
# starting with -

sub _has_optional_parameter
{
  my ($inputR) = @_;

  @$inputR and (ref $inputR->[0] or not $inputR->[0] =~ /^-/);
} # end _has_optional_parameter

#---------------------------------------------------------------------
sub required_parameter
{
  my ($inputR, $error_message) = @_;

  croak($error_message) unless defined(my $val = shift @$inputR);

  $val;
} # end required_parameter

#---------------------------------------------------------------------
sub add_value
{
  my ($valuesR, $value) = @_;

  push @$valuesR, $value;

  '$val' . $#$valuesR;
} # end add_value

#---------------------------------------------------------------------
sub join_expressions
{
  my ($op, $expressionsR) = @_;

  return @$expressionsR unless @$expressionsR > 1;

  '(' . join("\n    $op ", @$expressionsR) . "\n  )";
} # end join_expressions

#---------------------------------------------------------------------
# Supports only string, Regexp, or arrayref of either.
# Nested arrayrefs should work, but are not documented.

sub smart_match
{
  my ($valuesR, $value, $match) = @_;

  TEST_REF: {
    my $ref = ref $match;

    if ($ref eq 'ARRAY') {
      my $count = @$match;
      if ($count == 0) {
        return '0';               # Empty array never matches
      } elsif ($count == 1) {
        $match = $match->[0];
        redo TEST_REF;
      } else {
        my $exp = join_expressions('or',
          [ map smart_match($valuesR, '$v', $_), @$match ]
        );
        if ($value eq '$v') {
          return $exp;
        } else {
          return sprintf 'do { my $v = %s; %s }', $value, $exp;
        }
      }
    } elsif ($ref) {
      return "$value =~ " . add_value($valuesR, $match);
    } else {
      return "$value eq " . add_value($valuesR, $match);
    }
  }

  die "Can't reach";
} # end smart_match

#---------------------------------------------------------------------
sub conjunction_action
{
  my ($op, $valuesR, $inputR) = @_;

  my $arrayR = shift @$inputR;
  croak "Expected arrayref for -$op, got $arrayR"
      unless ref($arrayR) eq 'ARRAY';

  my @expressions;
  build_selector($valuesR, \@expressions, @$arrayR);

  join_expressions($op, \@expressions);
} # end conjunction_action

#---------------------------------------------------------------------
sub region_action
{
  my ($valuesR, $inputR, $pod) = @_;

  my @expressions = type_action(qw(isa Element::Pod5::Region));

  push @expressions, ($pod ? '' : 'not ') . '$para->is_pod'
      if defined $pod;

  if (_has_optional_parameter($inputR)) {
    push @expressions, smart_match($valuesR, '$para->format_name',
                                   shift @$inputR);
  } # end if specific format(s) listed

  join_expressions(and => \@expressions);
} # end region_action

#---------------------------------------------------------------------
sub type_action
{
  my ($check, $class) = @_;

  "\$para->$check('Pod::Elemental::$class')";
} # end type_action

#---------------------------------------------------------------------
our %action = (
  -and     => sub { conjunction_action(and => @_) },
  -or      => sub { conjunction_action(or  => @_) },
  -blank   => sub { type_action(qw(isa Element::Generic::Blank)) },
  -flat    => sub { type_action(qw(does Flat)) },
  -node    => sub { type_action(qw(does Node)) },

  -code => sub {
    my ($valuesR, $inputR) = @_;

    my $name = add_value($valuesR,
                         required_parameter($inputR, "-code requires a value"));
    "$name->(\$para)";
  }, #end -code

  -command => sub {
    my ($valuesR, $inputR) = @_;

    my @expressions = type_action(qw(does Command));

    if (_has_optional_parameter($inputR)) {
      push @expressions, smart_match($valuesR, '$para->command', shift @$inputR);
    } # end if specific command(s) listed

    join_expressions(and => \@expressions);
  }, #end -command

  -content => sub {
    my ($valuesR, $inputR) = @_;

    smart_match($valuesR, '$para->content',
                required_parameter($inputR, "-content requires a value"));
  }, #end -content

  -region       => \&region_action,
  -podregion    => sub { region_action(@_, 1) },
  -nonpodregion => sub { region_action(@_, 0) },
); # end %action


#---------------------------------------------------------------------
sub build_selector
{
  my $valuesR = shift;
  my $expR    = shift;

  while (@_) {
    my $type = shift;

    my $action = $action{$type}
        or croak "Expected selector type, got $type";

    push @$expR, $action->($valuesR, \@_);
  } # end while more selectors
} # end build_selector
#---------------------------------------------------------------------

# FIXME: These subs will be documented when I figure out how
# make_selector should be extended.


sub make_selector
{
  my @values;
  my @expressions;

  build_selector(\@values, \@expressions, @_);

  my $code = ("sub { my \$para = shift; return (\n  " .
              join("\n  and ", @expressions) .
              "\n)}\n");

  $code = sprintf("my (%s) = \@values;\n\n%s",
                  join(', ', map { '$val' . $_ } 0 .. $#values),
                  $code)
      if @values;

  #print STDERR $code;
  my ($sub, $err);
  {
    local $@;
    $sub = eval $code;
    $err = $@;
  }

  unless (ref $sub) {
    my $lineNum = ($code =~ tr/\n//);
    my $fmt = '%' . length($lineNum) . 'd: ';
    $lineNum = 0;
    $code =~ s/^/sprintf $fmt, ++$lineNum/gem;

    die "Building selector failed:\n$code$err";
  }

  $sub;
} # end make_selector

#=====================================================================
# Package Return Value:

1;

__END__

=pod

=head1 NAME

Pod::Elemental::MakeSelector - Build complex selectors as a single sub

=head1 VERSION

This document describes version 0.12 of
Pod::Elemental::MakeSelector, released October 17, 2015.

=head1 SYNOPSIS

  use Pod::Elemental::MakeSelector;

  my $author_selector = make_selector(
    -command => 'head1',
    -content => qr/^AUTHORS?$/,
  );

=head1 DESCRIPTION

The selectors provided by L<Pod::Elemental::Selectors> are fairly
limited, and there's no built-in way to combine them.  For example,
there's no simple way to generate a selector that matches a section
with a specific name (a fairly common requirement).

This module exports a single subroutine: C<make_selector>.  It can
handle everything that Pod::Elemental::Selectors can do, plus many
things it can't.  It also makes it easy to combine criteria.  It
compiles all the criteria you supply into a single coderef.

A selector is just a coderef that expects a single parameter: an
object that does Pod::Elemental::Paragraph.  It returns a true value
if the paragraph meets the selector's criteria.

=head1 CRITERIA

Most criteria that accept a parameter accept a string, a regex, or an
arrayref of strings and/or regexes.  However,
Pod::Elemental::MakeSelector I<does not> use Perl's C<~~> smartmatch
operator, because it is considered experimental.  Instead, a limited
form of smartmatching is performed by the code generator.  This means
arrayrefs are iterated when the selector is compiled.  Modifying the
arrayref later will not affect the selector.

Optional parameters must not begin with C<->, or they will be treated
as criteria instead.  If you need an optional parameter that begins
with C<->, put it inside an arrayref.

=head2 Simple Criteria

  -blank, # isa Pod::Elemental::Element::Generic::Blank
  -flat,  # does Pod::Elemental::Flat
  -node,  # does Pod::Elemental::Node

=head2 Command Paragraphs

  -command,           # does Pod::Elemental::Command
  -command => 'head1',           # and is =head1
  -command => qr/^head[23]/,     # and matches regex
  -command => [qw(head1 head2)], # 1 element must match

=head2 Content

  -content => 'AUTHOR',       # matches =head1 AUTHOR
  -content => qr/^AUTHORS?$/, # or =head2 AUTHORS
  -content => [qw(AUTHOR BUGS)], # 1 element must match

This criterion is normally used in conjunction with C<-command> to
select a section with a specific title.

=head2 Regions

  -region, # isa Pod::Elemental::Element::Pod5::Region
  -region => 'list',      # and format_name eq 'list'
  -region => qr/^list$/i, # and format_name matches regex
  -region => [qw(list group)], # 1 element must match
  -podregion    => 'list',          # =for :list
  -nonpodregion => 'Pod::Coverage', # =for Pod::Coverage

Regions are created with the C<=begin> or C<=for> commands.  The
C<-podregion> and C<-nonpodregion> criteria work exactly like
C<-region>, but they ensure that C<is_pod> is either true or false,
respectively.

=head2 Conjunctions

  -and => [ ... ], # all criteria must be true
  -or  => [ ... ], # at least one must be true

These take an arrayref of criteria, and combine them using the
specified operator.  Note that C<make_selector> does C<-and> by default;
S<C<make_selector @criteria>> is equivalent to
S<C<< make_selector -and => \@criteria >>>.

=head2 Custom Criteria

  -code => sub { ... }, # test $_[0] any way you want
  -code => $selector,   # also accepts another selector

=head1 SUBROUTINES

=head2 make_selector

  $selector = make_selector( ... );

C<make_selector> takes a list of criteria and returns a selector that
tests whether a supplied paragraph matches all the criteria.  It does
not allow you to pass a paragraph to be checked immediately; if you
want to do that, then call the selector yourself.  i.e., these two
lines are equivalent:

  s_command(head1 => $para); # From Pod::Elemental::Selectors
  make_selector(qw(-command head1))->($para);

=for Pod::Coverage add_value
build_selector
conjunction_action
join_expressions
region_action
required_parameter
smart_match
type_action

=head1 SEE ALSO

L<Pod::Elemental::Selectors> comes with L<Pod::Elemental>, but is much
more limited than this module.

=head1 DEPENDENCIES

Pod::Elemental::MakeSelector requires L<Pod::Elemental> and Perl 5.8.0
or later.

=head1 BUGS

Please report any bugs or feature requests to bug-pod-elemental-makeselector@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Elemental-MakeSelector

=head1 AUTHOR

Christopher J. Madsen <perl@cjmweb.net>

=head1 SOURCE

The development version is on github at L<http://github.com/madsen/pod-elemental-makeselector>
and may be cloned from L<git://github.com/madsen/pod-elemental-makeselector.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
