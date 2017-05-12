#!/usr/bin/perl

package Sub::Lexical;

$VERSION = 0.81;

use strict;
eval q(use warnings) or local $^W = 1;

use Regexp::Common;
use Carp qw(croak cluck);

use constant DEBUG  => 1;

sub new {
  my $class	= shift;
  croak('Sub::Lexical constructor must be called as a class method')
    if $class ne __PACKAGE__;

  cluck("arguments passed to new() aren't in pair form")
    if @_ % 2 != 0;

  ## don't stuff list in if it don't fit
  my $self	= { @_ % 2 == 0 ? @_ : () };

  bless($self, $class);
}

sub subs_found {
  my $self = shift;
  return [] unless defined $self->{info};
  return $self->{info};
}

my $brackets_re     = $RE{balanced}{-parens => '{}'};
my $paren_re        = $RE{balanced}{-parens => '()'};

## regex for fully qualified names which I don't want/need
# my $sub_fullname_re   = qr/[_a-zA-Z](?:(?:\w*)(?:(?:'|::)(?:\w+)+)?)*/;

my $sub_name_re     = qr{[_a-zA-Z](?:[\w_]+)?};
my $sub_proto_re    = qr{\([\$%\\@&\s]*\)};
my $sub_attrib_re   = qr{(?:\s*:\s*$sub_name_re\s*(?:$paren_re)?)*}o;
                      ## my sub foobar (proto) : attrib { "code" }
my $sub_match_re    = qr/    
                            my                      # literal 'my'
                            \s+                     # 1> whitespace
                            sub                     # literal 'my'
                            \s+                     # 1> whitespace
                            ($sub_name_re)          # group 1
                            \s*                     # 0> whitespace
                            (                       # group 2
                                $sub_proto_re  ?    # optional $sub_proto_re
                                $sub_attrib_re ?    # optional $sub_attrib_re
                            ) ?                     # optional group 2
                            \s*                     # 0> whitespace
                            (                       # group 3
                                $brackets_re        # match balanced brackets
                            ) ?                     # optional group 3
                            (?:
                                \s*                 # 0> whitespace
                                ;                   # optional literal ';'
                            ) ?
                        /xo;

## core functions which may expect a function e.g goto &foo
my $core_funcs    = join '|', qw(do defined eval goto grep map sort undef);
## things that *can't* come before or go after a bareword
my $ops_before    = qr/(?<! \$ | % | @ ) | (?>! -> )/x;

sub filter_code {
  my $self = shift;
  croak('filter_code() must be called as an object method')
    if not defined $self or $self eq __PACKAGE__;

  my $code = shift;
  study $code;

  while(my($subname, $subextra, $subcode) = $code =~ /$sub_match_re/) {
    push @{$self->{info}}, {
        name    => $subname,
        extra   => $subextra,
        code    => $subcode
    };

    my $lexname = "\$LEXSUB_${subname}";
    ## 'my sub name {}' => 'my $name; $name = sub {};'
    $code =~ s<$sub_match_re>
              <my \$LEXSUB_$1; \$LEXSUB_$1 = sub $2 $3;>g;

    ## '&name()' => '$name->()'
    $code =~ s<
                &?               # optional &
                $subname         # 'subname'
                \s*              # 0+ whitespace
                (                # group $1
                    $paren_re    # balanced parens
                )                # optional group $1
             >{"$lexname->" . ($1 || '()')}exg;

    ## 'goto &name' => 'goto &$name'
    $code =~ s<($core_funcs) \s* &$subname\b>
              {$1 &$lexname}xg;

    ## '&name' => '$name->(@_)'
    $code =~ s{ (?<!\\) \s* &$subname\b }
              {$lexname->(\@_)}xg;

    ## '\&name' => '$name'
    $code =~ s<(?: \\ \s*)+ &($sub_name_re)\b>
              <\$LEXSUB_$1>xg;

    ## 'name' => '$name->()'
    $code =~ s{(?: ^ | (?<! LEXSUB_) ( (?: $ops_before | \s+) \s* ) )
               $subname \b }
              {$1$lexname->()}xmg;
  }
  return $code;
}

use Filter::Simple;

FILTER_ONLY code => sub {
  $_ = Sub::Lexical->new()->filter_code($_);
};

q(package activated);

__END__

=pod

=head1 NAME

Sub::Lexical - implements lexically scoped subroutines

=head1 SYNOPSIS

  use Sub::Lexical;

  sub foo {
      my @vals = @_;

      my sub bar {
          my $arg = shift;
          print "\$arg is $arg\n";
          print "\$vals are @vals\n";
      }

      bar("just a string");

      my sub quux (@) {
          print "quux got args [@_]\n";
      }

      takesub(\&quux, qw(ichi ni san shi));
  }

  sub takesub { print "executing given sub\n\t"; shift->(@_[1..$#_]) }

  foo(qw(a bunch of args));

=head1 DESCRIPTION

Using this module will give your code the illusion of having lexically
scoped subroutines. This is because where ever a sub is lexically declared
it will really just turn into a C<my()>ed scalar pointing to a coderef.

However the lexically scoped subs seem to work as one might expect them to.
They can see other lexically scoped variables and subs, and will fall out of
scope like they should. You can pass them around like coderefs, give them
attributes and prototypes too if you're feeling brave. Another advantage is
you can use them as B<truly> private methods in packages, thereby realising
the dream of true encapsulation so many have dreamed of.

Your code will be automatically parsed on include (this is a filter module
after all) so the methods listed below are provided so you can filter your own
code manually.

=head1 METHODS

=over 4

=item new

Typical constructor will return a Sub::Lexical object. Must be called as a
class method at the moment

=item subs_found

Returns an ArOH of the form

  [
    {
    'code' => '{ ... }',
    'extra' => '() : attrib',
    'name' => 'foo'
    }
  ]

=item filter_code

It takes one argument which is the code to be filtered and returns a copy
of that code filtered e.g

  my $f = Sub::Lexical->new();
  $filtered = $f->filter_code($code);

=back

=head1 CAVEATS

=over 4

=item *

If you have a sub called foo it will clash with any variable called
LEXSUB_foo within the same scope, as all subs have 'LEXSUB_' appended
to them so as to avoid namespace clashes with other variables (any
suggestions for a cleaner workaround are very much welcome).

=back

=head1 SEE ALSO

perlsub, Regex::Common, Filter::Simple

=head1 THANKS

Damian Conway and PerlMonks for giving me the skills and resources to write this

=head1 AUTHOR

by Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 COPYRIGHT

Copyright (c) 2002, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same terms
as Perl itself.

=cut
