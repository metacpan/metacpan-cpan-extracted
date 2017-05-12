package Package::Butcher;

use warnings;
use strict;

use Package::Butcher::Inflator;
use Carp ();

use constant VALID_PACKAGE_RE => qr/^\w+(?:::\w+)*$/;
use constant VALID_SUBROUTINE_RE  => qr/^[_[:alpha:]][[:word:]]*$/;

our $VERSION = '0.02';

sub new {
    my ( $class, $arg_for ) = @_;
    my $self = bless {} => $class;
    return $self->_initialize($arg_for);
}

sub _initialize {
    my ( $self, $arg_for ) = @_;
    my %default_for = (
        package           => delete $arg_for->{package},
        import_on_use     => delete $arg_for->{import_on_use},
        is_package_loaded => 0,
        subs_installed    => {},
    );
    foreach my $method ( keys %default_for ) {
        $self->{$method} = $default_for{$method};
        no strict 'refs';
        *$method = sub { $_[0]->{$method} };
    }
    $self->_do_not_load( delete $arg_for->{do_not_load} );
    # _sub() must be called before _predeclare
    $self->_subs( delete $arg_for->{subs} );
    $self->_predeclare( delete $arg_for->{predeclare} );
    $self->_method_chains( delete $arg_for->{method_chains} );

    return $self;
}

sub _is_package_loaded { $_[0]->{is_package_loaded} = $_[1] }

sub _assert_looks_like_package {
    my ( $proto, $package ) = @_;
    unless ( $package =~ VALID_PACKAGE_RE ) {
        Carp::confess(
            "'$package' does not look like a valid package name to me");
    }
}

sub _assert_looks_like_subroutine {
    my ( $proto, $subroutine ) = @_;
    unless ( $subroutine =~ VALID_SUBROUTINE_RE ) {
        Carp::confess("'$subroutine' does not look like a valid subroutine name to me");
    }        
}

sub _do_not_load {
    my ( $self, $packages ) = @_;
    return unless $packages;
    $packages = [$packages] unless 'ARRAY' eq ref $packages;
    foreach my $package (@$packages) {
        $self->_assert_looks_like_package($package);
        my $file = "$package.pm";
        $file =~ s{::}{/}g;
        my $butcher = ref $self;
        my $message = "loaded via '$butcher'";
        if ( $INC{$file} && $INC{$file} ne $message ) {
            Carp::cluck("'$package' already loaded via '$INC{$file}'");
        }
        else {
            $INC{$file} = $message;

            # This ensures that "use Foo 'bar'" won't generate "package Foo
            # doesn't export bar" errors
            no strict 'refs';
            *{"${package}::import"} = sub {};
        }
    }
}

sub _subs {
    my ( $self, $subs ) = @_;
    return unless $subs;
    my $subs_installed = $self->subs_installed;
    foreach my $sub (keys %$subs) {
        $self->_assert_looks_like_subroutine($sub);
        if (exists $subs_installed->{$sub} ) {
            Carp::confess("Cannot install a subroutine already installed: '$sub'");
        }
        my $code = $subs->{$sub};
        unless ( 'CODE' eq ref $code ) {
            Carp::confess("The value for '$sub' must be a subroutine reference");
        }
        $subs_installed->{$sub} = $code;
    }
}

sub _method_chains {
    my ( $self, $chains ) = @_;
    return unless $chains;
    foreach my $chain (@$chains) {
        my ( $class_to_override, @methods ) = @$chain;
        my $code = pop @methods;

        unless (@methods) {
            Carp::confess("Must have at least one method name to call on $class_to_override");
        }
        unless ( 'CODE' eq ref $code ) {
            Carp::confess("Final argument to install_method_chain must be a coderef");
        }

        $self->_assert_looks_like_package($class_to_override);
        $self->_assert_looks_like_subroutine($_) foreach @methods;

        my $first   = shift @methods;
        my $inflate = $code;
        while ( my $method = pop @methods ) {
            $inflate = { $method => $inflate };
        }
        {
            no strict 'refs';
            *{"${class_to_override}::$first"} = sub {
                  Package::Butcher::Inflator->new($inflate);
            };
        }
    }
    return;
}

sub _uniq {
    my %seen = ();
    grep { not $seen{$_}++ } @_;
}

