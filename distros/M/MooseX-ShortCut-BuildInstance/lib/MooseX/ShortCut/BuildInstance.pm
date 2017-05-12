package MooseX::ShortCut::BuildInstance;
our $AUTHORITY = 'cpan:JANDREW';
use version 0.77; our $VERSION = version->declare('v1.44.2');
#~ use lib '../../../../Log-Shiras/lib';
#~ use Log::Shiras::Unhide qw( :InternalBuilDInstancE );
###InternalBuilDInstancE	warn "You uncovered internal logging statements for MooseX::ShortCut::BuildInstance-$VERSION";
use 5.010;
use utf8;
use Moose 2.1213;
use Moose::Meta::Class;
use MooseX::Types::Moose qw( Bool HashRef );
use Carp qw( cluck confess );
use Moose::Util qw( apply_all_roles );
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
	as_is => [qw(
		build_instance				build_class					should_re_use_classes
		set_class_immutability		set_args_cloning
	)],
);
use Data::Dumper;
use Clone 'clone';
use lib	'../../../lib',;
use MooseX::ShortCut::BuildInstance::Types 1.036 qw(
		BuildClassDict
	);

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

our	$anonymous_class_count	= 0;
our	$built_classes			= {};
our	$re_use_classes 		= 0;
our	$make_classes_immutable = 1;
our	$should_clone_args		= 1;
my 	@init_class_args = qw(
		package
		superclasses
		roles
	);
