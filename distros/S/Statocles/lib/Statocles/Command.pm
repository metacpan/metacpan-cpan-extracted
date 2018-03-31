package Statocles::Command;
our $VERSION = '0.092';
# ABSTRACT: The base class for command modules

#pod =head1 SYNOPSIS
#pod
#pod     use Statocles::Base 'Command';
#pod     sub run {
#pod         my ( $self, @argv ) = @_;
#pod         ...;
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module is a base class for command modules.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item L<statocles>
#pod
#pod The documentation for the command-line application.
#pod
#pod =back
#pod
#pod =cut

use Statocles::Base 'Class';
use YAML;
use Path::Tiny;

#pod =attr site
#pod
#pod The L<Statocles::Site> object for the current site.
#pod
#pod =cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

sub _get_status {
    my ( $self, $status ) = @_;
    my $path = Path::Tiny->new( '.statocles', 'status.yml' );
    return {} unless $path->exists;
    YAML::Load( $path->slurp_utf8 );
}

sub _write_status {
    my ( $self, $status ) = @_;
    Path::Tiny->new( '.statocles', 'status.yml' )->touchpath->spew_utf8( YAML::Dump( $status ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command - The base class for command modules

=head1 VERSION

version 0.092

=head1 SYNOPSIS

    use Statocles::Base 'Command';
    sub run {
        my ( $self, @argv ) = @_;
        ...;
    }

=head1 DESCRIPTION

This module is a base class for command modules.

=head1 ATTRIBUTES

=head2 site

The L<Statocles::Site> object for the current site.

=head1 SEE ALSO

=over 4

=item L<statocles>

The documentation for the command-line application.

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
