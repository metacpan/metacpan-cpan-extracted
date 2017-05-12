package Template::Plugin::Dump;

use strict;
use Data::Dump;
use Template::Plugin;
use base qw( Template::Plugin );
use vars qw( $VERSION );

$VERSION = '0.02';

sub dump {
  my $self = shift;
  my $content = Data::Dump::dump(@_);
  return $content;
}

sub dump_html {
  my $self = shift;
  my $content = Data::Dump::dump(@_);

  $content =~ s/&/&amp;/g;
  $content =~ s/</&lt;/g;
  $content =~ s/>/&gt;/g;
  $content =~ s/ /&nbsp;/g;
  $content =~ s/"/&quot;/g;
  $content =~ s/\n/<br>\n/g;

  return $content;
}

1;

__END__

=head1 NAME

Template::Plugin::Dump - alternative dumper plugin with Data::Dump

=head1 SYNOPSIS

    [% USE Dump %]
    [% Dump.dump( variable ) %]
    [% Dump.dump_html( variable ) %]

=head1 DESCRIPTION

This plugin is a simple alternative which uses Data::Dump instead of Data::Dumper. APIs are the same, except this plugin has no configuration options as Data::Dump has none of them.

=head1 METHODS

=head2 dump

Generates a raw text dump of the data structure(s).

=head2 dump_html

Generates a dump, but with the characters E<lt>, E<gt>, E<amp> converted to their equivalent HTML entities, and newlines converted to E<lt>brE<gt>. White spaces and double quotes will be converted to the equivalent HTML entities as well.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