my 	@add_class_args = qw(
		add_roles_in_sequence
		add_attributes
		add_methods
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub build_class{
	my	$temp_args = ( ( scalar( @_ ) == 1 ) ? $_[0] : { @_ } );
	my	$args = $should_clone_args ? clone( $temp_args ) : $temp_args;
	###InternalBuilDInstancE	warn "Arrived at build_class with args:" . Dumper( $args );
	my ( $class_args, $i, $can_build, $warning, @warn_list, $pre_exists );
	for my $key ( @init_class_args ){
		###InternalBuilDInstancE	warn "Processing the class argument: $key";
		if( exists $args->{$key} ){
			###InternalBuilDInstancE	warn 'Processing the values:' . Dumper( $args->{$key} );
			$class_args->{$key} = $args->{$key};
			if( $key eq 'package' ){
				if( $built_classes->{$args->{$key}} ){
					$pre_exists = 1;
					if( !$re_use_classes ){
						push @warn_list, 'You already built the class: ' . $args->{$key};
						$warning = 1;
						###InternalBuilDInstancE	warn "unmutablizing the class ..." . Dumper( @warn_list );
						$args->{$key}->meta->make_mutable;
					}
				}
				$built_classes->{$args->{$key}} = 1;
			}
			delete $args->{$key};
		}elsif( $key eq 'package' ){
			$class_args->{$key} = "ANONYMOUS_SHIRAS_MOOSE_CLASS_" . ++$anonymous_class_count;
			###InternalBuilDInstancE	warn "missing a package value - using: " . $class_args->{$key};
		}elsif( $key eq 'superclasses' ){
			$class_args->{$key} = [ 'Anonymous::Shiras::Moose::Class' ],
			###InternalBuilDInstancE	warn "missing the superclass value - using: " . Dumper( $class_args->{$key} );
		}
	}
	if( $warning ){
		push @warn_list, 'The old class definitions will be overwritten with args:', Dumper( $class_args );
		cluck( join( "\n", @warn_list ) );
	}else{
		my $package_key = $class_args->{package};
		$package_key =~ s/::/\//g;
		$package_key .= '.pm';
		if( exists $INC{$package_key} ){
			if( $re_use_classes ){
				###InternalBuilDInstancE	warn "Already built the class: $class_args->{package}";
				return $class_args->{package};# Don't rebuild if you are re-using
			}
			cluck "Overwriting a pre-built and loaded class: " . $class_args->{package} ;
			$class_args->{package}->meta->make_mutable;
		}
	}
	my $want_array = ( caller(0) )[5];
	###InternalBuilDInstancE	warn 'class args:' . Dumper( $class_args );
	###InternalBuilDInstancE	warn 'remaining arguments:' . Dumper( $args );
	###InternalBuilDInstancE	warn "want array: $want_array";
	###InternalBuilDInstancE	warn "Pre exists state: " . ($pre_exists//'');
	###InternalBuilDInstancE	warn "\$warning state: " . ($warning//'');
	###InternalBuilDInstancE	warn 'finalize the class name or load a new one ...';
	my	$class_name = ( $pre_exists and !$warning ) ?
			$class_args->{package} :
			Moose::Meta::Class->create( %{$class_args} )->name;
	###InternalBuilDInstancE	warn 'class to this point: ' . $class_name->dump( 2 );
	if( !$class_name->meta->is_mutable and
		(	exists $args->{add_attributes} or
			exists $args->{add_methods} or
			exists $args->{add_roles_in_sequence} ) ){
		###InternalBuilDInstancE	warn 'Un-immutablizing the class ...';
		$class_name->meta->make_mutable;
	}
	if( exists $args->{add_attributes} ){
		###InternalBuilDInstancE	warn "Found attributes to add";
		my	$meta = $class_name->meta;
		for my $attribute ( keys %{$args->{add_attributes}} ){
			###InternalBuilDInstancE	warn "adding attribute named: $attribute";
			$meta->add_attribute( $attribute => $args->{add_attributes}->{$attribute} );
		}
		delete $args->{add_attributes};
	}
	if( exists $args->{add_methods} ){
		###InternalBuilDInstancE	warn "Found roles to add";
		my	$meta = $class_name->meta;
		for my $method ( keys %{$args->{add_methods}} ){
			###InternalBuilDInstancE	warn "adding method named: $method";
			$meta->add_method( $method => $args->{add_methods}->{$method} );
		}
		delete $args->{add_methods};
	}
	if( exists $args->{add_roles_in_sequence} ){
		###InternalBuilDInstancE	warn "Found roles_in_sequence to add";
		for my $role ( @{$args->{add_roles_in_sequence}} ){
			###InternalBuilDInstancE	warn "adding role:" . Dumper( $role );
			apply_all_roles( $class_name, $role );
		}
		delete $args->{add_roles_in_sequence};
	}
	if( $make_classes_immutable ){
		###InternalBuilDInstancE	warn 'Immutablizing the class ...';
		$class_name->meta->make_immutable;
	}
	###InternalBuilDInstancE	warn "returning: $class_name";
	return $class_name;
}

sub build_instance{
	my	$temp_args = is_HashRef( $_[0] ) ? $_[0] : { @_ };
	my	$args = $should_clone_args ? clone( $temp_args ) : $temp_args;
	###InternalBuilDInstancE	warn "Arrived at build_instance with args:" . Dumper( $args );
	my	$class_args;
	for my $key ( @init_class_args, @add_class_args ){
		if( exists $args->{$key} ){
			$class_args->{$key} = $args->{$key};
			delete $args->{$key};
		}
	}
	###InternalBuilDInstancE	warn 'Reduced arguments:' . Dumper( $args );
	###InternalBuilDInstancE	warn 'Class building arguments:' . Dumper( $class_args );
	my $class = build_class( $class_args );
	###InternalBuilDInstancE	warn "Built class -$class- To get instance now applying args:" . Dumper( $args );
	my $instance;
	eval '$instance = $class->new( %$args )';
	if( $@ ){
		my $message = $@;
		if( ref $message ){
			if( $message->can( 'as_string' ) ){
				$message = $message->as_string;
			}elsif( $message->can( 'message' ) ){
				$message = $message->message;
			}
		}
		$message =~ s/\)\n;/\);/g;
		cluck $message;
	}else{
		###InternalBuilDInstancE	warn "Built instance:" . Dumper( $instance );
		return $instance;
	}
}

sub should_re_use_classes{
	my ( $bool, ) = @_;
	###InternalBuilDInstancE	warn "setting \$re_use_classes to: $bool";
	$re_use_classes = ( $bool ) ? 1 : 0 ;
}

sub set_class_immutability{
	my ( $bool, ) = @_;
	###InternalBuilDInstancE	warn "setting \$make_immutable_classes to; $bool";
	$make_classes_immutable = ( $bool ) ? 1 : 0 ;
}

