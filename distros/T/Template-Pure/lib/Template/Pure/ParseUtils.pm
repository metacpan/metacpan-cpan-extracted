package Template::Pure::ParseUtils;
 
use strict;
use warnings;
use Scalar::Util ();

sub parse_processing_instruction {
  my ($pi) = @_;
  my ($target, $body) = ($pi =~m/^\s*([^\s]+)(.+)$/s);
  my %attrs = map {
    my ($key, $val) = split '=', $_;
    $key=~s/^\s+//g;
    if($val=~s/^\\//) {
      $val=~s/^['"]|['"]$//g; 
      my $val2 = \$val;
      $key, $val2;
    } else {
      $val=~s/^['"]|['"]$//g;
      $key, $val;
    }
  } grep { $_ } 
    split(/['"]\s+/, $body);
  return $target => %attrs;
}

sub parse_itr_spec {
  my ($spec) = @_;
  my ($key, $data_spec) = split('<-', $spec);
  return $key => +{ parse_data_spec($data_spec) };
}

{
  package Template::Pure::Literal;
  use overload
    '""' => sub { my $self = shift; return ${$self} };  
}

sub parse_data_template {
  my ($spec) = @_;
  $spec=~s/\r|\n//gs; # cleanup newlines.

  my $opentag = qr/=\{/;
  my $closetag = qr/}/;
  my $placeholder = qr{(
    (?:
      $opentag ( 
        (?:
          (?> [^={}]+ )
          |
          (?2)
        )*
      ) $closetag
    )
  )}x;

  my @parts;

  # TODO Regexp hack info.  Ok so maybe my regexp Foo is not as good as it
  # could be... The problem I have is that ( [^={]+ ) capture = and { not both
  # grouped together.  I can't seem to get it working right with things like
  # (?!\=\{)+ that just never seems to pass tests.  Since '=' is very common in
  # HTML tags (like for setting attributes) matching on = is probably not my best
  # idea.  For now there's a hack here to change m/=./ into !\1! and then I revert
  # it.  That obviously sucks and wastes performance as well.  I'm leaving it like
  # this for now but someone with awesome regexp foo I hope can help me out :)

  $spec=~s/\=([^{])/\!$1\!/g; #TODO Hack step1

  while($spec =~/( [^={]+ ) | $placeholder /gx) {
    my $part = $1||$2;

    $part=~s/\!(.)+\!/\=$1/g; #TODO Hack step2

    if(my ($is_data_spec) = ($part=~/^$opentag(.+?)$closetag$/)) {
      push @parts, +{ parse_data_spec($is_data_spec) };
    } else {
      push @parts, bless \$part, 'Template::Pure::Literal';
    }
  }
  return @parts;
}

sub parse_data_spec {
  my $spec = shift;

  # Is this a literal?
  if(my ($value) = ($spec =~m/^[\'\"](.+)[\'\"]$/)) {
    return (
      literal => $value,
      absolute => '',
      path => [],
      filters => [],
    );
  }

  $spec=~s/\r|\n//gs; # cleanup newlines.
  my $absolute = ($spec=~s[^\/][]);

  my @parts;
  push @parts, $1 while $spec =~ /
  ((?:
    [^()\|]+ |
    ( \(
      (?: [^()]+ | (?2) )*
    \) )
  )*)
  (?: \|\s* | $)
  /xg;

  my ($path_proto, @filters_proto) = 
    grep { length($_) > 0 } 
      map { $_=~s/^\s+|\s+$//g; $_ } @parts;

  #Special case: If you have a part that is " |filter" we need to
  #munge a bit.
  if($parts[0] eq '') {
    push @filters_proto, $path_proto;
    $path_proto = '';
  }

  my @path_proto = split(/\.|\//, $path_proto);

  my @path = map {
    # Not ideal regexp here but safe enough I think since ':' is never in a method...
    # Just would croak on a hash key that is meant to mean this.  I'll doc that as
    # 'don't do that...
    my $maybe = ($_=~s/(maybe:)//);
    my $optional = ($_=~s/(optional:)//);
    +{ key => $_, maybe => $maybe, optional => $optional };
  } @path_proto;

  my @filters = map {
    my ($filter, $arg_proto) = ($_=~m/^(.*?)(?:\(\s*(.+?)?\s*\))?$/); # Borrowed from Catalyst::Controller
    my @arg_parts;

    if($arg_proto) {
      push @arg_parts, $1 while $arg_proto =~ /
      ((?:
        [^(),]+ |
        ( \(
          (?: [^()]+ | (?2) )*
        \) )
      )*)
      (?: ,\s* | $)
      /xg;
    }

    my @args = map {
      my ($data_spec) = ($_=~/^\=\{(.+?)\}$/);
      $data_spec ? +{ parse_data_spec($data_spec) } : eval $_;
    } grep { 
        length($_) > 0;
      } @arg_parts;

    +[ $filter, @args ];
  } @filters_proto;

  return (
    absolute => $absolute,
    path => \@path,
    filters => \@filters,
  );
}

sub parse_match_spec {
  my $spec = shift;

  # Look for all the possibilities, try to leave $spec in a useful state
  my $maybe_target_node = ($spec=~s/^\^//);
  my $maybe_filter = ($spec=~s/\|$//);
  my $maybe_prepend = ($spec=~s/^(\+)//);
  my $maybe_append = ($spec=~s/(\+)$//);
  my $maybe_absolute = ($spec=~s[^\/][]);

  my ($css, $maybe_attr) = split('@', $spec);
  $css = '.' if $maybe_attr && !$css; # $css unlikely to be 0

  # All the error conditions I can think of.
  die "You need a CSS style match: '$spec'"
    unless $css;

  die "Can't add a filter when appending or prepending: '$spec'"
    if $maybe_filter && ($maybe_append || $maybe_prepend);

  die "Can't set a target when filtering: '$spec'"
    if $maybe_filter && ($maybe_target_node || $maybe_attr);

  die "Can't set a target attribute and target node: '$spec'"
    if $maybe_target_node && $maybe_attr;

  my $target = 'content';
  if($maybe_target_node) {
    $target = 'node';
  } elsif($maybe_attr) {
    $target = \$maybe_attr;
  }

  my $mode = 'replace';
  if($maybe_append) {
    $mode = 'append';
  } elsif($maybe_prepend) {
    $mode = 'prepend';
  } elsif($maybe_filter) {
    $mode = 'filter';
    $target = '';
  }

  return (
    absolute => $maybe_absolute,
    css => $css,
    target => $target,
    mode => $mode,
  );
}

1;

=head1 NAME

Template::Pure::ParseUtils - Utility Functions

=head1 SYNOPSIS

    For internal use

=head1 DESCRIPTION

Contains utility functions for L<Template::Pure>

=head1 FUNCTIONS

This package contains the following functions:

=head2 parse_processing_instruction ($pi)

Given a processing instruction, parse it into a $target and %attrs such that:

    <?pure-include id='ddd'
      pure:mode='append|prepend|replace'
      pure:target='node|content'
      pure:src='include' ?>

Is parsed into:

    "pure-include" => {
      id => "ddd",
      "pure:mode" => "append|prepend|replace",
      "pure:src" => "include",
      "pure:target" => "node|content"
    }

and returned.

=head2 parse_itr_spec ($spec)

Used to parse a string when we are specifying an iterator. For example

    "user<-users"

or:

  "friend<-user.friends"

Returns a hashref when the key is the new data label and the value is a reference to the
indicated path from the current data context.

    {
      user => {
        absolute => '';
        filters => [],
        path => [
          key => 'users',
          maybe => '',
          optional => ''
        ],
      },
    }

B<NOTE> you cannot use a filter on an iterator specification.

B<NOTE> Indicated data context path must be something that can be coerced into an iterator
(an arrayref, a hashref, or an Object that provides the iterator interface).

=head2 parse_data_template ($spec)

Used to parse a string that is the target action of a match, when the string contains
template placeholders, for example:

    "Hello ={meta.first_name} ={meta.last_name}!"

Which is intended to be parsed as containing a string with two placeholders, each pointing
to a different path on the current data context.

When parsed returns an array, where each element is either a string (for a literal string
value) or a hash reference (indicates a patch to a value on the current data context).

For example the shown string would parse in this way:

    (
      'Hello ',
      {
        absolute => '',
        filters => [],
        path => [ 
          { key => 'meta', optional => undef, maybe => undef },
          { key => 'first_name', optional => undef, maybe => undef },
      },
      ' ',
      {
        absolute => '',
        filters => [],
        path => [ 
          { key => 'meta', optional => undef, maybe => undef },
          { key => 'first_name', optional => undef, maybe => undef },
      },
      '!',
    );

Information inside the placeholder may contain filters and prefixes and other markers:

    "Year of Birth: ={/maybe:meta.optional:dob | strftime(%Y)}"

Would parse as:

    (
      'Year of Birth: ',
      {
        absolute => '1',
        filters => [
          ['strftime', '%Y'],
        ],
        path => [ 
          { key => 'meta', optional => undef, maybe => 1 },
          { key => 'dob', optional => 1, maybe => undef },
      },
    );


=head2 parse_data_spec ($spec)

When the action target is a string we need to inspect it to figure out what do do with it.
Returns a hash with keys as follows:

=over 4

=item absolute

Boolean.  Defaults to False.  When true this means the described path should be absolute
from the top of the data context.  Otherwise the described path is relative to the current
point selected in the data context.


=item path

    Example:

    path => [
      {
        key => 'meta',
        optional => 0,
        maybe => 0
      },
      {
        key => 'title',
        optional => 0,
        maybe => 0
      }
    ];

An array hashrefs that indicate path parts from the current data context to the value we
wish to use.  Each hashref contains three keys:

=over 4

=item key

The name that is a 'key' point on the path.  Likely to be a key in a hash or a method on an
object.

=item optional

Boolean.  Defaults to false.  Generally if the key does not match a real path on the current
data context, this should return an error.  If this value is false, that means instead of
throwing an error we return an 'undef'.

Value is derived from the prefix 'optional:'. Presence of this prefix sets this to true.

B<NOTE> since 'optional:' has special meaning here, this means that if your data context is
a hash, you should not have any keys that match 'optional:' for your own purposes...  If you
really run into this you'll have to write an anonymous subroutine type action.

=item maybe

Boolean.  Defaults to false.  Generally if you have several path parts and a midpoint part 
returns undefined, that mean we throw an exception on later parts (can't find a next path on
an undefined value).  In some cases (like when you are chaining resultset methods in L<DBIx::Class>)
we might not prefer tothrow an error but just return 'undef'.  When a path is 'maybe' we
wrap in in an object such that the next path is always found (but returns undef).

Value is derived from the prefix 'maybe:'.  Presence of this prefix sets this to true.

B<NOTE> since 'maybe:' has special meaning here, this means that if your data context is
a hash, you should not have any keys that match 'maybe:' for your own purposes...  If you
really run into this you'll have to write an anonymous subroutine type action.

=back

=item filters

An Arrayref of Arrayrefs which are any filters added to the value and their arguments.

    Example:

    filters => [
      [ 'repeat', '3'],
      [ 'escape_html' ],
    ];

In some cases the arguments for a filter might itself point to a resolved data spec (which itself
could include filters...  In this case the argument value will be a hashref that is itself the 
result of a call to L</parse_data_spec>, example:

    (
      path => [
        {
          key => 'meta', maybe => 0, optional => 0,
        },
        {
          key => 'title', maybe => 0, optional => 0,
        },
      ],
      filters => [
        ['title_case'],
        ['truncate',
          {
            path => [
              { key => 'settings', maybe => 0, optional => 0 },
              { key => 'title_length', maybe => 0, optional => 0 },
            ],
            filters => [],
          },
          '...',
        ],
      ],
    );

You'd have a string to parse like "meta.title | title_case | truncate(={settings.title_length},'...')"
which has a filter 'truncate' that has two args, the first being 'whatever the value is at
'settings.title_length'' and the second is a literal '...'.

You could go wild here with nested values and filters but I recommend if you have such complex
needs it would be better to do it in Perl with an anonymous subroutine rather than over cleverness
in the string based DSL, which will never be as good as Perl itself.  Use it for straight and simple
things and for when you want to let non Perl programmers work with the directives.

B<NOTE> we run C<eval> on each argument to convert it to a Perl data value, so you could in
theory do fancy stuff here like "filter(1+2+3)" and get an arg of '3'.  I highly recommend constraint
in this.  Since its C<eval>'d you should be certain these values are properly cleaned and untainted.
For example beware of something like "filter($a)", where $a comes from uncontrolled source such as the
input of a HTML Form post, or from external sources like a database or file.  This could be considered
a possible injection attack location.  Because of this we might someday switch this to a non eval
parser such as L<Data::Pond> or similar, and if you did crazy expression stuff that don't work with
a more restrictive and safe expression parser, its possible your code will break.  Buyer beware.

B<NOTE> The values for the boolean keys 'maybe' and 'optional' are only specificed to return a
Perl value to be evaluated as a boolean.  We don't specify the exact value.  For example, under Perl
both 0 and undef are considered false in boolean context.

=back

=head2 parse_match_spec ($spec)

Given a directive match specification (such as '#head', 'title', 'p.links@href', ...) parse
it into a hash that defines how the match is to be performed.  Returns a hash with keys are
follows.

=over 4

=item css

This is the actual CSS match component ('p', '#id', '.class') or the special match indicator of
'.' for the current node.

=item target

This is the indicator of the replacement target for the match.  Can be: 'node', 'content', \'$attribute':

=over 4

=item content

    Example Match Specifiction: 'p.headline', 'title', '#id'

This is the default value for target.  Indicates we will update the matched nodes' content.  For example the
content of node '<p>content</p>' is 'content'.  No special symbols are needed to indicate this target type.

=item \$attribute

    Example Match Specifiction: 'a#homepage@href', 'ul.links@class'

When the value of 'target' is a scalar reference, this indicates the update type to be an attribute on the current
matched node.  The dereferenced scalar is the name of the attribute.  If the attribute does not exist in the current
node this does not raise an exception, but rather we automatically add it.

It is an error to indicate both node and attribute targets.

B<NOTE> Should a match specification consist only of an attribute, we presume a 'css' value of '.'

=item node

    Example Match Specifiction: '^p.headline', '^#id'

Indicated a target of 'node', which means we will replace the entire matched node.  Indicated by a '^' appearing
as the first character of the match specification.

It is an error to indicate both node and attribute targets.

=back

=item mode

Defines the relationship, if any, between a new value from the data context and any existing information
in the template and the match location.  One of 'append', 'prepend', or 'replace', with 'replace' being the default.

=over 4

=item replace

    Example Match Specifiction: 'title', '#id', 'p.content@class'

The default behavior.  Needs no special indicators in the match specification.  Means the new value
completely replaces the match target.

=item append

    Example Match Specifiction: 'title+', '#id+', 'p.content@class+'

Match specifications that end with '+' will append to the indicated match (that is we place the
new value after the old value, preserving th old value.

It is an error to try to set both append and prepend mode on the same target.  It is also an error
to use append and prepend along with a filter indicator (see below).

When appending to a target of attribute where the attribute is 'class', we automatically add a ' ' (space)
between the appending value and any existing value.  This is a special case since generally a space
is required between classes in order for them to work as expected.

=item prepend

    Example Match Specifiction: '+body', '+p.content@class'

Match specifications that begin with a '+' (or '^+') indicate we expect to add the data context to the
front of the existing value, preserving the existing value.

It is an error to try to set both append and prepend mode on the same target.  It is also an error
to use append and prepend along with a filter indicator (see below).

When prepending to a target of attribute where the attribute is 'class', we automatically add a ' ' (space)
between the appending value and any existing value.  This is a special case since generally a space
is required between classes in order for them to work as expected.

=item filter

    Example Match Specification: 'html|', 'body|'

Means that we expect to run a filter callback on the matched node.  Useful when you want to make global
changes across the entire template.  Indicated by a '|' or pipe symbol.  Cannot be used with append,
prepend or any special target indicators (attributes or node).

We expect the action the be an anonymous subroutine.

=back

=back

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>

But lots of this code was copied from L<Template::Filters> and other prior art on CPAN.  Thanks!
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Pure> for copyright and license information.

=cut 
