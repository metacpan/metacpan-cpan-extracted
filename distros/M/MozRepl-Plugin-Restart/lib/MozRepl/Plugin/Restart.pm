package MozRepl::Plugin::Restart;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Restart - Restart Firefox/Thunderbird

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use MozRepl;
    
    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Restart/] } });
    
    $repl->restart; ### and restart your Firefox or Thunderbird

=head1 DESCRIPTION

Add restart() method to L<MozRepl>.

=head2 Restart your Firefox/Thunderbird using JavaScript

In the MDC Code snippets:Miscellaneous(http://developer.mozilla.org/en/docs/Code_snippets:Miscellaneous#Restarting_Firefox.2FThunderbird)

    var nsIAppStartup = Components.interfaces.nsIAppStartup;
    Components.classes["@mozilla.org/toolkit/app-startup;1"].getService(nsIAppStartup).quit(nsIAppStartup.eForceQuit | nsIAppStartup.eRestart);

MozRepl object (default "repl") has attribute "Ci" and "Cc".
"Ci" is alias Components.interfaces, "Cc" is alias Components.classes.
So restart script will be here,

    (function(repl) {
      var nsIAppStartup = repl.Ci.nsIAppStartup;
      repl.Cc["@mozilla.org/toolkit/app-startup;1"].getService(nsIAppStartup).quit(nsIAppStartup.eForceQuit | nsIAppStartup.eRestart); 
    })(window.repl);


=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};
    $params->{repl} = $ctx->repl;

    my $command = $self->process('execute', $params);

    $ctx->log->warn("Restarting firefox/thunderbird ...");
    $ctx->execute($command);

    return 1;
}

=head1 SEE ALSO

=over 4

=item L<MozRepl>

=item L<mozrestart>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-restart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Restart

__DATA__
__execute__
(
 function(repl) { 
   var nsIAppStartup = repl.Ci.nsIAppStartup;
   repl.Cc["@mozilla.org/toolkit/app-startup;1"].getService(nsIAppStartup).quit(nsIAppStartup.eForceQuit | nsIAppStartup.eRestart); 
})([% repl %]);
__END__
