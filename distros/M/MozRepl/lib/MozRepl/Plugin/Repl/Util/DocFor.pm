package MozRepl::Plugin::Repl::Util::DocFor;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

=head1 NAME

MozRepl::Plugin::Repl::Util::DocFor - Variable information.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;
    use Data::Dump qw(dump);

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Repl::Util::DocFor/] } });

    my $doc = $repl->repl_doc_for({ source => 'document.getElementById' });
    print dump $doc;

=head1 DESCRIPTION

Add repl_doc_for() method to L<MozRepl>.

=head1 METHODS

=head2 execute($ctx, $args)

Return variable information as hash reference.

If variable is function, then may be return value within correct arguments list.
(Depend on whether toSource() return value is complete function definition or not.)

If variable is DOM Node, then return value within nodename value.

If variable has "doc" property, then return value within doc value.

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
    my @response = $ctx->execute($cmd);
    my $result = {};

    for my $line (@response) {
        my ($key, $value) = ($line =~ /^(TYPE|NAME|NODENAME|ARGS): (.*)/);

        if ($key) {
            $key = lc($key);
            $result->{$key} = $value;
            $result->{$key} = [split(/, /, $value)] if ($key eq "args" && $value !~ /^\[.*\]$/);
        }
        else {
            $result->{doc} .= $line . "\n";
        }
    }

    return $result;
}

=head2 method_name()

Return constant value,  "repl_doc_for".
Used by method name adding method to L<MozRepl> object.

=cut

sub method_name {
    return "repl_doc_for";
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=item L<MozRepl::Plugin::Repl::Util::HelpUrlFor>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-repl-util-docfor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Repl::Util::DocFor

__DATA__
__execute__
[% repl %].util.docFor([% source %]);
__END__
