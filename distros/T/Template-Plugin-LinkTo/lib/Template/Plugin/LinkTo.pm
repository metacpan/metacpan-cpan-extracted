package Template::Plugin::LinkTo;
use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = '0.093';
my @HTML_OPTIONS = qw/href target confirm title img class rel/;

my %escaped = ( '&' => 'amp', '<' => 'lt', '>' => 'gt', '"' => 'quot' );
sub escape {
    my $str = shift or return '';
    $str =~ s{([&<>"])(?!amp;)}{'&' . $escaped{$1} . ';'}msxgeo;
    $str;
}

sub link_to {
    my ($self, $text, $opt) = @_;

    $text = $opt->{img} ? qq{<img src="$opt->{img}" />} : escape $text; #"
    my $result = $text;

    if (my $href = escape $opt->{href}) {
        my $target  = ($opt->{target} = escape $opt->{target})
                      ? qq/target="$opt->{target}"/
                      : '';
        my $confirm = ($opt->{confirm} = escape $opt->{confirm})
                      ? qq/onclick="return confirm('$opt->{confirm}');"/
                      : '';
        my $title   = ($opt->{title} = escape $opt->{title})
                      ? qq/title="$opt->{title}"/
                      : '';
        my $class   = ($opt->{class} = escape $opt->{class})
                      ? qq/class="$opt->{class}"/
                      : '';
        my $rel     = ($opt->{rel} = escape $opt->{rel})
                      ? qq/rel="$opt->{rel}"/
                      : '';

        for my $key (@HTML_OPTIONS) {
            delete $opt->{$key};
        }

        my $params;
        for my $key (sort keys %$opt) {
            $params .= qq/&$key=$opt->{$key}/;
        }
        if ($params) {
            $params = escape $params;
            $href .= $params;
            $href  =~ s/&amp;/?/
                if $href !~ m/\?/;
        }

        $result = qq{<a href="$href" $target $confirm $title $class $rel>$text</a>};
        $result =~ s/\s{2,}/ /g;
        $result =~ s/\s>/>/;
    }

    return $result;
}

1;

__END__
=head1 NAME

Template::Plugin::LinkTo - like link_to in Ruby on Rails

=head1 SYNOPSIS

Input:

  [% USE LinkTo -%]
  [% args = {
      href => '/link/to',
  } -%]
  [% LinkTo.link_to('link_text', args) %]

Output:

  <a href="/link/to">link_text</a>

Input:

  [% USE LinkTo -%]
  [% args = {
      href => '/link/to',
      hoge => 'huga',
      foo  => 'bar',
  } -%]
  [% LinkTo.link_to('link_text', args) %]

Output:

  <a href="/link/to?foo=bar&hoge=huga">link_text</a>

Input:

  [% USE LinkTo -%]
  [% args = {
      href   => '/link/to',
      hoge   => 'huga',
      target => '_blank',
  } -%]
  [% LinkTo.link_to('link_text', args) %]

Output:

  <a href="/link/to?hoge=huga" target="_blank">link_text</a>

Input:

  [% USE LinkTo -%]
  [% args = {
      href    => '/link/to',
      hoge    => 'huga',
      target  => '_blank',
      confirm => 'really ?',
  } -%]
  [% LinkTo.link_to('link_<br />a&b<br />"text"', args) %]

Output:

  <a href="/link/to?hoge=huga" target="_blank" onclick="return confirm('really ?');">link_&lt;br /&gt;a&amp;b&lt;br /&gt;&quot;text&quot;</a>

Input:

  [% USE LinkTo -%]
  [% args = {
  } -%]
  [% LinkTo.link_to('link_text', args) %]

Output:

  link_text


=head2 Sample with DBIx::Class::ResultSet

  [% USE LinkTo -%]
  [%- WHILE (u = users.next) -%]
  [% args = {
      href => "user/${u.id}",
      hoge => 'huga',
      foo  => 'bar',
  } -%]
  [% LinkTo.link_to(u.nickname, args) %]
  [%- END %]
 

=head1 DESCRIPTION

Template::Plugin::LinkTo is like link_to in Ruby on Rails, but NOT same at all.

=head1 SEE ALSO

L<Template>, L<Template::Plugin>

=head1 AUTHOR

Tomoya Hirano, E<lt>hirafoo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify

=cut
