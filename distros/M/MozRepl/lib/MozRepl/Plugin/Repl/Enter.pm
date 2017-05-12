package MozRepl::Plugin::Repl::Enter;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Enter - Change to specified context

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Enter/] } });

    $repl->repl_enter({ source => "window" });
    $repl->repl_enter({ source => "gBrowser" });

    print $repl->execute(sprintf("%s.whereAmI();", $repl->repl)); ### [object XULElement]

=head1 DESCRIPTION

Add repl_back() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Change to specified context.

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item source

New context variable or value.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $cmd = $self->process('execute', { repl => $ctx->repl, source => $args->{source} });
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
C<bug-mozrepl-plugin-repl-enter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Enter

__DATA__
__execute__
[% repl %].enter([% source %]);
__END__