sub set_args_cloning{
	my ( $bool, ) = @_;
	$should_clone_args = !!$bool;
	###InternalBuilDInstancE	warn "set \$should_clone_args to; $should_clone_args";
}

#########1 Phinish strong     3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

#########1 Default class      3#########4#########5#########6#########7#########8#########9
package Anonymous::Shiras::Moose::Class;
our $AUTHORITY = 'cpan:JANDREW';
use	Moose;
no	Moose;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

MooseX::ShortCut::BuildInstance - A shortcut to build Moose instances

=begin html

<a href="https://www.perl.org">
	<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="perl version">
</a>

<a href="https://travis-ci.org/jandrew/MooseX-ShortCut-BuildInstance">
	<img alt="Build Status" src="https://travis-ci.org/jandrew/MooseX-ShortCut-BuildInstance.png?branch=master" alt='Travis Build'/>
</a>

<a href='https://coveralls.io/github/jandrew/MooseX-ShortCut-BuildInstance?branch=master'>
	<img src='https://coveralls.io/repos/github/jandrew/MooseX-ShortCut-BuildInstance/badge.svg?branch=master' alt='Coverage Status' />
</a>

<a href='https://github.com/jandrew/MooseX-ShortCut-BuildInstance'>
	<img src="https://img.shields.io/github/tag/jandrew/MooseX-ShortCut-BuildInstance.svg?label=github version" alt="github version"/>
</a>

<a href="https://metacpan.org/pod/MooseX::ShortCut::BuildInstance">
	<img src="https://badge.fury.io/pl/MooseX-ShortCut-BuildInstance.svg?label=cpan version" alt="CPAN version" height="20">
</a>

<a href='http://cpants.cpanauthors.org/dist/MooseX-ShortCut-BuildInstance'>
	<img src='http://cpants.cpanauthors.org/dist/MooseX-ShortCut-BuildInstance.png' alt='kwalitee' height="20"/>
</a>

=end html

=head1 SYNOPSIS

	#!/user/bin/env perl
	package Mineral;
	use Moose;
	use Types::Standard qw( Enum );

	has 'type' =>(
			isa => Enum[qw( Quartz Diamond Basalt Granite )],
			is => 'ro'
		);

	package Identity;
	use Moose::Role;

	has 'name' =>( is => 'ro' );

	use lib '../../../lib';
	use MooseX::ShortCut::BuildInstance qw( should_re_use_classes build_instance );
	should_re_use_classes( 1 );# To reuse build_instance
	use Test::More;
	use Test::Moose;

	# First build of instance
	my 	$paco = build_instance(
			package => 'Pet::Rock',
			superclasses =>['Mineral'],
			roles =>['Identity'],
			type => 'Quartz',
			name => 'Paco',
		);

	does_ok( $paco, 'Identity', 'Check that the ' . $paco->meta->name . ' has an -Identity-' );
	print'My ' . $paco->meta->name . ' made from -' . $paco->type . '- (a ' .
	( join ', ', $paco->meta->superclasses ) . ') is called -' . $paco->name . "-\n";

	# Next instance (If you don't want to call build_instance again)
	my $Fransisco = Pet::Rock->new(
		type => 'Diamond',
		name => 'Fransisco',
	);
	does_ok( $Fransisco, 'Identity', 'Check that the ' . $Fransisco->meta->name . ' has an -Identity-' );
	print'My ' . $Fransisco->meta->name . ' made from -' . $Fransisco->type . '- (a ' .
	( join ', ', $Fransisco->meta->superclasses ) . ') is called -' . $Fransisco->name . "-\n";

	# Another instance (reusing build_instance)
	my $Gonzalo = build_instance(
			package => 'Pet::Rock',
			superclasses =>['Mineral'],
			roles =>['Identity'],
			type => 'Granite',
			name => 'Gonzalo',
		);
	does_ok( $Gonzalo, 'Identity', 'Check that the ' . $Gonzalo->meta->name . ' has an -Identity-' );
	print'My ' . $Gonzalo->meta->name . ' made from -' . $Gonzalo->type . '- (a ' .
	( join ', ', $Gonzalo->meta->superclasses ) . ') is called -' . $Gonzalo->name . "-\n";
	done_testing();

    ##############################################################################
    # Output of SYNOPSIS
    # 01:ok 1 - Check that the Pet::Rock has an -Identity-
    # 02:My Pet::Rock made from -Quartz- (a Mineral) is called -Paco-
    # 01:ok 1 - Check that the Pet::Rock has an -Identity-
    # 02:My Pet::Rock made from -Diamond- (a Mineral) is called -Fransisco-
    # 01:ok 1 - Check that the Pet::Rock has an -Identity-
    # 02:My Pet::Rock made from -Granite- (a Mineral) is called -Gonzalo-
    # 03:1..3
    ##############################################################################

