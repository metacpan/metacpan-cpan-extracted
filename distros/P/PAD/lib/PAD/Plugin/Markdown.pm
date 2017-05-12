package PAD::Plugin::Markdown;
use strict;
use warnings;
use parent 'PAD::Plugin';
use Text::Markdown 'markdown';

sub suffix       { qr/\.(?:markdown|mk?dn?)$/ }
sub content_type { 'text/html; charset=UTF-8' }

sub execute {
    my $self = shift;
    my $path = $self->relative_path;

    open my $text, '<', $path or die $!;
    my $md = markdown(do { local $/; <$text> });

    my $res = $self->request->new_response(200, ['Content-Type' => $self->content_type], $md);
    $res->finalize;
}

1;
__END__

=head1 NAME

PAD::Plugin::Markdown - render markdown file as HTML

=head1 SYNOPSIS

    # enable PAD::Plugin::Markdown
    pad Markdown

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<PAD>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

