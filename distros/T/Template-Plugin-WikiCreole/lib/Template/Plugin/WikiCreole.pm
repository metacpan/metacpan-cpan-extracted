package Template::Plugin::WikiCreole;
use strict;
use warnings;

use base 'Template::Plugin::Filter';
use Text::WikiCreole;

our $VERSION = '0.01';

=head1 NAME

Template::Plugin::WikiCreole - TT wrapper for L<Text::WikiCreole>

=head1 SYNOPSIS

  [% USE WikiCreole %]
  [% FILTER $WikiCreole %]
  ...
  [% END %]

=head1 DESCRIPTION

This is a plugin used for Wiki Creole rendering inside Template Toolkit.

  [% USE WikiCreole %]

At this time none of the methods for customising L<Text::WikiCreole> are
not directly available via L<Template::Plugin::WikiCreole>. However 
Text:WikiCreole is an exporter and its methods act
globaly.  So you can use this class in your software and call its methods to
change the behavour in the template.

I have found this most useful when teamed with ttree.  It gives me a way to 
maintain the static part of a website in WikiCreole. I find it quicker to write 
and maintain most pages in WikiCreole. This ensures I end up with a constant 
style. (I have never liked HTML editors.)

For example the following ttree configuration:

  src = src
  dest = ~/site-prefview
  lib = template/
  template_process = layout.html
  depend = *=navigation.wiki,footer.wiki
  suffix = wiki=html
  ignore = ^navigation.wiki$
  ignore = ^footer.wiki$
  ignore = \b(CVS|RCS)\b
  ignore = ^\.
  ignore = ~$
  ignore = ^#
  ignore = \.tiff$
  copy = \.png$ 
  copy = \.gif$ 
  copy = \.css$ 
  ...

and the following template:

  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
  [% USE WikiCreole -%]
  <html>
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <meta name="language" content="en" />
      <link rel="stylesheet" href="css/main.css"/>
      <title>Change of Plan - [% template.name %]</title>
    </head>
    <body>
      <div class="page">
        <div class="header">
          [% INCLUDE header.wiki | $WikiCreole %]
        </div>
        <div class="body">
          <div class="navigation">
            [% INCLUDE navigation.wiki | $WikiCreole %]
          </div>
          <div class="main">
            [% PROCESS $template | $WikiCreole %]
          </div>
        </div>
        <div class="footer">
          [% INCLUDE footer.wiki | $WikiCreole %]
        </div>
      </div>
    </body>
  </html>

will create a webpage for every wiki template in the src directory with same 
layout and style (look and feel). The variation between pages is the content, 
the with the full expressive power of WikiCreole. The css file provides 
considerable flexability in the look.

This source itself is a blatant copy of L<Template::Plugin::WikiFormat> by
Ivor Williams

=head1 METHODS

=head2 filter

Accepts the wiki text to be rendered, and context.  See
L<Template::Plugin::Filter>.

=cut

sub filter {
    my ( $self, $text ) = @_;

    my $conf = $self->{_CONFIG};
    $conf ||= {};
    my %tags = %$conf;
    my %opts;
    my %default = ( # Consider and ther how best to do them
    );
    for ( keys %default ) {
        $opts{$_} = $tags{$_} || $default{$_};
        delete $tags{$_};
    }

    my $output = creole_parse( $text, \%tags );

    return $output;
}

=head1 BUGS

Please use http://rt.cpan.org for reporting any bugs.

=head1 TODO

Create arguments to pass 

=head1 AUTHOR

 Martin Ellis

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Text::WikiCreole>
L<Template::Plugin::WikiFormat>
L<Template::Plugin::Filter>

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

