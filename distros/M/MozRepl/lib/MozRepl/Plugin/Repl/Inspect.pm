package MozRepl::Plugin::Repl::Inspect;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

use MozRepl::Util;

=head1 NAME

MozRepl::Plugin::Repl::Inspect - Inspect specified javascript object.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Inspect/] } });

    print $repl->repl_inspect({ source => 'window.getBrowser().contentWindow.location' });

=head1 DESCRIPTION

Add repl_inspect() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item source

Target object, default value is current context object. (optional)
(Just do it same as repl.look())

=item name

Each properties prefix label. (optional)

=item max_depth

Limitation inspecting depth. (optional)

=item current_depth

Start inspecting depth. (optional)

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};
    for (qw/max_depth name current_depth/) {
        $params->{$_} = MozRepl::Util->javascript_value($args->{$_});
    }

    $params->{source} = $args->{source} || sprintf("%s._workContext", $ctx->repl);
    $params->{repl} = $ctx->repl;

    my $command = $self->process('execute', $params);
    my @responses = $ctx->execute($command);

    return wantarray ? @responses : join("\n", @responses);
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-inspect@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Inspect

__DATA__
__execute__
[% repl %].inspect([% source %], [% max_depth %], [% name %], [% current_depth %]);
__END__
