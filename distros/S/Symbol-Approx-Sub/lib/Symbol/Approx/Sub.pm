
=head1 NAME

Symbol::Approx::Sub - Perl module for calling subroutines by approximate names!

=head1 SYNOPSIS

  use Symbol::Approx::Sub;

  sub a {
    # blah...
  }

  aa(); # executes a() if aa() doesn't exist.

  use Symbol::Approx::Sub (xform => 'Text::Metaphone');
  use Symbol::Approx::Sub (xform => undef,
                           match => 'String::Approx');
  use Symbol::Approx::Sub (xform => 'Text::Soundex');
  use Symbol::Approx::Sub (xform => \&my_transform);
  use Symbol::Approx::Sub (xform => [\&my_transform, 'Text::Soundex']);
  use Symbol::Approx::Sub (xform => \&my_transform,
                           match => \&my_matcher,
                           choose => \&my_chooser);

New B<suggest> mode.

  use Symbol::Approx::Sub (suggest => 1);

=head1 DESCRIPTION

This is _really_ stupid. This module allows you to call subroutines by
_approximate_ names. Why you would ever want to do this is a complete
mystery to me. It was written as an experiment to see how well I
understood typeglobs and AUTOLOADing.

To use it, simply include the line:

  use Symbol::Approx::Sub;

somewhere in your program. Then, each time you call a subroutine that doesn't
exist in the current package, Perl will search for a subroutine with
approximately the same name. The meaning of 'approximately the same' is
configurable. The default is to find subroutines with the same Soundex
value (as defined by Text::Soundex) as the missing subroutine. There are
two other built-in matching styles using Text::Metaphone and
String::Approx. To use either of these use:

  use Symbol::Approx::Sub (xform => 'Text::Metaphone');

or

  use Symbol::Approx::Sub (xform => undef,
                           match => 'String::Approx');

when using Symbol::Approx::Sub.

=head2 Configuring The Fuzzy Matching

There are three phases to the matching process. They are:

=over 4

=item *

B<transform> - a transform subroutine applies some kind of transformation
to the subroutine names. For example the default transformer applies the
Soundex algorithm to each of the subroutine names. Other obvious
tranformations would be to remove all the underscores or to change the
names to lower case.

