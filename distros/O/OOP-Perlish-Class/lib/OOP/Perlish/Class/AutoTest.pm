#!/usr/bin/perl
use warnings;
use strict;
{

    package OOP::Perlish::Class::AutoTest;
    use warnings;
    use strict;
    ############################################################################################
    ## Simple, somewhat hacky way of running unit-tests in batch to make testing framework
    ## easier to manage.
    ############################################################################################

    use Data::Dumper;
    use B;
    use File::Basename qw(dirname fileparse basename);
    use File::Find;
    use Test::Class;

    ############################################################################################
    ## Provide an import method to handle testing parameters. 
    ############################################################################################
    sub import
    {
        my ( $self, @tags ) = @_;
        my %test_opts = @tags if( scalar @tags % 2 == 0 );
        my @packages;
        my @test_directories;
        my @exclude;

        return unless( scalar keys %test_opts );

        if( exists $test_opts{package} ) {
            if( $test_opts{package} && ref( $test_opts{package} ) eq 'ARRAY' ) {
                @packages = @{ $test_opts{package} };
            }
            elsif( $test_opts{package} && !ref( $test_opts{package} ) ) {
                @packages = ( $test_opts{package} );
            }
        }
        if( exists $test_opts{tests} ) {
            if( $test_opts{tests} && ref( $test_opts{tests} ) eq 'ARRAY' ) {
                @test_directories = @{ $test_opts{tests} };
            }
            elsif( $test_opts{tests} && !ref( $test_opts{tests} ) ) {
                @test_directories = ( $test_opts{tests} );
            }
        }
        if( exists $test_opts{exclude} ) {
            if( $test_opts{exclude} && ref( $test_opts{exclude} ) eq 'ARRAY' ) {
                @exclude = @{ $test_opts{exclude} };
            }
            elsif( $test_opts{exclude} && !ref( $test_opts{exclude} ) ) {
                @exclude = ( $test_opts{exclude} );
            }
        }

        for my $package ( $self->_find_test_modules( \@packages, \@test_directories, \@exclude ) ) {
            eval "require $package" || die "$@";
        }
    }

    ############################################################################################
    ## Divine information from whence a subroutine is loaded
    ############################################################################################
    sub _introspect_sub
    {
        my ( $self, $sub ) = @_;
        my $cv = B::svref_2object($sub);

        return ( ( $cv->STASH()->NAME(), $cv->FILE() ) );
    }

    ############################################################################################
    ## using introspect_sub, find any subroutine, introspect it to learn which package_name and
    ## file_name it comes from.
    ############################################################################################
    sub _find_package_filename
    {
        my ( $self, $package ) = @_;

        my ( $package_name, $file_name );

        eval "require $package";

        no strict 'refs';
        my %sym = %{ *{ '::' . $package . '::' } };
        use strict;

        while( my ( $k, $v ) = each %sym ) {
            if( defined *{$v}{CODE} ) {
                ( $package_name, $file_name ) = $self->_introspect_sub( *{$v}{CODE} );
                last if( $package_name eq $package );
            }
        }
        return $file_name;
    }

    ############################################################################################
    ## Search the path of a module for subdirectories matching paths in 'tests => []', yet not 
    ## matching $exclude_re
    ############################################################################################
    sub _find_test_modules
    {
        my ( $self, $packages, $test_directories, $exclude ) = @_;
        my @packages         = @{$packages};
        my @test_directories = @{$test_directories};
        my @exclude          = @{$exclude};

        my @test_packages;

        for my $package (@packages) {
            my $package_path = $self->_find_package_filename($package);
            my $search_path = join( '/', ( fileparse( $package_path, qr/\.pm/ ) )[ 1, 0 ] );

            File::Find::find(
                {
                   follow            => 0,
                   no_chdir          => 1,
                   bydepth           => 1,
                   untaint           => 1,
                   untaint_exclude   => 1,
                   dangling_symlinks => undef,
                   preprocess        => sub {
                       my $exclude_re = '(?:' . join( '|', @exclude ) . ')';
                       return grep { !/$exclude_re/ } @_;
                   },
                   wanted => sub {
                       m/\.pm$/ && do {
                           ( my $module = $_ ) =~ s/^\Q$search_path\E//;
                           $module =~ s,/+,/,g;
                           $module =~ s,/,::,g;
                           $module =~ s/\.pm$//;
                           $module = $package . $module;
                           push @test_packages, $module;
                       };
                   },
                },
                map { $search_path . '/' . $_ } @test_directories,
                            );
        }
        return @test_packages;
    } ## end sub _find_test_modules

    ############################################################################################
    ## convenience function to invoke Test::Class->runtests() indirectly
    ############################################################################################
    sub runtests
    {
        my ($self) = @_;
        Test::Class->runtests();
    }
}
1;
__END__

