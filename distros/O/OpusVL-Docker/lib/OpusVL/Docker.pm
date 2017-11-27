package OpusVL::Docker;
# ABSTRACT: Perl/docker utils by OpusVL
our $VERSION = '0.002';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Docker - Perl/docker utils by OpusVL

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This distribution contains both example and working files for various parts of a
Docker/docker-compose setup. Files included are:

=over

=item C<bin/entrypoint>

A working entrypoint for PSGI-based applications.

=item C<Dockerfile.example.base>

An example base Dockerfile from which to build your application.

=item C<Dockerfile.example.patch>

An example Dockerfile with which to patch the application you built with the
base file.

=back

=head1 AUTHOR

Alastair McGowan-Douglas <altreus@altre.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by OpusVL <support@opusvl.com>.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
