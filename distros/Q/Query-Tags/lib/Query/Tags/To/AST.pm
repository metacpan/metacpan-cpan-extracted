=encoding utf8

=head1 NAME

Query::Tags::To::AST - Build AST from Query

=cut

use v5.16;
use strict;
use warnings;

=head1 DESCRIPTION

The Query::Tags::To::AST package implements a L<Pegex::Receiver> based
on L<Pegex::Tree>. It is invoked from the Pegex parser engine to build
the syntax tree contained in a L<Query::Tags> object. What follows is
a list of all node types which appear in this syntax tree.

=cut

=head2 Query::Tags::To::AST::Query

This is the root object and represents the entire query.
Each assertion in the query is a pair object.

=head3 new

    my $query = Query::Tags::To::AST::Query->new(@pairs);

Create a new query from a list of assertions.

=head3 pairs

    my @pairs = $query->pairs;

Return the list of assertions.

=head3 test

    $query->test($x, \%opts) ? 'PASS' : 'FAIL'

Check if C<$x> passes all assertions.

=cut

package Query::Tags::To::AST::Query {
    use List::SomeUtils qw(all);

    sub new {
        my $class = shift;
        bless [ @_ ], $class
    }

    sub pairs { @{+shift} }

    sub test {
        my ($self, $arg, $opts) = @_;
        all { $_->test($arg, $opts) } @$self
    }
}

=head2 Query::Tags::To::AST::Pair

A key-value pair represents the assertion that the key should
exist and the values should match.

=head3 new

    my $pair = Query::Tags::To::AST::Pair->new($key, $value);

Create a new pair object.

=head3 key

    my $key = $pair->key;

Return the key as a Perl string.

=head3 value

    my $value = $pair->value;

Return the value (another C<Query::Tags::To::AST::*> object).

=head3 test

    $pair->test($x, \%opts) ? 'PASS' : 'FAIL'

Check if C<$x> matches the pair. This means the following:
if C<$x> is a blessed object and it has a method named C<$key>,
then it is invoked and its return value tested against C<$value>.
Otherwise, if C<$x> is a hashref, the C<$key> is looked up
and its value is used. Otherwise the test fails.

If C<$key> is undefined, the C<default_key> is looked up in
the options hashref C<\%opts>. See L<Query::Tags/"test"> for
an explanation of its behavior. If both C<$key> and C<default_key>
are undefined, the match fails.

If C<$value> is C<undef>, then only existence of the method
or the hash key is required and its value is ignored. If instead
C<$value> is (not blessed and) equal to the string C<?>,
then the value behind C<$key> is checked for truthiness.

=cut

package Query::Tags::To::AST::Pair {
    use Scalar::Util qw(blessed reftype);

    sub new {
        my $class = shift;
        my ($key, $value) = @_;
        bless [ $key, $value ], $class
    }

    # When the value is undefined, this means that we check for existence
    # of the key, not for undefinedness of the value!
    sub key   { shift->[0] }
    sub value { shift->[1] }

    sub test {
        my ($self, $arg, $opts) = @_;
        my ($key, $value) = @$self;

        if (not defined $key) {
            $key = $opts->{default_key};
            return 0 if not defined $key;
            if (ref($key) and reftype($key) eq 'CODE') {
                return $key->($arg, $value, $opts);
            }
        }

        if (blessed($arg) and $arg->can($key)) {
            return 1 if not defined $value;
            my $v = $arg->$key;
            return 0 if not defined $v;
            return !!$v if not blessed($value) and $value eq '?';
            return $value->test($v);
        }
        elsif (reftype($arg) eq 'HASH') {
            return exists $arg->{$key} if not defined $value;
            my $v = $arg->{$key};
            return 0 if not defined $v;
            return !!$v if not blessed($value) and $value eq '?';
            return $value->test($v);
        }
        return 0;
    }
}

=head2 Query::Tags::To::AST::String

Represents a string. This object has the stringification
and string comparison operators overloaded.

=head3 new

    my $string = Query::Tags::To::AST::String->new($s);

Create a new string object from a Perl scalar string.

=head3 value

    my $s = $string->value;

Return the Perl scalar string.

=head3 test

    $string->test($x) ? 'PASS' : 'FAIL'

Check if C<< $x eq $s >>.

=cut

