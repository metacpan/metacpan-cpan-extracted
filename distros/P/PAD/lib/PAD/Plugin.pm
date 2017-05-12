package PAD::Plugin;
use strict;
use warnings;
use Carp ();
use File::Spec::Unix;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub suffix        { qr/.+/ }
sub content_type  { 'text/plain; charset=UTF-8' }

sub request       { shift->{request} }
sub relative_path { # extracted from Plack::App::File :)
    my $self = shift;
    my $path = $self->request->path_info;

    if ($path =~ /\0/) {
        Carp::croak "Bad Request";
    }

    my @path = split '/', $path;
    if (@path) {
        if ($path[0] eq '') {
            shift @path
        }

    } else {
        @path = '.';
    }

    if (grep { $_ eq '..' } @path) {
        Carp::croak "Forbidden";
    }

    File::Spec::Unix->catfile('.', @path);
}

sub execute { shift->request->new_response(501)->finalize }

1;
__END__

=head1 NAME

PAD::Plugin - base class for writing pad plugin

=head1 SYNOPSIS

    package PAD::Plugin::Static;
    use parent 'PAD::Plugin';
    use Plack::App::File;

    sub execute {
        my $self = shift;
        Plack::App::Directory->new->to_app->($self->request->env);
    }

=head1 METHODS

=over 4

=item C<suffix>

Specifies the suffix of file (in regexp) that to be filtered.

    # e.g.) for markdown file,
    sub suffix { qr/\.md$/ }

=item C<content_type>

Defines Content-Type of response. Default is C<text/plain; charset=UTF-8>.

    # e.g.) serve HTML file,
    sub content_type { 'text/html; charset=UTF-8' }

=item C<request>

Accessor of the C<Plack::Request>.
You can call this method in C<execute> method.

=item C<relative_path>

Converts C<PATH_INFO> into relative path. This method is convenient for C<open>ing file.

=item C<execute>

Write the main logic here.

    # e.g.) renders a markdown document and returns C<finalized> PSGI response
    sub execute {
        my $self = shift;
        my $path = $self->relative_path;

        open my $text, '<', $path or die $!;
        my $md = markdown(do { local $/; <$text> });

        my $res = $self->request->new_response(200, ['Content-Type' => $self->content_type], $md);
        $res->finalize;
    }


=back

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<PAD>, L<PAD::Plugin::Static>, L<PAD::Plugin::Markdown>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