=head1 DESCRIPTION

This module is a shortcut to custom build L<Moose> class instances on the fly.
The goal is to compose unique instances of Moose classes on the fly using a single
function call with information describing required attributes, methods, inherited
classes, and roles as well as any desired instance settings.  This package will
check for and fill in any missing pieces as needed so that your call can either be
complex or very simple.  The goal is to provide configurable instance building
without stringing together a series of Class-E<gt>method( %args ) calls.

The package can also be used as a class factory with the L<should_re_use_classes
|/$MooseX::ShortCut::BuildInstance::re_use_classes> method.

Even though this is a Moose based class it provides a functional interface.

=head1 WARNING(S)

Moose (and I think perl 5) can't have two classes with the same name but
different guts coexisting! This means that if you build a class (package) name
on the fly while building an instance and then recompose a new class (package) with
the same name but different functionality (different attributes, methods, inherited
classes or roles) while composing a new instance on the fly then all calls
to the old instance will use the new class functionality for execution. (Usually
causing hard to troubleshoot failures).  This is also true if you re-build a
prebuilt class name inititally installed with 'use'.

MooseX::ShortCut::BuildInstance will warn if you overwrite named classes (packages)
built on top of another class (package) also built by MooseX::ShortCut::BuildInstance.
If you are using the 'build_instance' method to generate multiple instances of
the same class (by 'package' name) with different attribute settings but built
with the same functionality then you need to understand the purpose of the
L<$re_use_classes|/$MooseX::ShortCut::BuildInstance::re_use_classes> global variable.
An alternative to multiple calls straight to 'build_instance' is to call
L<build_class|/build_class( %args|\%args )> separately and then just call -E<gt>new
against the resulting class name over and over again.  Another alternative is to
leave the 'package' argument out of 'build_instance' and let this class create a
unique by-instance anonymous class/package name.

MooseX::ShortCut::BuildInstance will also warn (but not stop you) if you try to
overwrite a pre-loaded package initially installed with 'use' or 'require'.

The Types module in this package uses L<Type::Tiny> which can, in the
background, use L<Type::Tiny::XS>.  While in general this is a good thing you will
need to make sure that Type::Tiny::XS is version 0.010 or newer since the older
ones didn't support the 'Optional' method.

This package will clone the passed arguments to L<build_class|/build_class> and
L<build_instance|/build_instance> since the references are destructivly parsed.
If that is not what you want then use the method L<set_args_cloning
|/set_args_cloning( $bool )> to manage the desired process.  Where this is likley
to go south is if your passed arguments contain a deep perl data set or reference
that you want shared.  In this case clone only the bits you want cloned on the
script side.

=head1 Functions for Export

=head2 build_instance( %args|\%args )

=over

B<Definition:> This method is used to create a Moose instance on the fly.
I<It assumes that you do not have the class pre-built and will look for the
needed information to compose a new class as well.>  Basically this passes the
%args intact to L<build_class|/build_class( %args|\%args )> first.  All the
relevant class building pieces will be used and removed from the args and then
this method will run $returned_class_name->new( %remaining_args ) with what is
left.

B<Accepts:> a hash or hashref of arguments.  They must include the
necessary information to build a class.  I<(if you already have a class just
call $class-E<gt>new( %args ); instead of this method!)> This hashref can also
contain any attribute settings for the instance as well.  See
L<build_class|/build_class( %args|\%args )> for more information.

