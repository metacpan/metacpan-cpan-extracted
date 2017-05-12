package MozRepl::Plugin::Repl::Search;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Search - The fantastic new MozRepl::Plugin::Repl::Search!

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Search/] } });

    my @results = $repl->repl_search({
      pattern => '^getElement',
      context => 'document'
    });
    print join("\n", @results);

=head1 DESCRIPTION

Add repl_search() method to L<MozRepl>.

=head1 METHODS

Search properties by regex on specified context.

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item context

Context variable or value.

=item pattern

Search pattern string.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    $args->{context} ||= "this";
    $args->{repl} = $ctx->repl;

    my $cmd = $self->process('execute', $args);
    my @result = $ctx->execute($cmd);

    return wantarray ? @result : join("\n", @result);
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-search@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Search
__DATA__
__execute__
[% repl %].search([% pattern %], [% context %]);
__END__