A transform subroutine should simply apply its transformation to each
item in its parameter list and return the transformed list. For example, a
transformer that removed underscores from its parameters would look like
this:

  sub tranformer {
    map { s/_//g; $_ } @_;
  }

Transform subroutines can be chained together.

=item *

B<match> - a match subroutine takes a target string and a list of other
strings. It matches each of the strings against the target and determines
whether or not it 'matches' according to some criteria. For example, the
default matcher simply checks to see if the strings are equal.

A match subroutine is passed the target string as its first parameter,
followed by the list of potential matches. For each string that matches,
the matcher should return the index number from the input list. For example,
the default matcher is implemented like this:

  sub matcher {
    my ($sub, @subs) = @_;
    my (@ret);

    foreach (0 .. $#subs) {
      push @ret, $_ if $sub eq $subs[$_];
    }

    @ret;
  }

=item *

B<choose> - a chooser subroutine takes a list of matches and chooses exactly
one item from the list. The default matcher chooses one item at random.

A chooser subroutine is passed a list of matches and must simply return one
index number from that list. For example, the default chooser is implemented
like this:

  sub chooser {
    rand @_;
  }

=back

You can override any of these behaviours by writing your own transformer,
matcher or chooser. You can either define the subroutine in your own
script or you can put the subroutine in a separate module which
Symbol::Approx::Sub can then use as a I<plug-in>. See below for more details
on plug-ins.

To use your own function, simply pass a reference to the subroutine to the
C<use Symbol::Approx::Sub> line like this:

  use Symbol::Approx::Sub(xform => \&my_transform,
                          match => \&my_matcher,
                          choose => \&my_chooser);

A plug-in is simply a module that lives in the Symbol::Approx::Sub
namespace. For example, if you had a line of code like this:

  use Symbol::Approx::Sub(xform => 'MyTransform');

then Symbol::Approx::Sub will try to load a module called
Symbol::Approx::Sub::MyTransform and it will use a function from within that
module called C<transform> as the transform function. Similarly, the
matcher function is called C<match> and the chooser function is called
C<choose>.

The default transformer, matcher and chooser are available as plug-ins
called Text::Soundex, String::Equal and Random.

=head2 Suggest mode

Version 3.1.0 introduces a 'suggest' mode. In this mode, instead of just
choosing and running an alternative subroutine, your program will still
die as it would without Symbol::Approx::Sub, but the error message you
see will include the suggested alternative subroutine. As an example,
take this code:

  sub aa {
    print "Here's aa()";
  }

  a();

Obviously, if you run this without loading Symbol::Approx::Sub, you'll
get an error message. That message will say "Cannot find subroutine
main::a". With Symbol::Approx::Sub loaded in its default mode, the
module will find C<aa()> instead of C<a()> and will silently run that
subroutine instead.

And that's what makes Symbol::Approx::Sub nothing more than a clever
party trick. It's really not at all useful to run a program when you're
not really sure what subroutines will be called.

But running in 'suggest' mode changes that behaviour. Instead of just
running C<aa()> silently, the module will still C<die()> (as in the
non-Symbol::Approx::Sub behaviour) but the message will be a little
more helpful, as it will include the name of the subroutine that has
been selected as the most likely correction for your typo.

So, if you run this code:

  use Symbol::Approx::Sub (suggest => 1);

  sub aa {
    print "Here's aa()";
  }

  a();

Then your program will die with the error message "Cannot find
subroutine main::a. Did you mean main::aa?".

I like to think that some eighteen years or so after it was
first released, Symbol::Approx::Sub has added a feature that
might actually be of some use.

Thanks to Alex Balhatchet for suggesting it.

=cut

package Symbol::Approx::Sub;

require 5.010_000;
use strict;
use warnings;

our ($VERSION, @ISA, $AUTOLOAD);

use Devel::Symdump;
use Module::Load;
use Exception::Class (
  'SAS::Exception',
  'SAS::Exception::InvalidOption'              => { isa => 'SAS::Exception' },
  'SAS::Exception::InvalidOption::Transformer' => { isa => 'SAS::Exception::InvalidOption' },
  'SAS::Exception::InvalidOption::Matcher'     => { isa => 'SAS::Exception::InvalidOption' },
  'SAS::Exception::InvalidOption::Chooser'     => { isa => 'SAS::Exception::InvalidOption' },
  'SAS::Exception::InvalidParameter'           => { isa => 'SAS::Exception' },
);

$VERSION = '3.1.3';

use Carp;

# List of functions that we _never_ try to match approximately.
my @_BARRED = qw(AUTOLOAD BEGIN CHECK INIT DESTROY END);
my %_BARRED = map { $_ => 1 } @_BARRED;

# import is called when another script uses this module.
# All we do here is overwrite the caller's AUTOLOAD subroutine
# with our own.

=head1 Subroutines

=head2 import

Called when the module is C<use>d. This function installs our AUTOLOAD
subroutine into the caller's symbol table.

=cut

sub import  {
  my $class = shift;

  no strict 'refs'; # WARNING: Deep magic here!

  my %param;
  my %CONF;
  %param = @_ if @_;

  my %defaults = (
    xform   => 'Text::Soundex',
    match   => 'String::Equal',
    choose  => 'Random',
    suggest => 0,
  );

  foreach (keys %param) {
    SAS::Exception::InvalidParameter->throw(
      error => "Invalid parameter $_\n",
    ) unless exists $defaults{$_};
  }

  $CONF{xform}   = _set_transformer(\%param, $defaults{xform});
  $CONF{match}   = _set_matcher(\%param, $defaults{match});
  $CONF{choose}  =_set_chooser(\%param, $defaults{choose});

  $CONF{suggest} = $param{suggest} // $defaults{suggest};

  # Now install appropriate AUTOLOAD routine in caller's package

  my $pkg =  caller(0);
  *{"${pkg}::AUTOLOAD"} = _make_AUTOLOAD(%CONF);
}

# Work out which transformer(s) to use. The valid options are:
# 1/ $param{xform} doesn't exist. Use default transformer.
# 2/ $param{xform} is undef. Use no transformers.
# 3/ $param{xform} is a reference to a subroutine. Use the
#    referenced subroutine as the transformer.
# 4/ $param{xform} is a scalar. This is the name of a transformer
#    module which should be loaded.
# 5/ $param{xform} is a reference to an array. Each element of the
#    array is one of the previous two options.
sub _set_transformer {
  my ($param, $default) = @_;

  unless (exists $param->{xform}) {
    my $mod = "Symbol::Approx::Sub::$default";
    load $mod;
    return [\&{"${mod}::transform"}];
  }

  unless (defined $param->{xform}) {
    return [];
  }

  my $type = ref $param->{xform};
  if ($type eq 'CODE') {
    return [$param->{xform}];
  } elsif ($type eq '') {
    my $mod = "Symbol::Approx::Sub::$param->{xform}";
    load $mod;
    return [\&{"${mod}::transform"}];
  } elsif ($type eq 'ARRAY') {
    my @xforms;
    foreach (@{$param->{xform}}) {
      my $subtype = ref $_;
      if ($subtype eq 'CODE') {
        push @xforms, $_;
      } elsif ($subtype eq '') {
        my $mod = "Symbol::Approx::Sub::$_";
        load $mod;
        push @xforms, \&{"${mod}::transform"};
      } else {
        SAS::Exception::InvalidOption::Transformer->throw(
          error => 'Invalid transformer passed to Symbol::Approx::Sub'
        );
      }
    }
    return \@xforms;
  } else {
    SAS::Exception::InvalidOption::Transformer->throw(
      error => 'Invalid transformer passed to Symbol::Approx::Sub'
    );
  }
}

# Work out which matcher to use. The valid options are:
# 1/ $param{match} doesn't exist. Use default matcher.
# 2/ $param{match} is undef. Use no matcher.
# 3/ $param{match} is a reference to a subroutine. Use the
#    referenced subroutine as the matcher.
# 4/ $param{match} is a scalar. This is the name of a matcher
#    module which should be loaded.
sub _set_matcher {
  my ($param, $default) = @_;

  unless (exists $param->{match}) {
    my $mod = "Symbol::Approx::Sub::$default";
    load $mod;
    return \&{"${mod}::match"};
  }

  unless (defined $param->{match}) {
    return undef;
  }

  my $type = ref $param->{match};
  if ($type eq 'CODE') {
    return $param->{match};
  } elsif ($type eq '') {
    my $mod = "Symbol::Approx::Sub::$param->{match}";
    load $mod;
    return \&{"${mod}::match"};
  } else {
    SAS::Exception::InvalidOption::Matcher->throw(
      error => 'Invalid matcher passed to Symbol::Approx::Sub'
    );
  }
}

# Work out which chooser to use. The valid options are:
# 1/ $param{choose} doesn't exist. Use default chooser.
# 2/ $param{choose} is undef. Use default chooser.
# 3/ $param{choose} is a reference to a subroutine. Use the
#    referenced subroutine as the chooser.
# 4/ $param{choose} is a scalar. This is the name of a chooser
#    module which should be loaded.
sub _set_chooser {
  my ($param, $default) = @_;

  unless (exists $param->{choose}) {
    my $mod = "Symbol::Approx::Sub::$default";
    load $mod;
    return \&{"${mod}::choose"};
  }

  unless (defined $param->{choose}) {
    my $mod = "Symbol::Approx::Sub::$default";
    load $mod;
    return \&{"${mod}::choose"};
  }

  my $type = ref $param->{choose};
  if ($type eq 'CODE') {
    return $param->{choose};
  } elsif ($type eq '') {
    my $mod = "Symbol::Approx::Sub::$param->{choose}";
    load $mod;
    return \&{"${mod}::choose"};
  } else {
    SAS::Exception::InvalidOption::Chooser->throw(
      error => 'Invalid chooser passed to Symbol::Approx::Sub',
    );
  }
}

sub _run_xformers {
  my ($xforms, $sub, @subs) = @_;

  foreach (@$xforms) {
    SAS::Exception::InvalidOption::Transformer->throw(
      error => 'Invalid transformer passed to Symbol::Approx::Sub',
    ) unless defined &$_;
    ($sub, @subs) = $_->($sub, @subs);
  }

  return ($sub, @subs);
}

sub _run_matcher {
  my ($matcher, $sub, @subs) = @_;

  my @match_ind;
  if ($matcher) {
    SAS::Exception::InvalidOption::Matcher->throw(
      error => 'Invalid matcher passed to Symbol::Approx::Sub',
    ) unless defined &{$matcher};
    @match_ind = $matcher->($sub, @subs);
  } else {
    @match_ind = (0 .. $#subs);
  }

  return @match_ind;
}

sub _run_chooser {
  my ($chooser, @subs) = @_;

  SAS::Exception::InvalidOption::Chooser->throw(
    error => 'Invalid chooser passed to Symbol::Approx::Sub'
  ) unless defined &$chooser;
  my $index = $chooser->(@subs);

  return $index;
}

# Create a subroutine which is called when a given subroutine
# name can't be found in the current package. In the import subroutine
# above, we have already arranged that our calling package will use
# the AUTOLOAD created here instead of its own.
sub _make_AUTOLOAD {
  my %CONF = @_;

  return sub {
    my @c = caller(0);
    my ($pkg, $sub) = $AUTOLOAD =~ /^(.*)::(.*)$/;

    # Get a list of all of the subroutines in the current package
    # using the get_subs function from GlobWalker.pm
    # Note that we deliberately omit function names that exist
    # in the %_BARRED hash
    my (@subs, @orig);
    my $sym = Devel::Symdump->new($pkg);
    @orig = @subs = grep { ! $_BARRED{$_} }
                    map { s/${pkg}:://; $_ }
                    grep { defined &{$_} } $sym->functions();

    # Transform all of the subroutine names
    ($sub, @subs) = _run_xformers($CONF{xform}, $sub, @subs);

    # Call the subroutine that will look for matches
    # The matcher returns a list of the _indexes_ that match
    my @match_ind = _run_matcher($CONF{match}, $sub, @subs);

    @subs = @subs[@match_ind];
    @orig = @orig[@match_ind];

    # If we've got more than one matched subroutine, then call the
    # chooser to pick one.
    # Call the matched subroutine using magic goto.
    # If no match was found, die recreating Perl's usual behaviour.

    die "REALLY Undefined subroutine $AUTOLOAD called at $c[1] line $c[2]\n"
      unless @match_ind;

    if (@match_ind == 1) {
      $sub = "${pkg}::" . $orig[0];
    } else {
      my $index = _run_chooser($CONF{choose}, @subs);
      $sub = "${pkg}::" . $orig[$index];
    }
    if ($CONF{suggest}) {
      croak "Cannot find subroutine $AUTOLOAD. Did you mean $sub?";
    } else {
      goto &$sub;
    }
  }
}

1;
__END__

=head1 CAVEAT

I can't stress too strongly that this will make your code completely
unmaintainable and you really shouldn't use this module unless you're
doing something very stupid.

=head1 ACKNOWLEDGEMENTS

This idea came to me whilst sitting in Mark-Jason Dominus' "Tricks of
the Wizards" tutorial. In order to protect his reputation, I should
probably point out that just as the idea was forming in my head, he
clearly said that this kind of thing was a very bad idea.

Leon Brocard is clearly as mad as me as he pointed out some important bugs
and helped massively with the 'fuzzy-configurability'.

Matt Freake helped by pointing out that Perl generally does what you
mean, not what you think it should do.

Robin Houston spotted some nasty problems and (more importantly) supplied
patches.

=head1 AUTHOR

Dave Cross <dave@dave.org.uk>

With lots of help from Leon Brocard <leon@astray.com>

=head1 LICENSE

Copyright (C) 2000-2008, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
