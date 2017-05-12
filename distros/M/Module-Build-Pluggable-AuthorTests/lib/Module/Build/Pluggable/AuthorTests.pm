package Module::Build::Pluggable::AuthorTests;

use parent qw(Module::Build::Pluggable::Base);

use strict;
use warnings;

our $VERSION = '0.01';

sub HOOK_configure {

    my ( $self ) = shift;

    my @testdirs = (  'ARRAY' eq ref $self->{test_dirs} ?
		     @{ $self->{test_dirs} } : $self->{test_dirs} );

    $self->builder->test_files( @testdirs );

}

sub HOOK_build {

    my $self = shift;

    $self->add_action( 'authortest', \&ACTION_authortest );

}

sub ACTION_authortest {
    my ( $self ) = @_;

    $self->depends_on( 'build' );
    $self->depends_on( 'manifest' );
    $self->depends_on( 'distmeta' );


    $self->depends_on( 'test' );

    return;
}

1;

__END__

=pod

=head1 NAME

Module::Build::Pluggable::AuthorTest - Plugin to Module::Build to add author tests

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # Build.PL
    use strict;
    use warnings;
    use Module::Build::Pluggable qw[ AuthorTests ];

    my $builder = Module::Build::Pluggable->new(
        ...
    );
    $builder->create_build_script();

=head1 DESCRIPTION

This L<Module::Build::Pluggable> plugin adds an B<authortest> action which
recursively runs tests in both the normal test directory F<t>, as well
as in author-only test directories (by default F<xt> ).

To specify alternate author-only test directories, pass the C<test_dirs> option
when loading the module, e.g.

  use Module::Build::Pluggable ( AuthorTests =>
                                  { test_dirs => 'xtt' } );


C<test_dirs> will accept either a scalar or an array of directories.

To run the tests,

  ./Build authortest

=head1 SEE ALSO

http://elliotlovesperl.com/2009/11/24/explicitly-running-author-tests/

which is where the idea and code comes from.


=head1 AUTHOR

Diab Jerius E<lt>djeriuss@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

Copyright (c) 2016 Diab Jerius

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
