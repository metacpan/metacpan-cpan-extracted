package SimpleMock;
use strict;
use warnings;
use SimpleMock::ScopeGuard;
use Exporter qw(import);
use Hash::Merge qw(merge);
use Carp qw(carp);

use SimpleMock::Util qw(
    all_file_subs
    generate_args_sha
    namespace_from_file
);

our @EXPORT_OK = qw(
    register_mocks
    register_mocks_scoped
    clear_mocks
);

our $VERSION = '0.04';

# mocks get stored in a stack, with globals as the first element
our @MOCK_STACK = ( {} );

# enable this env var to troubleshoot
sub _debug {
    my $message = shift;
    $ENV{DEBUG_SIMPLEMOCK} and carp "DEBUG: $message";
}

# "globals"
sub register_mocks {
    my %mocks_data = @_;
    _register_into_layer($MOCK_STACK[0], \%mocks_data);
}

# pushes a new layer, registers into it, returns a guard
sub register_mocks_scoped {
    my %mocks_data = @_;
    my $layer = {};
    push @MOCK_STACK, $layer;
    _register_into_layer($layer, \%mocks_data);
    return SimpleMock::ScopeGuard->new($layer);
}

sub _register_into_layer {
    my ($layer, $mocks_data) = @_;
    foreach my $model (keys %$mocks_data) {
        $model =~ /^[A-Z_]+$/ or die "Mock model class must be ALL_CAPS and underscores only! ($model)";
        my $model_ns = "SimpleMock::Model::$model";

        # load model NS if needed — convert Foo::Bar to Foo/Bar.pm for block eval
        (my $model_file = $model_ns) =~ s{::}{/}g;
        $model_file .= '.pm';
        eval { require $model_file }; die $@ if $@;
        no strict 'refs'; ## no critic
        my $processed = "${model_ns}::validate_mocks"->($mocks_data->{$model});

        # merge INTO the layer reference in-place
        %$layer = %{ Hash::Merge::merge($processed, $layer) };
    }
}

sub _register_into_current_scope {
    my %mocks_data = @_;
    _register_into_layer($MOCK_STACK[-1], \%mocks_data);
}

sub _load_mocks_for {
    my $original_filename = shift;
     _debug("_load_mocks_for($original_filename)");
    # Skip if the file is a SimpleMock file
    return if $original_filename =~ /^SimpleMock\b/;

    my $mock_filename = "SimpleMock/Mocks/$original_filename";
    eval {
        require $mock_filename;
    };
    if ($@) {
        # mock doesn't exist — match only the file-not-found form so that
        # "Can't locate object method" dies inside the mock file still surface
        $@ =~ /\ACan't locate \S+ in \@INC/ and return;
        # mock is borked
        die "Error loading $mock_filename: $@";
    }
    _debug("Loaded mocks for $original_filename ($mock_filename)");

    # map any method that exists in the mock over to the original
    # as a default mock
    my @module_subs = all_file_subs($original_filename);
    my $mock_ns = namespace_from_file($mock_filename);
    my $original_ns = namespace_from_file($original_filename);

    my $default_sub_mocks;
    foreach my $sub_name (@module_subs) {
        $sub_name =~ s/.*:://;
        my $mock_sub = $mock_ns.'::'.$sub_name;
        no strict 'refs'; ## no critic
        if (defined &{$mock_sub}) {
            _debug("Mapping mock sub $mock_sub to original sub ${original_ns}::$sub_name");
            $default_sub_mocks->{$original_ns}->{$sub_name} = [ { returns => \&{$mock_sub} } ];
        }
    }
    register_mocks(SUBS => $default_sub_mocks) if $default_sub_mocks;
}

sub clear_mocks {
    my @classes = @_;
    if (@classes) {
        delete $MOCK_STACK[0]->{$_} for (@classes);
    }
    else {
        %{$MOCK_STACK[0]} = ();
    }
}

