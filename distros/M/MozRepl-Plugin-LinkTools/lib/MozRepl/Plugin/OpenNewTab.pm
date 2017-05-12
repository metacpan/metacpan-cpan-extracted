package MozRepl::Plugin::OpenNewTab;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

use MozRepl::Util;

=head1 NAME

MozRepl::Plugin::OpenNewTab - Open new tab and url.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/OpenNewTab/] } });

    $repl->open_new_tab({ url => "http://d.hatena.ne.jp/ZIGOROu/", selected => 1 });

=head1 DESCRIPTION

Add open_new_tab() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.
See below detail.

=over 4

=item url

=item selected

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{url} = MozRepl::Util->javascript_value($args->{url});
    $params->{selected} = ($args->{selected}) ? "true" : "false";

    my $command = $self->process('execute', $params);
    my $result = $ctx->execute($command);

    return ($result eq 'true') ? 1 : 0;
}

=head2 method_name()

Return constant value,  "open_new_tab".
Used by method name adding method to L<MozRepl> object.

=cut

sub method_name {
    return "open_new_tab";
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-opennewtab@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::OpenNewTab

__DATA__
__execute__
(function(url, selected) {
  selected = (selected) ? true : false;

  var tab;

  try {
    tab = window.top.getBrowser().addTab(url);

    if (!tab) {
      return false;
    }

    if (selected) {
      window.top.getBrowser().selectedTab = tab;
    }
  }
  catch (e) {
    return false;
  } 

  

  return true;
})([% url %], [% selected %])
__END__
