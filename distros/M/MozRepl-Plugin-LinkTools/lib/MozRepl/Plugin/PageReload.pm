package MozRepl::Plugin::PageReload;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::PageReload - Reload specified tabs.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;
    use Data::Dump qw(dump);

    my $repl == MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/PageReload/] } });

    $repl->page_reload();

=head1 DESCRIPTION

Add page_reload() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.
See below detail.

=over 4

=item tabindex

Default undef.
If tabindex is setted, then reloading page specified by tabindex.

=item regex

Default undef.
If regex is setted, then reloading pages matched regex to url.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{tab_index} = (defined $args->{tab_index}) ? $args->{tab_index} : 'undefined';
    $params->{regex} = ($args->{regex}) ? $args->{regex} : 'undefined';

    my $command = $self->process('execute', $params);
    my $result = $ctx->execute($command);

    return $result;
}

=head2 method_name

=cut

sub method_name {
    "page_reload";
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-pagereload@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::PageReload

__DATA__
__execute__
(function(args) {
  try {
    if (args.regex && args.regex instanceof RegExp) {
      var rcnt = 0;

      Array.prototype.forEach.call(
                                   window.getBrowser().tabContainer.childNodes, 
                                   function(tab) {
                                     var tLocation = tab.linkedBrowser.contentWindow.location;

                                     if (args.regex.test(tLocation.href)) {
                                       tLocation.reload();
                                       rcnt++;
                                     }
                                   });

      return rcnt;
    }
    else if (typeof args.tab_index == "number") {
      window.getBrowser().getBrowserAtIndex(tab_index).linkedBrowser.contentWindow.location.reload();
      return 1;
    }
    else {
      window.getBrowser().contentWindow.location.reload();
      return 1;
    }
  }
  catch (e) {
    return 0;
  }
})({ tab_index: [% tab_index %], regex: [% regex %] });
__END__