B<Returns:> This will return a blessed instance of your new class with
the passed attribute settings implemented.

=back

=head2 build_class( %args|\%args )

=over

B<Definition:> This function is used to compose a Moose class on the fly.  The
the goal is to allow for as much or as little class definition as you want to be
provided by one function call.  The goal is also to remove as much of the boilerplate
and logic sequences for class building as possible and let this package handle that.
The function begins by using the L<Moose::Meta::Class>-E<gt>class(%args) method.
For this part the function specifically uses the argument callouts 'package',
'superclasses', and 'roles'.  Any necessary missing pieces will be provided. I<Even
though L<Moose::Meta::Class>-E<gt>class(%args) allows for the package name to be called
as the first element of an odd numbered list this implementation does not.  To define
a 'package' name it must be set as the value of the 'package' key in the %args.>
This function then takes the following arguements; 'add_attributes', 'add_methods',
and 'add_roles_in_sequence' and implements them in that order.   The
implementation of these values is done with L<Moose::Util> 'apply_all_roles'
and the meta capability in L<Moose>.

B<Accepts:> a hash or hashref of arguments.  Six keys are stripped from the hash or
hash ref of arguments.  I<These keys are always used to build the class.  They are
never passed on to %remaining_args.>

=over

B<The first three key-E<gt>value pairs are consumed simultaneously>.  They are;

=over

B<package:> This is the name (a string) that the new instance of
a this class is blessed under.  If this key is not provided the package
will generate a generic name.  This will L<overwrite|/WARNING> any class
built earlier with the same name.

=over

B<accepts:> a string

=back

B<superclasses:> this is intentionally the same key from
Moose::Meta::Class-E<gt>create.

=over

B<accepts:> a recognizable (by Moose) class name

=back

B<roles:> this is intentionally the same key from Moose::Meta::Class
-E<gt>create.

=over

B<accepts:> a recognizable (by Moose) class name

=back

=back

B<The second three key-E<gt>value pairs are consumed in the following
sequence>.  They are;

=over

B<add_attributes:> this will add attributes to the class using the
L<Moose::Meta::Class>-E<gt>add_attribute method.  Because these definitions
are passed as key / value pairs in a hash ref they are not added in
any specific order.

=over

B<accepts:> a hash ref where the keys are attribute names and the values
are hash refs of the normal definitions used to define a Moose attribute.

=back


B<add_methods:>  this will add methods to the class using the
L<Moose::Meta::Class>-E<gt>add_method method.  Because these definitions
are passed as key / value pairs in a hash ref they are not added in
any specific order.

=over

B<accepts:> a hash ref where the keys are method names and the values
are anonymous subroutines or subroutine references.

=back

B<add_roles_in_sequence:> this will compose, in sequence, each role in
the array ref into the class built on the prior three arguments using
L<Moose::Util> apply_all_roles.  This will allow an added role to
'require' elements of a role earlier in the sequence.  The roles
implemented with the L<role|/roles:> key are installed first and in a
group. Then these roles are installed one at a time.

=over

B<accepts:> an array ref list of roles recognizable (by Moose) as roles

=back

=back

=back

B<Returns:> This will check the caller and see if it wants an array or a
scalar.  In array context it returns the new class name and a hash ref of the
unused hash key/value pairs.  These are presumably the arguments for the
instance.  If the requested return is a scalar it just returns the name of
the newly created class.

=back

=head2 should_re_use_classes( $bool )

=over

This sets/changes the global variable
L<MooseX::ShortCut::BuildInstance::re_use_classes
|/$MooseX::ShortCut::BuildInstance::re_use_classes>

=back

=head2 set_class_immutability( $bool )

=over

This sets/changes the global variable
L<MooseX::ShortCut::BuildInstance::make_classes_immutable
|/$MooseX::ShortCut::BuildInstance::make_classes_immutable>

=back

=head2 set_args_cloning( $bool )

=over

This sets/changes the global variable
L<MooseX::ShortCut::BuildInstance::should_clone_args
|/$MooseX::ShortCut::BuildInstance::should_clone_args>

