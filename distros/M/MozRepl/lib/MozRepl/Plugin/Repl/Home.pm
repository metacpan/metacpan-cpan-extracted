package MozRepl::Plugin::Repl::Home;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Home - Change to home context.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Enter Repl::Home/] } });

    $repl->repl_enter({ source => 'window.getBrowser().contentDocument' });
    print $repl->repl_home(); ### [object ChromeWindow]

=head1 DESCRIPTION

Add repl_home() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Change to home context.

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

=item L<MozRepl::Plugin::Repl::Back>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-home@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Home

__DATA__
__execute__
[% repl %].home();
__END__
