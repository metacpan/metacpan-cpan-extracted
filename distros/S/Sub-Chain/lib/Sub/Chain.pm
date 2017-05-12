# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Sub-Chain
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Sub::Chain;
BEGIN {
  $Sub::Chain::VERSION = '0.012';
}
BEGIN {
  $Sub::Chain::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Chain subs together and call in succession

use Carp qw(croak carp);

# enable object to be called like a coderef
use overload
  '&{}' => \&coderef,
  fallback => 1;

use Object::Enum 0.072 ();

our %Enums = (
  result => Object::Enum->new({unset => 0, default => 'replace',
    values => [qw(replace discard)]}),
  on_undef => Object::Enum->new({unset => 0, default => 'proceed',
    values => [qw(skip blank proceed)]}),
);


sub new {
  my $class = shift;
  my %opts = ref $_[0] ? %{$_[0]} : @_;

  my $self = {
    chain => []
  };
  bless $self, $class;

  $self->_copy_enums(\%opts);

  return $self;
}


sub append {
  my ($self, $sub, $args, $opts) = @_;

  # TODO: normalize_spec (better than this):
  $args ||= [];
  $opts ||= {};
  $self->_copy_enums($opts, $opts);

  CORE::push(@{ $self->{chain} }, [$sub, $args, $opts]);
  # allow calls to be chained
  return $self;
}


sub call {
  my ($self, @args) = @_;
  # cache function call
  my $wantarray = wantarray;

  my @chain = @{ $self->{chain} };
  carp("No subs appended to the chain")
    unless @chain;

  foreach my $tr ( @chain ){
    my ($sub, $extra, $opts) = @$tr;
    my @all = (@args, @$extra);
    my @result;

    # TODO: instead of duplicating enum objects do %opts = (%$self, %$opts)
    if( @args && $opts->{on_undef} && !defined($args[0]) ){
      next if $opts->{on_undef}->is_skip;
      $args[0] = ''
        if $opts->{on_undef}->is_blank;
    }

    # call sub with same context as this
    if( !defined $wantarray ){
      $sub->(@all);
    }
    elsif( $wantarray ){
      @result    = $sub->(@all);
    }
    else {
      $result[0] = $sub->(@all);
    }
    @args = @result
      if $opts->{result}->is_replace;
  }

  # if 'result' isn't 'replace' what would be a good return value?
  # would they expect one?

  # return value appropriate for context
  if( !defined $wantarray ){
    return;
  }
  elsif( $wantarray ){
    return @args;
  }
  else {
    return $args[0];
  }
}


sub coderef {
  my ($self) = @_;
  return sub { $self->call(@_); }
}

sub _copy_enums {
  my ($self, $from, $to) = @_;
  $to ||= $self;
  while( my ($name, $enum) = each %Enums ){
    $to->{$name} = ($self->{$name} || $enum)->clone(
      # use the string passed in
      exists $from->{$name} ? $from->{$name} :
        # clone from the default value saved on the instance
        $self->{$name} ? $self->{$name}->value : ()
    );
  };
}

1;


# TODO: link to questions on perlmonks and stackoverflow?


__END__
=pod

=for :stopwords Randy Stauner runtime distros TODO cpan testmatrix url annocpan anno
bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 NAME

Sub::Chain - Chain subs together and call in succession

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  my $chain = Sub::Chain->new();

  $chain->append(\&wash, ['cold']);
  $chain->append(\&dry,  [{tumble => 'low'}]);
  $chain->append(\&fold);

  my @clean_laundry = $chain->call(@clothes);

  # if only it were that easy

=head1 DESCRIPTION

This module aims to provide a simple interface for
chaining multiple subs (coderefs) together
and executing them one after the other in a single call.

It was specifically designed to be built dynamically
from a list of specifications provided at runtime
to filter data through the specified list of functions.

Also see L<Sub::Chain::Named>
which appends subs to the chain by name rather than coderef.

=head1 METHODS

=head2 new

  my $chain = Sub::Chain->new();
  my $chain = Sub::Chain->new( option => $value );
  my $chain = Sub::Chain->new({option => $value});

Constructor.
Takes a hash or hashref of arguments.

Accepts values as described in L<OPTIONS|/OPTIONS>
that will be used as defaults
for any sub that doesn't override them.

=head2 append

  $chain->append(\&sub, \@args, \%opts);

Append a sub to the chain.
The C<\@args> arrayref will be flattened and passed to the C<\&sub>
after any arguments to L</call>.

  sub sum { my $s = 0; $s += $_ for @_; $s; }

  $chain->append(\&sum, [3, 4]);

  $chain->call(1, 2);
  # returns 10
  # equivalent to: sum(1, 2, 3, 4)

If you don't want to send any additional arguments to the sub
an empty arrayref (C<[]>) can be used.

This method returns the object so that it can be chained for simplicity:

  $chain->append(\&sub, \@args)->append(\&sub2)->append(\&sub3, [], \%opts);

The C<\%opts> hashref can be any of the options described in L</OPTIONS>
to override the defaults on the object for this particular sub.

=head2 call

  $chain->call(@args);

Calls each method in the chain
with the supplied (and any predetermined) arguments
according to any predefined options.

=head2 coderef

  my $sub = $chain->coderef;
  $sub->(@args);

Wrap C<< $self->call >> in a closure.
This is used to overload the function dereference operator
so you can pretend the instance is a coderef: C<< $chain->(@args) >>

=for test_synopsis my @clothes;

=head1 OPTIONS

These options can define how a sub should be handled.
Specified in the options hashref for L</append>
they apply to that particular sub.
Specified in the constructor they can set the default
for how to handle any sub that doesn't override the option.

=over 4

=item *

C<result>

What to do with the result;
Valid values are:

=over 4

=item *

C<replace> - replace the argument list with the return value of each sub

=item *

C<discard> - discard the return value of each sub

=back

The arguments to L</call> are passed to each sub in the chain.
When C<replace> is specified the return value of one sub
is the argument list to the next.
This is useful, for instance, when chaining a number of
data cleaning or transformation functions together:

  sub add_uc { $_[0] . ' ' . uc $_[0]  }
  sub repeat { $_[0] x $_[1] }

  $chain->append(\&add_uc)->append(\&repeat, [2]);
  $chain->call('hi');

  # returns 'hi Hihi HI', similar to:

  my $s = 'hi';
  $s = add_uc($s);
  $s = repeat($s, 2);

When C<discard> is specified, the same arguments are sent to each sub.
This is useful when chaining subs that are called for their side effects
and you aren't interested in the return values.

  # assume database handle has RaiseError set
  $chain
    ->append(\&log)
    ->append(\&save_to_database)
    ->append(\&email_to_user);

  # call in void context because we don't care about the return value
  $chain->call($object);

The default is C<replace> since that (arguably) makes this module more useful.

=item *

C<on_undef>

What to do when a value is undefined;
Valid values are:

=over 4

=item *

C<proceed> - proceed as normal (as if it was defined)

=item *

C<skip> - skip (don't call) the sub

=item *

C<blank> - initialize the value to a blank string

=back

The default is C<proceed>.

=back

=head1 RATIONALE

This module started out as C<Data::Transform::Named>,
a named wrapper (like C<Sub::Chain::Named>) around
L<Data::Transform> (and specifically L<Data::Transform::Map>).

As the module was nearly finished I realized I was using very little
of L<Data::Transform> (and its documentation suggested that
I probably wouldn't want to use the only part that I I<was> using).
I also found that the output was not always what I expected.
I decided that it seemed reasonable according to the likely purpose
of L<Data::Transform>, and this module simply needed to be different.

So I attempted to think more abstractly
and realized that the essence of the module was not tied to
data transformation, but merely the succession of simple subroutine calls.

I then found and considered L<Sub::Pipeline>
but needed to be able to use the same
named subroutine with different arguments in a single chain,
so it seemed easier to me to stick with the code I had written
and just rename it and abstract it a bit further.

I also looked into L<Rule::Engine> which was beginning development
at the time I was searching.
However, like L<Data::Transform>, it seemed more complex than what I needed.
When I saw that L<Rule::Engine> was using [the very excellent] L<Moose>
I decided to pass since I was doing work on a number of very old machines
with old distros and old perls and constrained resources.
Again, it just seemed to be much more than what I was looking for.

=head1 TODO

=over 4

=item *

Write a lot more tests

=item *

Improve documentation

=back

=head1 SEE ALSO

=over 4

=item *

L<Sub::Chain::Named>

=item *

L<Sub::Pipeline>

=item *

L<Data::Transform>

=item *

L<Rule::Engine>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Sub::Chain

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Sub-Chain>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Chain>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Sub-Chain>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/Sub-Chain>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Sub-Chain>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Sub::Chain>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-sub-chain at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Chain>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<http://github.com/rwstauner/Sub-Chain>

  git clone http://github.com/rwstauner/Sub-Chain

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

