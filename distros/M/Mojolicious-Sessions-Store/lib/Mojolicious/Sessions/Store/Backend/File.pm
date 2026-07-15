package Mojolicious::Sessions::Store::Backend::File;
$Mojolicious::Sessions::Store::Backend::File::VERSION = '0.01';
# ABSTRACT: File-based session storage backend

use Mojo::Base 'Mojolicious::Sessions::Store::Backend', -signatures;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::File;

has 'store_dir';    # directory where session files are stored

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);

    die "store_dir is required" unless $self->store_dir;

    # Ensure the directory exists
    my $dir = Mojo::File->new($self->store_dir);
    $dir->make_path unless -d $dir;

    return $self;
}

sub load ($self, $session_id) {
    my $file = $self->_session_file($session_id);
    return undef unless -f $file;

    my $content = eval { $file->slurp };
    return undef unless $content;

    my $data = eval { decode_json($content) };
    return undef unless $data && ref $data eq 'HASH';

    return $data;
}

sub save ($self, $session_id, $data) {
    my $file    = $self->_session_file($session_id);
    my $json    = encode_json($data);
    my $tmp     = Mojo::File->new("$file.$$." . int(rand(100000)));

    # Atomic write: write to temp file, then rename
    $tmp->spurt($json);
    rename($tmp->to_string, $file->to_string)
        or die "Failed to rename session file: $!";

    return 1;
}

sub delete ($self, $session_id) {
    my $file = $self->_session_file($session_id);
    return 1 unless -f $file;
    unlink($file->to_string);
    return 1;
}

sub _session_file ($self, $session_id) {
    return Mojo::File->new($self->store_dir, "$session_id.json");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Sessions::Store::Backend::File - File-based session storage backend

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Mojolicious::Sessions::Store::Backend::File;

    my $backend = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => '/path/to/sessions',
    );

    my $data = $backend->load('abc123');
    $backend->save('abc123', { user_id => 42 });
    $backend->delete('abc123');

=head1 DESCRIPTION

Stores session data as JSON files on the filesystem. Each session is a
single file named C<$session_id.json> in the C<store_dir> directory.

Writes are atomic (write to temp file, then rename) to prevent corruption
on crash.

=head1 NAME

Mojolicious::Sessions::Store::Backend::File - File-based session storage backend

=head1 ATTRIBUTES

=head2 store_dir

    my $dir = $backend->store_dir;
    $backend = $backend->store_dir('/path/to/sessions');

Directory where session files are stored. Required. Created automatically
if it does not exist.

=head1 METHODS

=head2 load

    my $data = $backend->load($session_id);

Reads and decodes the JSON file. Returns a hashref or C<undef>.

=head2 save

    $backend->save($session_id, $data);

Writes the session data as JSON to an atomic temporary file,
then renames it to the final filename.

=head2 delete

    $backend->delete($session_id);

Removes the session file if it exists.

=head1 SEE ALSO

L<Mojolicious::Sessions::Store>, L<Mojolicious::Sessions::Store::Backend>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
