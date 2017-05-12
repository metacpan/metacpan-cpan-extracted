package MozRepl::Plugin::Repl::Rename;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Rename - Rename repl object name

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Rename/] } });

    $repl->repl_rename('zigorou');
    print $repl->execute("zigorou");

=head1 DESCRIPTION

Add repl_rename() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>

=item $args

Hash reference.

=over 4

=item name

new repl object name.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{name} = MozRepl::Util->javascript_value($args->{name});

    my $command = $self->process('execute', $params);

    $ctx->log->debug($command);

    my $prompt = "/" . $args->{name} . "> /";

    $ctx->client->prompt($prompt);
    $ctx->repl($args->{name});
    $ctx->execute($command);

    return 1;
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-rename@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Rename

__DATA__
__execute__
[% repl %].rename([% name %]);
__END__
