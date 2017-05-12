package Template::Plugin::Text::Filter::URI;

use warnings;
use strict;

use base 'Template::Plugin';
use Text::Filter::URI qw( filter_uri );

=encoding utf8

=head1 NAME

Template::Plugin::Text::Filter::URI - Filter a string to meet URI requirements

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

  [% USE Text::Filter::URI %]
  <a href="/blog/[% "a string with föreign chäräcters" | filter_uri %]">Link</a>

  # Output

  <a href="/blog/a-string-with-foreign-characters">Link</a>

This filter can be useful if you have a string which should be included in an url but contains illegal characters. 

See L<Text::Filter::URI> for more information on this process.

=cut

sub new {
  my ($self, $context) = @_;
  $context->define_filter('filter_uri', \&filter_uri, '');
  return $self;
}


=head1 AUTHOR

Moritz Onken, C<< <onken at houseofdesign.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-text-filter-uri at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Text-Filter-URI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Text::Filter::URI

=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Template::Plugin::Text::Filter::URI