=head1 NAME

OOP::Perlish::Class::AutoTest

=head1 SUMMARY

    #!/usr/bin/perl
    use warnings;
    use strict;

    use blib;
    use OOP::Perlish::Class::AutoTest (tests => [ 'UnitTests' ], package => [ 'OOP::Perlish::Class' ], exclude => [ '^Base.pm$' ]);
    OOP::Perlish::Class::AutoTest->runtests();

=head1 DESCRIPTION

Automatically find unittests in @INC for specified package(s) and run them

Unittests must be derived from Test::Class.

See OOP::Perlish::Class distrubution for complete examples. Below are some highlights:

=head1 METHODS

=over

=item runtests

Run all unittests found for given packages

=back

=head1 LOCATIONS

This module makes the following assumptions about the location of unit tests with relationship to the classes they test:

Given the module location /path/to/My/Class.pm 
Unit tests will be in /path/to/My/Class/<test-identifier-path>/*.pm

So, for example, if I choose as test-identifier-paths 'UnitTests' and 'SmokeTests', then all my tests would be in:

 /path/to/My/Class/UnitTests/*.pm
 /path/to/My/Class/SmokeTests/*.pm

Any module found in those path locations will automatically be run with the lines:

 use OOP::Perlish::Class::AutoTest (tests => [ 'UnitTests', 'SmokeTests', ], package => 'My::Class' );
 OOP::Perlish::Class::AutoTest->runtests();

=head1 EXAMPLE

 #!/usr/bin/perl
 use warnings;
 use strict;

 use blib;
 use OOP::Perlish::Class::AutoTest (tests => [ 'UnitTests' ], package => 'My::Class', exclude => [ '^Base.pm$' ]);
 OOP::Perlish::Class::AutoTest->runtests();

=over

=item tests

A listref of directory names in @INC where you can find tests for each 'package'. The assumption is that these tests will exist as a subdirectory
of the class itself, so for instance, the tests for My::Class are in OOP/Perlish/Class/UnitTests/*, in the same location as My::Class itself.

This assumption is important, because this module determines where My::Class was used from, and does a 'find' on that directory to look for paths matching each item in C<tests => []>.

Note that you can include a single string in lieu of a listref, which will be treated as a listref containing only a single member.

=item package

The next list is the list of packages to test. This allows you to have every unit-test for the same component run out of the same file. So if you have a class hiarchy which makes sense to test
all at once, you could list them all with  C<package => [ 'My::Class', 'My::Class::Thing' ]>. For each 'package', all subdirectories matching names in C<tests => []> will be searched. 

Note that you can include a single string in lieu of a listref, which will be treated as a listref containing only a single member.

I chose not to pluralize this parameter, as it almost always only makes sense to test a single class at a time. 

=item exclude

A listref wherein you can include regular expression patterns for files you wish to exclude. This useful for things like base-classes which your test-classes are derived from, but are not themselves test classes.
Specifying multple items in the listref is identical to providing a pattern with each element logically ORed together [e.g. (?:foo|bar) ]

=back

=cut
