package MozRepl::Plugin::Repl::Util::HelpUrlFor;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Util::HelpUrlFor - Return xulplanet reference url if exists.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;
    use MozRepl::Util;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Util::HelpUrlFor/] } });

    print $repl->repl_help_url({ source => q|window.document.getElementsByTagName('window')[0]| });
    print $repl->repl_help_url({ source => MozRepl::Util->javascript_value(q|@mozilla.org/network/protocol;1?name=view-source|) });

=head1 DESCRIPTION

Add repl_help_url() method to L<MozRepl>

=head1 METHODS

=head2 setup($ctx, $args)

Now, MozLab 0.1.6 is include bug in repl.util.helpUrlFor() method.
So setup() process is overriding this method.

=cut

sub setup {
    my ($self, $ctx, $args) = @_;

    $ctx->execute($self->process('setup', { repl => $ctx->repl }));
}

=head2 execute

Return xulplanet reference url if exists.

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item source

JavaScript variable or value.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $cmd = $self->process('execute', { repl => $ctx->repl, source => $args->{source} });
    return "" . $ctx->execute($cmd);
}

=head2 method_name()

Return constant value,  "repl_help_url".
Used by method name adding method to L<MozRepl> object.

=cut

sub method_name {
    return "repl_help_url";
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-util-helpurlfor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Util::HelpUrlFor

__DATA__
__setup__
[% repl %].util.helpUrlFor = function(thing) {
  function xulPlanetXpcomClassUrl(classID) {
    
    return "http://xulplanet.com/references/xpcomref/comps/c_" + classID.replace(/^@mozilla.org\//, "").replace(/[;\?\/=-]/g, "") + ".html";
  }

  function xulPlanetXulElementUrl(element) {
    return "http://xulplanet.com/references/elemref/ref_" + element.nodeName + ".html";
  }

  if (typeof thing == "string") {
    if (thing.match(/^@mozilla.org\//)) {
      return xulPlanetXpcomClassUrl(thing);
    }
  } else if (thing.QueryInterface && (function () {const NS_NOINTERFACE = 2147500034;try {thing.QueryInterface(Components.interfaces.nsIDOMXULElement);return true;} catch (e if e.result == NS_NOINTERFACE) {}})()) {
    return xulPlanetXulElementUrl(thing);
  }
};
__execute__
[% repl %].util.helpUrlFor([% source %]);
__END__
