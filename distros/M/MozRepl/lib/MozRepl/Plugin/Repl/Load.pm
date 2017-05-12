package MozRepl::Plugin::Repl::Load;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

use MozRepl::Util;

=head1 NAME

MozRepl::Plugin::Repl::Load - Load external script

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Load/] } });

    $repl->repl_load({
      uri => q|http://json.org/json.js|
    });
    print $repl->execute("String.prototype.toJSONString;");

=head1 DESCRIPTION

Add repl_load() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Load external script

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item uri

External script location.

=item context

Default undefined.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $params = {};

    $params->{repl} = $ctx->repl;
    $params->{uri} = MozRepl::Util->javascript_value(MozRepl::Util->javascript_uri($args->{uri}));
    $params->{context} ||= MozRepl::Util->javascript_value(undef);

    my $command = $self->process('execute', $params);
    $ctx->execute($command);

    return 1;
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
C<bug-mozrepl-plugin-repl-load@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Load

__DATA__
__execute__
[% repl %].load([% uri %], [% context %]);
__END__