sub _predeclare {
    my ( $self, $subs ) = @_;
    return unless $subs;
    $subs = [$subs] unless 'ARRAY' eq ref $subs;
    my $installed = $self->subs_installed;

    # we have to predeclare subs we're installing lest we hit subtle parsing
    # issues where Perl thinks they're indirect method calls. See 'perldoc
    # perlobj' for more information. Thanks for Flavio for spotting this
    # issue.
    @$subs = _uniq(@$subs, keys %$installed);
    my $package = $self->package;
    my $forward_declarations = join '' => map { "sub $_;" } @$subs;
    eval "package $package; $forward_declarations";
    Carp::confess($@) if $@;
}

sub use {
    my ( $self, @import ) = @_;
    $self->_load( 'use', @import );
}

sub require {
    my ($self) = @_;
    if ( @_ > 1 ) {
        Carp::confess("require() does not take arguments");
    }
    $self->_load('require');
}

sub _load {
    my ( $self, $use_or_require, @import ) = @_;

    my $package = $self->package;
    if ( my $loaded = $self->is_package_loaded ) {
        Carp::confess("You have already loaded '$package' via '$loaded'");
    }

    my $caller = caller(1);

    my $import = '';
    if (@import) {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $import = join ', ' => Data::Dumper::Dumper(@import);
    }

    my $import_list = $self->import_on_use ? $import : '()';
    eval <<"    USE";
    package $caller;
    $use_or_require $package $import_list;
    USE
    Carp::confess($@) if $@;

    my $to_install = $self->subs_installed;
    foreach my $sub (keys %$to_install) {
        # XXX we were going to do nifty checks to see if you could 'install'
        # or 'replace' a sub, but merely the existance of
        # Some::Package::subname() in another package would create the stash
        # slot. We're taking the easy way out.
        # my $stash = do { no strict 'refs'; \%{"${package}::"} };
        # if (exists $stash->{$sub} ) {}
        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::$sub"} = $to_install->{$sub};
    }

    unless ( $self->import_on_use ) {
        eval <<"        IMPORT";
        package $caller;
        $package->import($import);
        IMPORT
        Carp::confess($@) if $@;
    }

    $self->_is_package_loaded($use_or_require);
}

1;

__END__

=head1 NAME

Package::Butcher - When you absolutely B<have> to load that damned package.

=head1 ALPHA CODE

You've been warned. It also has an embarrassingly poor test suite. It was
hacked together in an emergency while sitting in a hospital waiting for my
daughter to be born. Sue me.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    my $butcher = Package::Butcher->new(
        {
            package     => 'Dummy',
            do_not_load => [qw/Cannot::Load Cannot::Load2 NoSuch::List::MoreUtils/],
            predeclare  => 'uniq',
            subs => {
                this     => sub { 7 },
                that     => sub { 3 },
                existing => sub { 'replaced existing' },
            },
            method_chains => [
                [
                    'Cannot::Load' => qw/foo bar baz this that/ => sub {
                        my $args = join ', ' => @_;
                        return "end chain: $args";
                    },
                ],
            ],
        }
    );
    $butcher->use(@optional_import_list);

=head1 DESCRIPTION

Sometimes you need to load a module which won't otherwise load. Unit testing
is a good reason. Unfortunately, some modules are just very, very difficult to
load. This module is a nasty hack with a name designed to make this clear.
It's here to provide a standard set of tools to let you load these problem
modules.

=head1 USAGE

To use this module, let's consider the following awful module:

    package Dummy;

    use strict;
    use Cannot::Load;
    use NoSuch::List::MoreUtils 'uniq';
    use DBI;

    use base 'Exporter';
    our @EXPORT_OK = qw(existing);

    sub existing { 'should never see this' }

    # this strange construct forces a syntax error
    sub filter {
        uniq map {lc} split /\W+/, shift;
    }

    sub employees {
        my @connect =
          ( 'dbi:Pg:dbname=ourdb', '', '', { AutoCommit => 0 } );
        return DBI->connect(@connect)
          ->selectall_arrayref(
            'SELECT id, name, position FROM employees ORDER BY id');
    }

    sub recipes {
        my @connect = ( 'dbi:Pg:dbname=ourdb', '', '', { AutoCommit => 0 } );
        return DBI->connect(@connect)
          ->selectall_arrayref('SELECT id, name FROM recipes');
    } 

    1;

You probably cannot load this. You don't have C<Cannot::Load> or
C<NoSuch::List::MoreUtils> available. What's worse, even if you try to stub
them out and fake this, the C<employees> and C<recipes>  methods might be
frustrating.  We'll use this as an example of how to use C<Package::Butcher>.

