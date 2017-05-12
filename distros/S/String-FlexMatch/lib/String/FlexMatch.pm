use 5.008;
use strict;
use warnings;

package String::FlexMatch;
our $VERSION = '1.100820';
# ABSTRACT: Flexible ways to match a string
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new;

# Back in Test::More 0.45 the sane view was taken that if an object overrides
# stringification, it probably does so for a reason, and that stringification
# defines how the object wants to be compared. Newer versions of Test::More
# simply say that if you have a string and a reference, they can't possibly be
# the same, effectively overriding overload. This is completely fucked up, and
# we override it here again.
#
# You might say that's an evil hack and I might say I don't care. If you use
# String::FlexMatch you subscribe to my point of view.
#require Test::Builder;
#no warnings 'redefine';
#*Test::Builder::_unoverload = sub {};
use overload
  '""' => \&as_string,
  'eq' => \&is_eq,
  'ne' => \&is_ne,
  '==' => \&is_eq;
sub init { }    # so potential subclasses can override

sub string {
    my $self = shift;
    @_ ? $self->{string} = shift : $self->{string};
}

sub force_regex {
    return unless defined $_[1];
    ref $_[1] eq 'Regexp' ? $_[1] : qr/$_[1]/;
}

sub regex {
    my $self = shift;
    @_
      ? $self->{regex} = $self->force_regex(+shift)
      : $self->force_regex($self->{regex});
}

sub force_code {
    return unless defined $_[1];
    ref $_[1] eq 'CODE' ? $_[1] : eval $_[1];
}

sub code {
    my $self = shift;
    @_
      ? $self->{code} = $self->force_code(+shift)
      : $self->force_code($self->{code});
}
sub as_string { $_[0]->choice_attr }

sub is_eq {
    my ($lhs, $rhs) = @_;

    # only 'undef' matches 'undef'; if one side is undef and the other is not,
    # there's no match
    return !defined $rhs unless defined $lhs;
    return !defined $lhs unless defined $rhs;
    my $lhs_val =
      ref($lhs) && $lhs->isa('String::FlexMatch') ? $lhs->choice_attr : "$lhs";
    my $rhs_val =
      ref($rhs) && $rhs->isa('String::FlexMatch') ? $rhs->choice_attr : "$rhs";
    my $key = sprintf "%s_%s", map { ref || 'STRING' } $lhs_val, $rhs_val;
    our $match ||= {
        STRING_STRING => sub { $_[0] eq $_[1] },
        STRING_Regexp => sub { $_[0] =~ $_[1] },
        STRING_CODE   => sub { $_[1]->($_[0]) },
        Regexp_STRING => sub { $_[1] =~ $_[0] },
        Regexp_Regexp => sub { die "can't compare two regexes" },
        Regexp_CODE => sub { die "can't compare a regex to a string" },
        CODE_STRING => sub { $_[0]->($_[1]) },
        CODE_Regexp => sub { die "can't compare a coderef to a regex" },
        CODE_CODE   => sub { die "can't compare two coderefs" },
    };
    $match->{$key}->($lhs_val, $rhs_val);
}
sub is_ne { !is_eq(@_) }

sub choice_attr {
    my $self = shift;
        defined $self->string ? $self->string
      : defined $self->regex  ? $self->regex
      : defined $self->code   ? $self->code
      :                         undef;
}

# If this module is used with YAML::Active, we want it to dump as a
# String::Flex::NoOverload object. If this sub wasn't there, YAML would
# stringify the String::FlexMatch object, which would produce a normal string
# (cf. as_string() - something like '(?-xism:blah)'. However, we wouldn't be
# able to re-Load this dump via YAML::Active again, since the string, when
# loaded, would just stay a normal string and not turn into a
# String::FlexMatch object again.
#
# To remedy this, we provide this sub to tell YAML::Active how we want a
# String::FlexMatch object dumped: as a String::FlexMatch::NoOverload object,
# which can then be given to YAML to dump - it will produce something like
#
#   !perl/String::FlexMatch::NoOverload regex: ...
#
# The last piece of the puzzle is to make String::FlexMatch::NoOverload
# inherit from String::FlexMatch. That way, when re-Loading the above YAML,
# the expected behaviour of the flex string still works.
sub prepare_dump { @String::FlexMatch::NoOverload::ISA = () }
sub finish_dump  { @String::FlexMatch::NoOverload::ISA = 'String::FlexMatch' }

sub yaml_dump {
    my $self = shift;
    my $dump_self;
    %$dump_self = %$self;
    bless $dump_self, 'String::FlexMatch::NoOverload';
}
@String::FlexMatch::NoOverload::ISA = 'String::FlexMatch';
1;


__END__
=pod

=head1 NAME

String::FlexMatch - Flexible ways to match a string

=head1 VERSION

version 1.100820

=head1 SYNOPSIS

  use String::FlexMatch;

  my $s = String::FlexMatch->new(string => 'foobar');
  if ($s eq 'foobar') {
    # ...
  }

  $s = String::FlexMatch->new(regex => 'Error .* at line \d+');
  if ($s eq 'Error "foo" at line 58') {
    # ...
  }

  $s = String::FlexMatch->new(code => 'sub { length $_[0] < 10 }');
  # or:
  # my $s = String::FlexMatch->new(code => sub { length $_[0] < 10 });

  if ($s ne 'somelongstring') {
    # ...
  }

=head1 DESCRIPTION

Normally when trying to see whether two strings are equal, you use
the C<eq> operator. If you want to find out whether one string matches
another more flexibly, you'd use a regular expression. And sometimes
you have to call a subroutine with a string argument that will tell you
whether that argument is interesting, i.e. matches in a broader sense.

When running data-driven tests, you sometimes don't know beforehand which form
of matching (C<eq>, regex or code) you need. Take the following example:

  use Test::More;
  use String::FlexMatch;
  use YAML;

  sub frobnicate { $_[0] + $_[1] }

  my $tests = Load do { local $/; <DATA> };
  plan tests => scalar @$tests;

  for my $test (@$tests) {
    my $baz = frobnicate($test->{testarg}{foo}, $test->{testarg}{bar});
    is($baz, $test->{expect}{baz});
  }

  __DATA__
  -
    testarg:
      foo: 2
      bar: 3
    expect:
      baz: 5
  -
    testarg:
      foo: 21
      bar: 34
    expect:
      baz: !perl/String::FlexMatch
        regex: '\d+'

A setup like this was the reason for writing this class. If you find
any other uses for it, please let me know so this manpage can be expanded
with a few cookbook-style examples.

=head1 METHODS

=head2 new

    my $obj = String::FlexMatch->new;
    my $obj = String::FlexMatch->new(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=head2 as_string

FIXME

=head2 choice_attr

FIXME

=head2 code

FIXME

=head2 finish_dump

FIXME

=head2 force_code

FIXME

=head2 force_regex

FIXME

=head2 init

FIXME

=head2 is_eq

FIXME

=head2 is_ne

FIXME

=head2 prepare_dump

FIXME

=head2 regex

FIXME

=head2 string

FIXME

=head2 yaml_dump

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=String-FlexMatch>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/String-FlexMatch/>.

The development version lives at
L<http://github.com/hanekomu/String-FlexMatch/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

