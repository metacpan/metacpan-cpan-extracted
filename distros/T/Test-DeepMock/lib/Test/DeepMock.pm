package Test::DeepMock;

use 5.008;
use strict;
use warnings;

=head1 NAME

Test::DeepMock - Awesome abstract factory class to mock everything for unit tests.

Test::DeepMock unshifts objects into @INC which handle "require" and returns what you need
for your tests.

=head1 VERSION

Version 0.0.4

=cut

our $VERSION = '0.0.4';


=head1 SYNOPSIS

Test::DeepMock is a abstract mock factory which injects mocks in @INC so
whenever your app "requires" the package the mock will be loaded.
Extreemly usefull for testing old legacy code.

Create your factory of mocks:

    package My::Factory;
    use Test::DeepMock ();

    our @ISA = qw( Test::DeepMock );
    our @CONFIG = {
        'My::Package' => {
            source => 'package My::Package; 1;'
        },
        'My::Another::Package' => {
            file_handle => $FH
        },
        'My::Package::From::File' => {
            path => '/some/path/to/mock'
        },
        default => sub {
            my ($class, $package_name) = @_;
            #returns scalar with source of package or file handle
            #return undef to interrupt mocking
        },
    };

In the test: import packages that you want to mock from your factory:

    use My::Factory qw(
        My::Package
        My::Another::Package
        My::Package::From::File
        This::Package::Will::Triger::Default::Subroutine
    );

=head1 CONFIG

our $CONFIG in the ancestor of Test::DeepMock will identify a mock configuration.

=head2 keys of config

Keys are the package names (e.g. 'My::Package'); Also, there are 'default' entry, which should provide
subroutine which returns scalar (package content) or file handle to a file with package content.

=head1 PATH_TO_MOCKS

our $PATH_TO_MOCKS - is a package scalar which should contain path to dir, where to look
for mock implementations. If Factory cannot find mock implementation, it will trigger
default handler, if it exists.

=head1 Mock configuration

Each mock package in our $CONFIG can have following keys:

=head2 source

Scalar or scalar reference with package content, which will be loaded.

=head2 file_handle

File handle to a file with package content

=head2 path

Path to a foulder where to look for a package (similar to @INC or PERL5LIB entries)

=head2 IT COULD BE A REFERENCE TO AN EMPTY HASH - in this way it will search in the $PATH_TO_MOCKS and then trigger default handler.

=head1 SUBROUTINES/METHODS

=head2 import

"import" is used to specify which packages you want to mock. Does not actualy import something.

=cut

our $CONFIG;
our $PATH_TO_MOCKS;
use constant DEBUG => $ENV{TEST_DEEPMOCK_DEBUG};

sub import {
    my ($class, @packages) = @_;

    my ($config, $path_to_mocks);
    {
        no strict 'refs';
        $config = ${$class."::CONFIG"};
        $path_to_mocks = ${$class."::PATH_TO_MOCKS"};
    }

    my $default_handler = $config->{default};

    foreach my $package (@packages) {
        my $file_name = $package;
        $file_name =~ s/::/\//g;
        $file_name .= '.pm';
        my %inc_args = (
            file_name => $file_name
        );
        my $package_config = $config->{$package};

        #Searching for mocks:
        #  1. by source
        #  2. by file_handle
        #  3. by path
        #  4. default handler
        if (defined $package_config->{source}){
            # by source
            $inc_args{source} = $package_config->{source};
        } elsif (defined $package_config->{file_handle}){
            # by file_handle
            $inc_args{file_handle} = $package_config->{file_handle};
        } elsif (defined $package_config->{path} || defined $path_to_mocks){
            # lets try to pick up mocks from file system
            my $mock_path = defined $package_config->{path} ? $package_config->{path} : $path_to_mocks;
            my $FH;
            open($FH, "< $mock_path/$inc_args{file_name}") or undef $FH;

            warn "cannot open file: $mock_path/$inc_args{file_name}"
                if !$FH && DEBUG() ;

            if ($FH) {
                $inc_args{file_handle} = $FH;
            } elsif (ref $default_handler eq 'CODE') {
                # this is odd, but lets try to run default handler
                warn "Running default handler for $package"
                  if DEBUG();
                _run_default_handler($class, $default_handler, $package, \%inc_args);
            } else {
                # ok, I give up
                die "could not mock $package. Please, check \$$class\::CONFIG";
            }
        } elsif (ref $default_handler eq 'CODE'){
            _run_default_handler($class, $default_handler, $package, \%inc_args);
        } else {
            # I give up
            die "could not mock $package. Please, check \$$class\::CONFIG";
        }

        _fix_up_inc_args(\%inc_args);

        my $interceptor = Test::Util::Inc->new(
            %inc_args,
        );
        unshift @INC, $interceptor;
    }
}

sub _run_default_handler {
    my ($class, $handler, $package, $inc_args) = @_;
    my $mock = eval {&$handler($class, $package)};
    if ($@) {
        die "default handler died for '$package' with $@";
    }
    die "could not mock $package. Please, check \$$class\::CONFIG"
        unless $mock;

    my $type = (ref $mock eq "GLOB") ? "file_handle" :
            (!ref $mock || ref $mock eq 'SCALAR') ? "source" : undef;
    die "could not mock $package. Default handler returned neither scalar nor file handle. Please, check \$$class\::CONFIG"
        unless $type;

    $inc_args->{$type} = $mock;
}

sub _fix_up_inc_args {
    my $inc_args = shift;
    my $source = $inc_args->{source};
    $inc_args->{source} = \$source
        if defined $source && !ref $source;
}

=head1 AUTHOR

Mykhailo Koretskyi, C<< <radio.mkor at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-deepmock at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DeepMock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::DeepMock


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-DeepMock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-DeepMock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-DeepMock>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-DeepMock/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mykhailo Koretskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Test::DeepMock

package Test::Util::Inc;
use strict;
use warnings;

use constant MOCK_PATH => $ENV{DEEP_MOCK_PATH};
use constant OUTPUT_KEYS => [
    qw ( source file_handle file_name)
];

sub new {
    my ($class, %args) = @_;

    my $self = {
        (map { ($_ => $args{$_}) } @{OUTPUT_KEYS()}),
    };

    bless $self, $class;

    return $self;
}

sub Test::Util::Inc::INC {
    my ($self, $filename) = @_;

    # skip, if filename doesn`t match
    return undef
        if $self->{file_name} ne $filename;

    return $self->{source} ? $self->{source} : $self->{file_handle};
}

1;
