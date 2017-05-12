use strict;
package Module::Depends;
use Parse::CPAN::Meta;
use Cwd qw( getcwd );
use base qw( Class::Accessor::Chained );
__PACKAGE__->mk_accessors(qw( dist_dir debug libs requires configure_requires build_requires error ));
our $VERSION = '0.16';

=head1 NAME

Module::Depends - identify the dependencies of a distribution

=head1 SYNOPSIS

 use YAML;
 use Module::Depends;
 my $deps = Module::Depends->new->dist_dir( '.' )->find_modules;
 print "Our dependencies:\n", Dump $deps->requires;

=head1 DESCRIPTION

Module::Depends extracts module dependencies from an unpacked
distribution tree.

Module::Depends only evaluates the META.yml shipped with a
distribution.  This won't be effective until all distributions ship
META.yml files, so we suggest you take your life in your hands and
look at Module::Depends::Intrusive.

=head1 METHODS

=head2 new

simple constructor

=cut

sub new {
    my $self = shift;

    return $self->SUPER::new({
        libs           => [],
        requires       => {},
        build_requires => {},
        configure_requires => {},
        error          => '',
    });
}

=head2 dist_dir

Path where the distribution has been extracted to.

=head2 find_modules

scan the C<dist_dir> to populate C<libs>, C<requires>, and C<build_requires>

=cut

sub find_modules {
    my $self = shift;

    my $here = getcwd;
    unless (chdir $self->dist_dir) {
        $self->error( "couldn't chdir to " . $self->dist_dir . ": $!" );
        return $self; 
    }
    eval { $self->_find_modules };
    chdir $here;
    die $@ if $@;
    
    return $self;
}

sub _find_modules {
    my $self = shift;

    my ($file) = grep { -e $_ } qw( MYMETA.yml META.yml );
    if ($file) {
        my $meta = ( Parse::CPAN::Meta::LoadFile( $file ) )[0];
        $self->requires( $meta->{requires} );
        $self->build_requires( $meta->{build_requires} );
    }
    else {
        $self->error( "No META.yml found in ". $self->dist_dir );
    }
    return $self;
}


1;
__END__

=head2 libs

an array reference of lib lines

=head2 requires

A reference to a hash enumerating the prerequisite modules for this
distribution.

=head2 configure_requires

A reference to a hash enumerating the prerequisite modules to configure this
distribution.

=head2 build_requires

A reference to a hash enumerating the modules needed to build the
distribution.

=head2 error

A reason, if any, for failing to get dependencies.

=head1 AUTHOR

Richard Clamp, based on code extracted from the Fotango build system
originally by James Duncan and Arthur Bergman.

=head1 COPYRIGHT

Copyright 2010, Richard Clamp.
Copyright 2004-2008, Fotango.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Depends::Intrusive>

=cut