# override "require" to trigger loading of mocks
BEGIN {
    our %processed;
    *CORE::GLOBAL::require = sub {
        my $filename = shift;

        # special cases (not module loads)
        return CORE::require($filename)
            if ($filename !~ /[A-Za-z]/ || $filename =~ /\.pl$/);

        # if namespace, switch to file name
        unless ($filename =~ /\.pm$/) {
            $filename =~ s|::|/|g;
            $filename .= '.pm';
        }

        # only load if not already processed
        unless ($processed{$filename}) {
            $processed{$filename}=1;
            eval { CORE::require($filename) };
            $@ and _debug("Can't require file $filename: $@");
            _load_mocks_for($filename);
        }
        return $INC{$filename} || 1;
    };
}

1;

=head1 NAME

SimpleMock - A simple mocking framework for Perl

=head1 SYNOPSIS

    use SimpleMock qw(register_mocks);

    # register mocks for a model
    register_mocks(
        SUBS => {
            'MyModule' => {
                'my_method' => [
                    { returns => sub { return 42 } },
                ],
            },
        },
        DBI => {
            QUERIES => [
                ...
            ],
        },
        LWP_UA => {
            ...
        },
    );

    {
        my $scope_guard = register_mocks_scoped(...);
        # tests here will use the scoped mocks
    }
    # scoped mocks are destroyed and previously overwritten mocks are restored

=head1 DESCRIPTION

SimpleMock is a simple, extendable mocking framework for Perl. The
following models are supported by default:

=over 4

=item * SUBS - for mocking subroutine calls

=item * DBI - for mocking DBI code

=item * LWP_UA - for mocking LWP::UserAgent code

=item * PATH_TINY - for mocking Path::Tiny code

=back

See documentation in each SimpleMock::Model::* namespace for details of
the mock data formats.

Other models can easily be added via the SimpleMock::Model namespace. If
you add mocks that are for a commonly used module, please consider submitting
a pull request so that others can use them.

Currently, there is no versioning of the mocks, so you should
ensure that the mocks you use are compatible with the version of the
module you are mocking. If there is a good reason to version the mocks,
I have architected it, but not implemented. I am happy to add it but
have yet to hit a use case in production code to justify it.

=head2 DEFINING MOCKS

Mocks can be defined via:

=over 4

=item * defined sub in SimpleMock::Mocks modules

=item * calls to register_mocks in SimpleMock::Mocks modules

=item * calls to register_mocks in your test code

=item * calls to register_mocks_scoped in blocks in your tests

=back

=head1 GETTING STARTED

Look at each of the model modules to see how to define each mock type:

    perldoc SimpleMock::Model::SUBS
    perldoc SimpleMock::Model::DBI
    perldoc SimpleMock::Model::LWP_UA
    perldoc SimpleMock::Model::PATH_TINY

The SUBS model also goes over the various ways you can define mocks.

In calls to C<register_mocks> and C<register_mocks_scoped> the arg sent
is a hash where the keys are the model we are mocking, ie:

    register_mocks(
        SUBS      => { ... },
        DBI       => { ... },
        LWP_UA    => { ... },
        PATH_TINY => { ... },
    );

