package MozRepl::Plugin::Repl::Back;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Back - Back to previous context

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Enter Repl::Back/] } });

    $repl->repl_enter({ source => "window" });
    $repl->repl_enter({ source => "gBrowser" });
    $repl->repl_enter({ source => "contentWindow" });
    print $repl->repl_back(); ### gBrowser/[object XULElement]
    print $repl->repl_back(); ### window/[object ChromeWindow]

=head1 DESCRIPTION

Add repl_back() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Back to previous context.

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $cmd = $self->process('execute', { repl => $ctx->repl });
    return "" . $ctx->execute($cmd);
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=item L<MozRepl::Plugin::Repl::Enter>

=item L<MozRepl::Plugin::Repl::Home>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-back@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Back

__DATA__
__execute__
[% repl %].back();
__END__
