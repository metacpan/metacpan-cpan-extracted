package Template::Plugin::ForumCode;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use base qw{ Template::Plugin };
use base qw{ Template::Plugin::HTML };

use version; our $VERSION = qv('0.0.5')->numify;

use base qw{HTML::ForumCode};

sub new {
    my ($class, $context, @args) = @_;

    # TODO - I'm sure this could be nicer
    my $new_obj = bless {}, $class;
    $new_obj->init;

    return $new_obj;
}

1;
__END__

=pod

=head1 NAME

Template::Plugin::ForumCode - Template plugin for HTML::ForumCode

=head1 SYNOPSIS

Standard usage in a Template Toolkit file:

  # load the TT module
  [% USE ForumCode %]

  # ForumCodify some text
  [% ForumCode.forumcode('[b]bold[/u] [u]underlined[/u] [i]italic[/i]') %]
  [% ForumCode.forumcode('**bold** __underlined__') %]

=head1 DESCRIPTION

This module provides the L<Template::Toolkit> plugin for L<HTML::ForumCode>.

ForumCode allows end-users (of a web-site) limited access to a set of HTML
markup through a HTML-esque syntax.

=head1 MARKUP

For a full description of available markup please see L<HTML::ForumCode>.

=head1 PUBLIC METHODS

=head2 new

Create a new instance of an HTML::ForumCode object.

=head1 SEE ALSO

L<HTML::ForumCode>,
L<Template::Toolkit>,
L<HTML::ForumCode::Cookbook>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