=back

=head1 GLOBAL VARIABLES

=head2 $MooseX::ShortCut::BuildInstance::anonymous_class_count

This is an integer that increments and appends to the anonymous package name
for each new anonymous package (class) created.

=head2 $MooseX::ShortCut::BuildInstance::built_classes

This is a hashref that tracks the class names ('package's) built buy this class
to manage duplicate build behaviour.

=head2 $MooseX::ShortCut::BuildInstance::re_use_classes

This is a boolean (1|0) variable that tracks if the class should overwrite or
re-use a package name (and the defined class) from a prior 'build_class' call.
If the package name is overwritten it will L<cluck|https://metacpan.org/pod/Carp#SYNOPSIS>
in warning since any changes will affect active instances of prior class builds
with the same name.  If you wish to avoid changing old built behaviour at the risk
of not installing new behaviour then set this variable to true.  I<No warning will
be provided if new requested class behaviour is discarded.> The class reuse behaviour
can be changed with the exported method L<should_re_use_classes
|/should_re_use_classes( $bool )>.  This does not apply to pre-loaded classes.
For pre-loaded classes this package will cluck and then overwrite every time.

=over

B<Default:> False = warn then overwrite

=back

=head2 $MooseX::ShortCut::BuildInstance::make_classes_immutable

This is a boolean (1|0) variable that manages whether a class is immutabilized at the end of
creation.  This can be changed with the exported method L<set_class_immutability
|/set_class_immutability( $bool )>.

=over

B<Default:> True = always immutabilize classes after building

=back

=head2 $MooseX::ShortCut::BuildInstance::should_clone_args

This is a boolean (1|0) variable that manages whether a the arguments passed to
L<build_instance|/build_instance( %argsE<verbar>\%args )> and L<build_class
|/build_class( %argsE<verbar>\%args )> are cloned (using L<Clone> )  the arguments
to both of these are processed destructivly so generally you would want them cloned
but not in every case.  If you want cloning to be managed on the script side set this
global variable to 0.  Where this is likley to be helpful is if your passed arguments
contain a deep perl data set or reference that you want shared.  In this case clone only
the bits you want cloned on the script side.

=over

B<Default:> True = always clone arguments

=back

=head1 Build/Install from Source

=over

B<1.> Download a compressed file with the code

B<2.> Extract the code from the compressed file.

=over

If you are using tar this should work:

	tar -zxvf Spreadsheet-XLSX-Reader-LibXML-v0.xx.tar.gz

=back

B<3.> Change (cd) into the extracted directory

B<4.> Run the following

=over

(For Windows find what version of make was used to compile your perl)

	perl  -V:make

(for Windows below substitute the correct make function (s/make/dmake/g)?)

=back

	>perl Makefile.PL

	>make

	>make test

	>make install # As sudo/root

	>make clean

=back

=head1 SUPPORT

=over

L<MooseX-ShortCut-BuildInstance/issues|https://github.com/jandrew/MooseX-ShortCut-BuildInstance/issues>

=back

=head1 TODO

=over

B<1.> L<Increase test coverage
|https://coveralls.io/github/jandrew/MooseX-ShortCut-BuildInstance?branch=master>

B<2.> Add an explicit 'export' setup call using L<Moose::Exporter> as an action key in 
'build_class'

=back

=head1 AUTHOR

=over

Jed Lund

jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2012, 2016 by Jed Lund

=head1 Dependencies

=over

L<version>

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<Moose>

L<Moose::Meta::Class>

L<Carp> - cluck

L<Moose::Exporter>

L<Moose::Util> - apply_all_roles

L<Moose::Exporter>

L<Type::Tiny> - 1.000

L<Data::Dumper>

L<MooseX::ShortCut::BuildInstance::Types>

=back

=head1 SEE ALSO

=over

L<Moose::Meta::Class> ->create

L<Moose::Util> ->with_traits

L<MooseX::ClassCompositor>

L<Log::Shiras::Unhide>

=over

All debug lines in this module are warn statements and are hidden behind 
'###InternalBuilDInstancE'.  When exposed they can be redirected to log files with 
Log::Shiras::TapWarn.

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
