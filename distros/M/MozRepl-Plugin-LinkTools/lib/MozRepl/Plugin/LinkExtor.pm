package MozRepl::Plugin::LinkExtor;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

use Carp::Clan qw(croak);
use JSON;

=head1 NAME

MozRepl::Plugin::LinkExtor - Extract "a" and "link" elements.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;
    use Data::Dump qw(dump);

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/JSON OpenNewTab LinkExtor/] } });

    $repl->open_new_tab({ url => "http://search.cpan.org/", selected => 1 });

    sleep(5);

    my $links = $repl->linkextor();

    print dump($links);

=head1 DESCRIPTION

Add linkextor() method to L<MozRepl>.

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

Default 0.
If this value is 1, then extracting links from all tabs.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    croak("Please include MozRepl::Plugin::JSON") unless ($ctx->can("json"));

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{all} = ($args->{all}) ? 'true' : 'false';

    my $command = $self->process('execute', $params);
    my $result = $ctx->execute($command);

    $result =~ s/^"//;
    $result =~ s/"$//;
    $result =~ s/\\"/"/g;

    return JSON->new(barekey => 1, quotapos => 1)->jsonToObj($result);
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-linkextor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::LinkExtor

__DATA__
__execute__
(function(all) {
  function documentLinksToJSON(cDocument) {
    function elementToJSON(element) {
      var result = {
        "nodeName": "",
        "attributes": {}
      };
      
      result.nodeName = element.nodeName;
      
      for (var i = 0, l = element.attributes.length; i < l; i++) {
        if ((/^on/i).test(element.attributes[i].nodeName)) {
          continue;
        }

        result.attributes[element.attributes[i].nodeName.toString()] = element.attributes[i].nodeValue;
      }
      
      return result;
    }
    
    var result = [];
    
    return result.concat(
                         Array.prototype.map.call(
                                                  cDocument.getElementsByTagName("link"),
                                                  elementToJSON
                                                  ),
                         Array.prototype.map.call(
                                                  cDocument.getElementsByTagName("a"),
                                                  elementToJSON
                                                  )
                         ).toSource();
  }

  if (all) {
    return JSONstring.make(Array.prototype.map.call(
        window.getBrowser().tabContainer.childNodes, 
        function(tab) {
            return documentLinksToJSON(tab.linkedBrowser.contentDocument);
        }
    ));
  }
  else {
    return JSONstring.make(documentLinksToJSON(window.getBrowser().contentDocument));
  }
})([% all %]);
__END__
