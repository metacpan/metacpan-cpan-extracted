package MozRepl::Plugin::Repl::Print;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Print - Print value

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Print/] } });

    print $repl->repl_print("Kyoshinhei ga do-n!!!"); ### Kyoshinhei ga do-n!!!

=head1 DESCRIPTION

Add repl_print() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Print value.

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item source

Javascript variable or value.

=item newline

Include newline(\n). default true.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{source} = $args->{source};
    $params->{newline} = (defined $args->{newline}) ? ($args->{newline} ? "true" : "false") : "undefined";
    $params->{repl} = $ctx->repl;

    my $command = $self->process('execute', $params);
    my @responses = $ctx->execute($command);

    return join("\n", @responses);
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=item L<MozRepl::Util>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-print@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Print

__DATA__
__execute__
[% repl %].print([% source %], [% newline %]);
__END__
