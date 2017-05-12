package Template::Plugin::Filter::MinifyHTML;

our $VERSION = '0.02';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;
    $self->install_filter('minify_html');
    $self->{_cfg} = shift;
    return $self;
}

sub filter {
  my ($self, $text) = @_;

  for ($text) {
    s/^\s+//;     # Leading Whitespace
    s/\s+$//;     # Trailing Whitespace
    s/[ \r\n\t]+/ /g;    # More than one space
    s/>\s+</></g; # Fix > <

    s/\s*\/>/>/g # Remove trailing / on self-closing elements
      if ($self->{_cfg}->{html5});

    s/<!--[^[].*?[^]]-->//g # Remove HTML comments (leaving IE conditional comments alone (hopefully))
      if ($self->{_cfg}->{comments});
  }

  return $text;
}

1;

__END__
=pod
 
=head1 NAME
 
Template::Plugin::Filter::MinifyHTML - HTML minification filter for Template Toolkit
 
=head1 VERSION
 
version 0.01
 
=head1 SYNOPSIS
 
  [% USE Filter.MinifyHTML( comments => 1, html5 => 1 ) %]
 
  [% FILTER minify_html %]
  <html>...Your html content here...</html>
  [% END %]
 
=head1 DESCRIPTION
 
This is a Template Toolkit filter which uses a few quick and nasty regexes to minify HTML source code. It's built upon the idea/workings of the default 'collapse' filter, but adds a little spice of its own into the mix, removing HTML comments and a few other bits and pieces.

=head1 USAGE

Be sure to [% USE Filter.MinifyHTML %] in your template, then you're able to wrap [% FILTER minify_html %][% END %] around blocks that you would like to minify.

Filter.MinyfyHTML can currently take two arguments - comments and html5.
       
=head2 COMMENTS

If comments is set to a truesy value it will remove any HTML comments it finds (<!-- ... -->). It shouldn't affect any conditional comments in your markup (ie. <!--[if lt IE 9]><link href="/static/css/custom-ie.css" rel="stylesheet"><![endif]-->).

=head2 HTML5

If html5 is truesy, then it will remove the trailing slash on self-closing elements (<br />, <input />, etc).


=head1 BUYER BEWARE

This filter does not check for or acknowledge the existence or importance of tags such as <pre> or <textarea>. As such, any whitespace within these tags *WILL* be royally messed up by this module in its current state.

 
=for Pod::Coverage init
filter
 
=head1 SEE ALSO
 
L<Template::Filters>, L<Template::Plugin::Filter>, L<Template>
 
=head1 AUTHOR
 
Jarrod Linahan <jarrod@texh.net>
 
=head1 COPYRIGHT AND LICENSE
 
Template::Plugin::Filter::MinifyHTML is copyright (c) 2013 by Jarrod Linahan.
 
This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.
 
=cut
