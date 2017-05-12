package Template::Pure::Filters;
 
use strict;
use warnings;
use Scalar::Util ();
use Data::Dumper ();
use URI::Escape ();
use Template::Pure::EncodedString;

sub all {
  return (
    format => \&format,
    strftime => \&strftime,
    dump => \&dump,
    uri_escape_utf8 => \&uri_escape_utf8,
    uri_escape => \&uri_escape,
    upper => \&upper,
    lower => \&lower,
    upper_first => \&upper_first,
    lower_first => \&lower_first,
    collapse => \&collapse,
    encoded_string => \&encoded_string,
    escape_html => \&escape_html,
    truncate => \&truncate,
    repeat => \&repeat,
    remove => \&remove,
    replace => \&replace,
    comma => \&comma,
    ltrim => \&ltrim,
    rtrim => \&rtrim,
    trim => \&trim,
    default => \&default,
    cond => \&cond,
  );
}

sub escape_html {
  my ($value) = @_;
  my %_escape_table = (
    '&' => '&amp;', 
    '>' => '&gt;', 
    '<' => '&lt;',
    q{"} => '&quot;',
    q{'} => '&#39;' );

  if(
    Scalar::Util::blessed($value) && ( 
      $value->isa('Template::Pure::EncodedString') ||
      $value->isa('Mojo::DOM58')
    )
  ) {
    return $value;
  } else {
    $value =~ s/([&><"'])/$_escape_table{$1}/ge unless 
      !defined($value) ||
        (Scalar::Util::blessed($value) && $value->isa('Template::Pure::UndefObject'));
    return $value;
  }
}

sub format {
  my ($template, $data, $format) = @_;
  return sprintf($format, $data);
}

sub strftime {
  my ($template, $date_obj, $format) = @_;
  die "Must be an object that does 'strftime'"
    unless Scalar::Util::blessed($date_obj) && $date_obj->can('strftime');
  return $date_obj->strftime($format);
}

sub dump {
  my ($template, $value) = @_;
  warn Data::Dumper::Dumper $value;
  return $value;
}

sub cond {
  my ($template, $check, $if_true, $if_false) = @_;
  return $check ? $if_true : $if_false;
}
sub uri_escape {
  my ($template, $data, $unsafe) = @_;
  if($unsafe) {
    return URI::Escape::uri_escape($data, $unsafe);
  } else {
    return URI::Escape::uri_escape($data);
  }
}

sub uri_escape_utf8 {
  my ($template, $data, $unsafe) = @_;
  if($unsafe) {
    return URI::Escape::uri_escape_utf8($data, $unsafe);
  } else {
    return URI::Escape::uri_escape_utf8($data);
  }
}

sub upper {
  my ($template, $data) = @_;
  return uc $data;
}

sub lower {
  my ($template, $data) = @_;
  return lc $data;
}

sub upper_first {
  my ($template, $data) = @_;
  return ucfirst $data;
}

sub lower_first {
  my ($template, $data) = @_;
  return lcfirst $data;
}

sub collapse {
  my ($template, $data) = @_;
  for ($data) {
    s/^\s+//;
    s/\s+$//;
    s/\s+/ /g;
  }
  return $data;
}

sub encoded_string {
  my ($template, $data) = @_;
  return Template::Pure::EncodedString->new($data);
}

sub truncate {
  my ($template, $data, $length, $affix) = @_;
  my $allowed_length = $length - length($affix||'');
  if(length $data > $allowed_length) {
    $data = substr($data, 0, $allowed_length) . ($affix||'');
  }
  return $data;
}

sub repeat {
  my ($template, $data, $times) = @_;
  return $data x $times;
}

sub remove {
  my ($template, $data, $match) = @_;
  $data =~ s/$match//g;
  return $data
}

sub replace {
  my ($template, $data, $match, $replace) = @_;
  $data =~ s/$match/$replace/g;
  return $data
}

sub default {
  my ($template, $data, $default) = @_;
  return defined($data) ? $data : $default;
}

sub ltrim {
  my ($template, $data) = @_;
  $data =~s/^\s+//;
  return $data;
}

sub rtrim {
  my ($template, $data) = @_;
  $data =~s/\s+$//;
  return $data;
}

sub trim {
  my ($template, $data) = @_;
  $data =~s/^\s+|\s+$//g;
  return $data;
}

sub comma {
  my ($template, $data) = @_;
  1 while $data =~ s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
  return $data;
}


1;

=head1 NAME

Template::Pure::Filters - Default Data Filters

=head1 SYNOPSIS

    my $html = qq[
      <html>
        <head>
          <title>Page Title</title>
        </head>
        <body>
        </body>
      </html>
    ];

    my $pure = Template::Pure->new(
      template=>$html,
      directives=> [
        'body' => 'content | repeat(3) | escape_html',
      ]
    );

    my $data = +{
      content => q[
        <p>Are you <b>doomed</b> to discover that you never recovered from the narcoleptic
        country in which you once <u>stood?</u> Where the fire's always burning, but
        there's <i>never enough wood</i></p>?
      ],
    };

    print $pure->render($data);

Returns:

    <html>
      <head>
        <title>Page Title</title>
      </head>
      <body>
        <p>Are you <b>doomed</b> to discover that you never recovered from the narcoleptic
        country in which you once <u>stood?</u> Where the fire's always burning, but
        there's <i>never enough wood</i></p>
        <p>Are you <b>doomed</b> to discover that you never recovered from the narcoleptic
        country in which you once <u>stood?</u> Where the fire's always burning, but
        there's <i>never enough wood</i></p>
        <p>Are you <b>doomed</b> to discover that you never recovered from the narcoleptic
        country in which you once <u>stood?</u> Where the fire's always burning, but
        there's <i>never enough wood</i></p>
      </body>
    </html>

(Note that the embedded HTML was not HTML encoded due to the use of the 'escape_html'
filter.)

=head1 DESCRIPTION

Container modules for all the filters that are bundled with L<Template::Pure>.  Please
see L<Template::Pure/"Filtering your data"> for usage.  A lot of this is copied from
L<Template::Filters> and other filters from template languages like L<Xslate>.

Filters are arrange in 'UNIX pipe' syntax, so the output of the first filter becomes the
input of the second and so forth.  It also means filter are order sensitive.  Some filters
like the 'escape_html' filter only make sense if they are the last in the pipe.

Some filters may take arguments, for example:

    directives=> [
      'body' => 'content | repeat(3)',
    ]

Generally these are literals which are parsed out via regular expressions and then we use C<eval>
to generate Perl values.  As a result you are strongly encouraged to properly untaint and secure
these arguments (for example don't pass them in from a HTML form POST...).

You may pass arguments to filters via the data context using placeholder notation.  Placeholder
notation may be freely mixed in with argument literals.

    directives=> [
      'body' => 'content | repeat(#{times_to_repeat})',
    ]

Filters may be added to your current L<Template::Pure> instance:

    my $pure = Template::Pure->new(
      filters => {
        my_custom_filter => sub {
          my ($template_pure, $data, @args) = @_;
          return $modified_data;
        },  
      }, ... );

Custom filters get the current L<Template::Pure> instance, the current data context and any
arguments; you are expected to return modified data.

=head1 FILTERS

This module defines the following subroutines that are used as filters for L<Template::Pure>:

=head2 format ($format)
 
The C<format> filter takes a format string as a parameter (as per C<sprintf()>) and formats the
data accordingly.

    my $pure = Template::Pure->new(
      template => '<p>Price: $<span>1.00</span></p>'
      directives => [
        'span' => 'price | format(%.2f)',
      ],
    );

    print $pure->render({
      price => '2.0000001'
    });

Output:
 
    <p>Price: $<span>2.00</span></p>

=head2 strftime ($format)

Given an object that does 'strftime' return a string formatted date / time;

    my $pure = Template::Pure->new(
      template => '<p>Year</p>'
      directives => [
        'p' => 'date | strftime(%Y)',
      ],
    );

    print $pure->render({
      date => DateTime->new(year=>2016, month=>12),
    });

Output:
 
    <p>2016</p>

=head2 dump

This filter doesn't actually change the data.  It just uses L<Data::Dumper> and sends
C<Dumper> output to STDOUT via C<warn>.  Can be useful during debugging when you can't
figure out what is amiss with your data.  After it dumps to STDOUT we just return the
value unaltered.

=head2 uri_escape

=head2 uri_escape_utf8

These filters are just wrappers around the same in L<URI::Escape>.

=head2 upper

=head2 lower

=head2 upper_first

=head2 lower_first

Does text case conversions using Perl built in functions C<uc>, C<lc>, C<ucfirst> and C<lcfirst>.

=head2 collapse

Collapse any whitespace sequences in the input text into a single space. Leading and trailing whitespace 
(which would be reduced to a single space) is removed, as per trim.

=head2 encoded_string

By default L<Template::Pure> escapes your values using a simple HTML escape function so that your
output is 'safe' from HTML injection attacks.  However there might be cases when you wish to all raw
HTML to be injected into your template, froom known, safe data.  In this case you can use this function
to mark your data as "don't encode".  We will assume you know what you are doing... 

=head2 escape_html

As mentioned in the previous filter documentation, we nearly always automatically escape your data values
when they get rendered into your template to produce a document.  However as also mentioned there are
a few case where we don't, since we think its the more common desired behavior, such as when you
are injecting a template object or you are setting the value from the contents of a different node inside
the same template.  In those cases, should HTML escaping be desired you can use this filter to make it so.

=head2 truncate ($length, $affix)

Truncates string data to $length (where $length is the total allowed number of characters).  In the case
when we need to truncate, add $affix to the end to indicate truncation.  For example you may set $affix
to '...' to indicate characters were removed.  There is no default $affix.

B<NOTE> Should you use an $affix we automatically increase the required truncation so that the new string
INCLUDING THE $affix fits into the required $length.

=head2 repeat ($times)

Repeat a value by $times.

=head2 remove ($match)

Searches the input text for any occurrences of the specified string and removes them. 
A Perl regular expression may be specified as the search string.

=head2 replace ($match, $replacement)

Like L</remove> but does a global search and replace instead of removing.  Can also use
a regular expression in the $match

=head2 default ($value)

Should $data be undefined, use $value instead.

=head2 rtrim

=head2 ltrim

=head2 trim

Removes all whitespace from either the right side, left side, or both sides of the data

=head2 comma

Given a data value which is a number, comma-fy it for readability (100000 = > 100,000).

=head2 cond

A filter that is like the conditional operator (?).  Takes two arguments and returns the
first one if the filtered value is true and the second one otherwise.

    my $pure = Template::Pure->new(
      template=>q[
        <input name='toggle' type='checkbox'>
      ],
      directives=> [
        'input[name="toggle"]@checked' => 'checkbox_is_set |cond("on", undef)',
      ],    
    );

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>

But lots of this code was copied from L<Template::Filters> and other prior art on CPAN.  Thanks!
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Pure> for copyright and license information.

=cut 