=head1 METHODS

=head2 C<new>

The constructor for C<Package::Butcher> takes a hashref with several allowed
keys. For example, the following will allow the C<Dummy> package above to
load:

    my $dummy = Package::Butcher->new({
        package => 'Dummy',
        do_not_load =>
          [qw/Cannot::Load NoSuch::List::MoreUtils DBI/],
        predeclare => 'uniq',
        subs       => {
            existing       => sub { 'replaced existing' },
            reverse_string => sub {
                my $arg = shift;
                return scalar reverse $arg;
            },
        },
        method_chains => [
            [
                'Cannot::Load' => qw/foo bar baz this that/ => sub {
                    my $args = join ', ' => @_;
                    return "end chain: $args";
                },
            ],
            [
                'DBI' => qw/connect selectall_arrayref/ => sub {
                    my $sql = shift;
                    return (
                        $sql =~ /\brecipes\b/
                        ? [
                            [qw/1 bob secretary/], 
                            [qw/2 alice ceo/],
                            [qw/3 ovid idiot/],
                          ]
                        : [ [ 1, 'Tartiflette' ], [ 2, 'Eggs Benedict' ], ];
                 },
             ],
        ],
    });

Here are the allowed keys to the constructor:

=over 4

=item * C<package>

The name of the package to be butchered.

 package => 'Hard::To::Load::Package'

=item * C<do_not_load>

Packages which must not be loaded. This is useful when there are a bunch of
C<use> or C<require> statements in the code which cause the target code to try
and load packages which may not be loadable.

 do_not_load => [
    'Apache::Never::Loads',
    'Module::I::Do::Not::Have::Installed',
    'Win32::Anything',
 ]

=item * C<predeclare>

Sometimes you need to simply predeclare a method or subroutine to ensure it
parses correctly, even if you don't need to execute that function (for
example, if you're replacing a subroutine which contains the offending code).
To do this, you can simply "predeclare a function or arrayref of functions
with optional prototypes.

 predeclare => [ 'uniq (@)', 'some_other_function' ]

=item * C<subs>

This should point to a hashref of subroutine names and sub bodies. These will
be added to the package, overwriting any subroutines already there:

 subs => {
     existing       => sub { 'replaced existing' },
     reverse_string => sub {
         my $arg = shift;
         return scalar reverse $arg;
     },
 },

Note that any subroutinine listed in the C<subs> section will automatically be
predeclared.

=item * C<method_chains>

Method "chains" are frequent in bad code (and even in some good code). This is
when you see a class with a list of chained methods getting called. For
example:

 return DBI->connect(@connect)
   ->selectall_arrayref(
     'SELECT id, name, position FROM employees ORDER BY id');

The butcher allows you to declare a method chain and a subref which will be
executed. The structure is like this:

 method_chains => [
    [ $class1, @list_of_methods1, sub { @body } ],
    [ $class2, @list_of_methods2, sub { @body } ],
    [ $class3, @list_of_methods3, sub { @body } ],
 ],

For the DBI example above, assuming this was the only method chain in the
code, you would have something like:

 method_chains => [
    [ 'DBI', qw/connect selectall_arrayref/, \&some_sub ],
 ],

See C<Package::Butcher::Inflator> code to see how this works.

=item * C<import_on_use>

This defaults to false and you should hopefully not need it.

As a general rule, if you call C<< $butcher->use >>, the package's C<import>
method will be called I<after> you use the class to allow us to inject the new
code before importing. This means that if a class exports a 'foo' method and
you've replaced it with your own, you are generally guaranteed to get your
replacement when you call:

 $butcher->use('foo');

However, if you class requires that the C<import> method be called at the at
time the class is "use"d, then you can specify this in the constructor:

 import_on_use => 1,

=back

=head2 C<use>

 my $butcher = Package::Butcher->new({ package ... });
 $butcher->use(@import_list);

Once constructed, this method will "use" the package in question. You may pass
it the same import list that the package you're butchering takes. Note that if
you override C<import>, you're on your own.

=head2 C<require>

 my $butcher = Package::Butcher->new({ package ... });
 $butcher->require;

Like use, but does a C<require>.

=head1 AUTHOR

Curtis 'Ovid' Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-package-butcher at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Butcher>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Butcher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Butcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Butcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Butcher>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Butcher/>

=back

=head1 ACKNOWLEDGEMENTS

Flavio Glock for help with a parsing error.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Curtis 'Ovid' Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