=head1 ARCHITECTURE

  +------------------+
  |    Test Code     |
  +------------------+
           |
           | register_mocks( MODEL => { ... } )
           | register_mocks_scoped( MODEL => { ... } )
           | clear_mocks()
           v
  +------------------+     +-------------------------------------------+
  |   SimpleMock.pm  |---->|            @MOCK_STACK                    |
  |                  |     | +---------------------------------------+ |
  |  require override|     | | Layer 2 (inner scope)  <- searched 1st| |
  |  _load_mocks_for |     | +---------------------------------------+ |
  |                  |     | | Layer 1 (outer scope)  <- searched 2nd| |
  +------------------+     | +---------------------------------------+ |
                           | | Layer 0 (global base)  <- searched 3rd| |
                           | +---------------------------------------+ |
                           +-------------------------------------------+
                                            |
              +-----------------------------+--------------------+
              |              |              |                    |
              v              v              v                    v
     +-----------+   +-----------+   +-------------+   +-------------+
     |Model::SUBS|   |Model::DBI |   |Model::LWP_UA|   |Model::PATH_ |
     |           |   |           |   |             |   |  TINY       |
     |validate_  |   |validate_  |   |validate_    |   |validate_    |
     |  mocks()  |   |  mocks()  |   |  mocks()    |   |  mocks()    |
     +-----------+   +-----------+   +-------------+   +-------------+
          |               |               |                  |
          v               v               v                  v
     +-----------+   +-----------+   +------------+   +-------------+
     |Mocks::*   |   |Mocks::DBI |   |Mocks::LWP::|   |Mocks::Path::|
     |(auto-load)|   |           |   | UserAgent  |   |  Tiny       |
     |           |   |overrides  |   |overrides   |   |overrides    |
     |delegation |   |DBI::      |   |LWP::User   |   |Path::Tiny   |
     |wrappers   |   | connect   |   | Agent::new |   | methods     |
     +-----------+   +-----------+   +------------+   +-------------+
                          |
                          v
                     +-----------+
                     |DBD::      |
                     |SimpleMock |
                     | (driver)  |
                     +-----------+

  Flow:
    use SimpleMock  ->  installs CORE::GLOBAL::require override
    use MyModule    ->  override loads SimpleMock::Mocks::MyModule
                        (if it exists), auto-registers matching subs
    register_mocks  ->  Model::*::validate_mocks() normalises data,
                        merges into Layer 0
    scoped mocks    ->  push new layer, ScopeGuard::DESTROY pops it
    mock lookup     ->  traverse stack top-to-bottom, first match wins

=head1 METHODS

=head2 register_mocks

It takes a hash of model mocks where the top level keys refer to the model
namespace under SimpleMock::Model and the values define the actual mocks.
Different mocks can have different formats - eg, SUBS have namespaces with
methods, DBI has a hash of queries and a hash of meta flags.

    use SimpleMock qw(register_mocks);

    register_mocks(
        SUBS => {
            'MyModel' => {
                'my_method' => [
                    { returns => sub { return 42 } },
                ],
            },
        },
        DBI => {
            QUERIES => [
                {
                    sql => 'SELECT name, email FROM user where name like=?',
                    results => [
                        # data is an arrayref of arrayrefs of results
                        { args => [ 'C%' ], data => $d1 },
                        # if you set a result with no args, it will be used as the default
                        { data => $d2 },
                    ],
                },
                {
                    sql => 'SELECT id, name, email FROM member WHERE name like=?',
                    # cols is only needed if using selectall_hashref etc
                    cols => [ 'id', 'name', 'email' ],
                    results => [
                        { args => [ 'C%' ], data => $d3 },
                        { args => [ 'D%' ], data => $d4 },
                    ],
                },
            ],
        },
    );

=head2 register_mocks_scoped

As above, but the mocks will go out of scope at the end of the current block.

A scope guard is returned, and a DESTROY block on this object removes the scoped
mocks as appropriate.

Note: the underlying original method is not restored when a scoped mock is
deleted. The use case would be to temporarily change a global mock just for a specific
test without having to put it in a separate file. No error is explicitly thrown for
scoped mocks that do not have an underlying global mock.

    use SimpleMock qw(register_mocks register_mocks_scoped);

    # set global mocks
    register_mocks(...);

    {
        # set scoped mocks
        my $scope_guard = register_mocks_scoped(...);
        # scope registered mocks are available
    }
    # scope registered mocks are no longer available

=head2 clear_mocks

Clears registered mocks from the base layer. Pass one or more model names to
clear only those models, or call with no arguments to clear everything.

    use SimpleMock qw(clear_mocks);

    clear_mocks('DBI');        # clear only DBI mocks
    clear_mocks('DBI', 'LWP_UA'); # clear DBI and LWP_UA mocks
    clear_mocks();             # clear all mocks

Note: clearing mocks does not restore the original subroutine implementations
for SUBS mocks. The delegation wrappers remain in place, and calling a cleared
mock sub will die with "No mock found".

=head1 BUGS AND LIMITATIONS

I have a feeling this doesn't work well with some XS modules, nor with any modules that
override the CORE require, but I haven't tested heavily in that direction.

=head1 REPOSITORY

L<https://github.com/cliveholloway/perl_simplemock>

Pull requests to add common modules to the framework are welcomed!

=head1 AUTHOR

Clive Holloway <clive.holloway@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025-2026 by Clive Holloway.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