package Query::Tags::To::AST::String {
    use overload
        '""'  => \&to_string,
        'cmp' => \&_cmp;

    sub new {
        my $class = shift;
        my $string = shift;
        bless \$string, $class
    }

    sub value { "". ${+shift} }
    sub to_string { shift->value }

    sub _cmp {
        my ($self, $other, $swap) = @_;
        ($self, $other) = ($other, $self) if $swap;
        "$self" cmp "$other"
    }

    sub test {
        my ($self, $arg) = @_;
        $self eq $arg
    }
}

=head2 Query::Tags::To::AST::Regex

Represents a regex. This object stringifies to the regex pattern.

=head3 new

    my $regex = Query::Tags::To::AST::Regex->new($re);

Create a new regex object from a Perl regex.

=head3 value

    my $re = $regex->value;

Return the underlying Perl regex.

=head3 test

    $regex->test($x) ? 'PASS' : 'FAIL'

Check if C<< $x =~ m/$re/ >>.

=cut

package Query::Tags::To::AST::Regex {
    use overload '""'  => \&to_string;

    sub new {
        my $class = shift;
        my $regex = shift;
        bless [ $regex ], $class
    }

    sub value { shift->[0] }
    sub to_string { "". shift->value }

    sub test {
        my ($self, $arg) = @_;
        my $re = $self->[0];
        $arg =~ m/$re/
    }
}

=head2 Query::Tags::To::AST::Junction

Represents a junction, a superposition of multiple values which compares
to a single value using a given mode.

=head3 new

    my $j = Query::Tags::To::AST::Junction->new($negate, $type, @values);

Create a new junction of C<$type> (optionally negated if C<$negate>
is truthy) over the given C<@values>.

=head3 negated

    my $negated = $j->negated;

Whether the junction is negated.

=head3 type

    my $type = $j->type;

Return the junction type as a string C<&>, C<|> or C<!>.

=head3 values

    my @values = $j->values;

Return the values in the junction (as C<Query::Tags::To::AST::*> objects).

=head3 test

    $j->test($x) ? 'PASS' : 'FAIL'

Check if C<$x> matches the junction. The type C<&> implements an L<all|List::SomeUtils/"all">
junction, C<|> implements L<any|List::SomeUtils/"any"> and C<!> implements L<none|List::SomeUtils/"none">.
These modes govern how the results of testing C<$x> against the C<@values>
are interpreted. If the junction is negated, then the result will be inverted
after it was computed.

=cut

package Query::Tags::To::AST::Junction {
    use List::SomeUtils qw(any all none);

    sub new {
        my $class = shift;
        my ($negate, $type, @list) = @_;
        bless [ $negate, $type, [ @list ] ], $class
    }

    sub negated { !!shift->[0] }
    sub type    { shift->[1]    }
    sub values  { @{shift->[2]} }

    sub test {
        my ($self, $arg) = @_;
        my ($negate, $type, $list) = @$self;
        my $res = do {
            if ($type eq '&') {
                all { $_->test($arg) } @$list;
            }
            elsif ($type eq '|') {
                any { $_->test($arg) } @$list;
            }
            elsif ($type eq '!') {
                none { $_->test($arg) } @$list;
            }
            else {
                die "unknown junction type '$type'";
            }
        };
        $negate ? !$res : $res
    }
}

package Query::Tags::To::AST;

use Pegex::Base;
extends 'Pegex::Tree';

sub got_query {
    my ($items) = @{+pop};
    my @pairs;
    for my $item (@$items) {
        $item = Query::Tags::To::AST::Pair->new(undef, $item)
            unless $item->isa('Query::Tags::To::AST::Pair');
        push @pairs, $item;
    }
    Query::Tags::To::AST::Query->new(@pairs)
}

sub got_pair {
    my ($key, $value) = @{+pop};
    Query::Tags::To::AST::Pair->new($key => $value)
}

sub got_bareword {
    my $word = pop;
    Query::Tags::To::AST::String->new($word)
}

sub got_string {
    my $string = pop;
    Query::Tags::To::AST::String->new($string)
}

sub got_regex {
    my $regex = pop;
    Query::Tags::To::AST::Regex->new(qr/$regex/x)
}

sub got_junction {
    my ($negate, $type, $values) = @{+pop};
    Query::Tags::To::AST::Junction->new($negate, $type, @$values)
}

":wq"
