package MozRepl::Plugin::Location;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);
use JSON::Any qw(XS DWIW Syck JSON);

=head1 NAME

MozRepl::Plugin::Location - Dump window.location object as possible.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/OpenNewTab Location/] } });

    $repl->open_new_tab({ url => "http://d.hatena.ne.jp/ZIGOROu/", selected => 1 });

    sleep(5);

    my $location = $repl->location();
    print $location->{href};

=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.
See below detail.

=over 4

=item all

Defalt 0, return location object dump of current tab.
If this value is 1, dump location object from all tabs.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{all} = ($args->{all}) ? 'true' : 'false';

    my $command = $self->process('execute', $params);
    my $result = $ctx->execute($command);

    return JSON::Any->new->jsonToObj($result);
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-location@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Location

__DATA__
__execute__
(function(all) {

  function getLocationAsJSON(tWindow) {
    var json = {};

    for (var p in tWindow.location) {
      var type;

      try {
        type = typeof tWindow.location[p];
      }
      catch (e) {
        continue;
      }

      if (type == "object" || type == "function" || type == "undefined") {
        continue;
      }

      json[p] = tWindow.location[p];
    }

    return json;
  }

  if (all) {
      return JSONstring.make(Array.prototype.map.call(
          window.getBrowser().tabContainer.childNodes, 
          function(tab) {
              return JSONString.make(getLocationAsJSON(tab.linkedBrowser.contentWindow));
          }
      ));
  }
  else {
      return JSONstring.make(getLocationAsJSON(window.getBrowser().contentWindow));
  }
})([% all %]);
__END__
