package Perlmazing::Engine;
use Perlmazing::Feature;
use Submodules;
use Carp;
use Scalar::Util qw(set_prototype);
use Taint::Util 'untaint';
use Data::Dump 'dump';
our $VERSION = '1.2810';
my $found_symbols;
my $loaded_symbols;
my $precompile_symbols;
my $parameters;

sub found_symbols {
	my $self = shift;
	my $package = (shift or caller);
	return unless exists $found_symbols->{$package};
	return sort keys %{$found_symbols->{$package}};
}

sub loaded_symbols {
	my $self = shift;
	my $package = (shift or caller);
	return unless exists $loaded_symbols->{$package};
	return keys %{$loaded_symbols->{$package}};
}

sub preload {
	my $self = shift;
	my $package = caller;
	for my $i (@_) {
		_debug("Preloading symbol $i", $package);
		_load_symbol($package, $i);
	}
}

sub import {
	my $self = shift;
	carp "If passing arguments to this module, it most be using named arguments" if @_ % 2;
	my $package = caller;
	my $p = {@_};
	$parameters->{$package} = {} unless $parameters->{$package};
	$parameters->{$package} = {%{$parameters->{$package}}, %$p};
	return if exists $found_symbols->{$package};
	$found_symbols->{$package} = {};
	_debug("Importing $self");
	$self->_find_symbols($package);
}

sub _is_compile_phase {
	my $code = q[
		BEGIN {
			use warnings 'FATAL' => 'all';
			eval 'INIT{} 1' or die;
		}
	];
	eval $code;
	return 0 if $@;
	1;
}

sub _debug {
	my $msg = shift;
	my $caller = (shift or caller);
	print STDERR __PACKAGE__." DEBUG: Package $caller, $msg\n" if $parameters->{$caller}->{debug};
}

sub _find_symbols {
	my $self = shift;
	my $package = shift;
	my @paths;
	my $seen_paths;
	_debug("Looking for symbols", $package);
	for my $i (Submodules->find("${package}::Perlmazing")) {
		next if $i->{Clobber};
		_debug("Found file $i->{AbsPath} for symbol $i->{Name}", $package);
		$found_symbols->{$package}->{$i->Name} = $i;
		if ($i->Module eq "${package}::Perlmazing::Precompile::$i->{Name}") {
			$precompile_symbols->{$package}->{$i->Name} = $i;
		}
		no strict 'refs';
		*{"${package}::$i->{Name}"} = sub {
			unshift @_, $package, $i->Name;
			goto &_autoload;
		};
	}
}

sub precompile {
	my $self = shift;
	my $package = caller;
	return unless exists $precompile_symbols->{$package};
	for my $name (sort keys %{$precompile_symbols->{$package}}) {
		# We detect already precompiled symbols by undefining this variable
		# Note that symbols can in some cases (by internal recursion) be called
		# more than once, not allowing _load_symbol to complete and mark it as loaded
		# before being called again, so this part comes handy in those cases.
		next if not defined $precompile_symbols->{$package}->{$name};
		undef $precompile_symbols->{$package}->{$name};
		_debug("Precompiling symbol $name", $package);
		_load_symbol($package, $name);
	}
}

sub _preload {
	my $self = shift;
	my $package = shift;
	for my $i (@_) {
		_debug("Preloading symbol $i", $package);
		_load_symbol($package, $i);
	}
}

sub _autoload {
	my ($package, $symbol) = (shift, shift);
	_debug("Autoloading symbol $symbol", $package);
	my $code = _load_symbol($package, $symbol);
	goto $code;
}

sub _load_symbol {
	my ($package, $symbol) = (shift, shift);
	local $@;
	return $loaded_symbols->{$package}->{$symbol} if exists $loaded_symbols->{$package} and exists $loaded_symbols->{$package}->{$symbol};
	croak "File $package/Perlmazing/$symbol.pm cannot be found in \@INC for symbol \&${package}::$symbol - \@INC contains: @INC" unless exists $found_symbols->{$package} and exists $found_symbols->{$package}->{$symbol};
	_debug("Reading file $found_symbols->{$package}->{$symbol}", $package);
	my $code = $found_symbols->{$package}->{$symbol}->read;
	_debug("Parsing contents of $found_symbols->{$package}->{$symbol}->{AbsPath}", $package);
	my $stderr = '';
	my $eval_string = "\n#line 1 $found_symbols->{$package}->{$symbol}->{AbsPath}\npackage ${package}::Perlmazing::$symbol; $code";
	{
		local *STDERR;
		open STDERR, '>>', \$stderr;
		untaint $eval_string;
		eval $eval_string;
	}
	if (my $e = $@) {
		croak "While attempting to load symbol '$symbol': $e";
	}
	print STDERR $stderr if length $stderr;
	$loaded_symbols->{$package}->{$symbol} = "${package}::Perlmazing::${symbol}"->can('main');
	die "Unable to find sub 'main' at $found_symbols->{$package}->{$symbol}->{AbsPath} line 1 to EOF\n" unless $loaded_symbols->{$package}->{$symbol};
	_debug("Replacing skeleton symbol with actual code from $found_symbols->{$package}->{$symbol}->{AbsPath}", $package);
	if ("${package}::Perlmazing::${symbol}"->isa('Perlmazing::Listable')) {
		_debug("Symbol &${package}::$symbol isa Perlmazing::Listable, creating wrapper sub around it", $package);
		my $sub_main = $loaded_symbols->{$package}->{$symbol};
		my $sub_pre = sub {
			for my $i (@_) {
				$sub_main->($i);
			}
		};
		$loaded_symbols->{$package}->{$symbol} = sub {
			my $wantarray = wantarray;
			my @call = caller(1);
			my @res = eval {
				(@_) = ($_) if not @_;
				if ($wantarray) {
					my @res = @_;
					foreach my $i (@res) {
						$sub_pre->($i);
					}
					return @res;
				} elsif (defined $wantarray) {
					my $i = $_[0];
					$sub_pre->($i);
					return $i;
				} else {
					foreach my $i (@_) {
						$sub_pre->($i);
					}
				}
			};
			if (my $e = $@) {
				if ($e =~ /^Modification of a read\-only value attempted/) {
					die "Modification of a read-only value attempted at $call[1] line $call[2]\n";
				} else {
					die "Unhandled error in listable function: $e\n";
				}
			}
			return @res if $wantarray;
			$res[0];
		};
	}
	no strict 'refs';
	no warnings qw(redefine once);
	my $skeleton = *{"${package}::$symbol"}{CODE};
	my ($callers, $offset);
	while (my $caller = caller($offset++)) {
		$callers->{$caller}++;
	}
	$callers->{$package}++;
	for my $i (keys %$callers) {
		next if $i eq __PACKAGE__;
		if (my $ref = *{"${i}::$symbol"}{CODE}) {
			my $proto_old = prototype \&{"${i}::$symbol"};
			my $proto_new = prototype $loaded_symbols->{$package}->{$symbol};
			if ((defined $proto_new and defined $proto_old and $proto_old ne $proto_new) or (defined $proto_old and not defined $proto_new) or (defined $proto_new and not defined $proto_old)) {
				carp "Warning: Too late to apply prototype ($proto_new) to symbol &${i}::$symbol - perl compilation phase has passed already" unless _is_compile_phase();
				set_prototype \&{"${i}::$symbol"}, $proto_new;
			}
			*{"${i}::$symbol"} = $loaded_symbols->{$package}->{$symbol} if $ref eq $skeleton;
		}
	}
	_debug(__PACKAGE__." no longer has power over symbol &${package}::$symbol (it's now loaded on it's own code)", $package);
	$loaded_symbols->{$package}->{$symbol};
}

package Perlmazing::Listable;

1;

__END__
=pod
=head1 NAME

Perlmazing::Engine - Have your functions load their code and associated modules only when needed, automagically.


=head1 SYNOPSIS

This module was written with one main goal in mind: to save time, processing and memory when a module is loaded
and it has a lot of functions (exported or not) and a those functions require loading a lot of other modules.

By using this module, you can write your functions in separate files without having to declare any package.
Perlmazing::Engine will create empty symbols for each function you write (one per file). Those symbols will
be present in your own module just like if they were regular functions - but the code associated with them 
will be loaded the first time you attempt to use each function. For many heave modules, this can be the answer
to faster loading times and, when not all functions are used by a script, also a lot of processing and memory
can be saved.

Also, behind the scenes, Perlmazing::Engine manages each function in a separate and unique namespace, but
making any other function from your module visible and usable just like if they were all in the same namespace.
By doing this, it also maintains your namespace clean, free from anything a specific function imports from
other modules just to work itself. Each function can have it's own globals (variables, secondary functions, etc.)
without poluting the whole module.

In order to use Perlmazing::Engine, you just do something like the following:

    package MyModule;
    use Perlmazing::Engine;
    
    # Now your functions are usable, but not loaded until called.

    1;


=head1 HOW TO USE

So, where do we put functions and their code so Perlmazing::Engine knows what to do? You need to have the following structure
for your module files. Assume your module name is C<MyModule>; so you will organize any submodules in the folder C<./Submodule>,
like normal, but you will also have a C<./MyModule/Perlmazing> folder where your function files will live. You can have an
optional C<./MyModule/Perlmazing/Precompile> folder, where you will place function files that for any reason you want to be
compiled at compile time (e.g. functions with prototypes):

    .
    |-- MyModule.pm
    +-- MyModule/
        +-- Perlmazing/
            |-- function_A.pm
            |-- function_B.pm
            +-- Precompile/
                |-- function_C.pm
                |-- function_D.pm

In the previous example, Perlmazing::Engine will create empty symbols for the functions C<function_A>, C<function_B>, C<function_C>
and C<function_D>, all of them belonging to the C<MyModule> namespace. If you had a submodule called C<MyModule::Clients> and
wanted to use C<Perlmazing::Engine> there too, then that submodule would use its own folder at C<./MyModule/Clients/Perlmazing>. It
would then look like this:

    .
    |-- MyModule.pm
    +-- MyModule/
        |-- Clients.pm
        +-- Clients/
        |   +-- Perlmazing
        |       |-- function_E.pm
        |       |-- function_F.pm
        +-- Perlmazing/
            |-- function_A.pm
            |-- function_B.pm
            +-- Precompile/
                |-- function_C.pm
                |-- function_D.pm

C<MyModule::Clients> is now able to use the functions C<function_E> and C<function_F> by just calling C<use Perlmazing::Engine>.


=head1 HOW FUNCTIONS SHOULD BE WRITTEN

Besides residing on its own file in their respective C<Perlmazing> folder, and having a file name that is their exact actual function
name, they also have one particularity that most be respected: the function name inside the file will always be C<main>. This has
several reasons, being one of the most important ones that you can import your own module and if that module exports functions by default,
and one of those functions happens to be the one you are writting in this file, then having the same exact name would cause a conflict.

There are also two types of functions you can write, in terms of behavior and this is something comming from L<Perlmazing::Engine>.
Basically, you get the regular type and the C<Listable> type. The regular type is simply any kind of subroutine,
and it can simply do whatever you code it to do.


=head1 REGULAR FUNCTIONS

The following is an example of a simple function. Let's say that function name is "B<say_hello()>", so it will live in the file
C<./MyModule/Perlmazing/say_hello.pm> and will have the following content:

    use strict;
    use warnings;
    # use any other module you need here for this specific function to work
    
    sub main {
        print "Hello there!\n";
    }
    
    1;


=head1 LISTABLE FUNCTIONS

C<Listable> functions are all meant to follow this behavior:

    # Assume 'my_sub' is a function of the type Listable:
    
    # Calling my_sub on an array will directly affect elements of @array:
    
    my_sub @array;
    
    # Calling my_sub on a list will *attempt* to directly affect the
    # elements of that list, failing on 'read only'/'constant' elements
    # like the elements in the following list:
    
    my_sub (1, 2, 3, 4, 5, 'string element');
    
    # Calling my_sub on an array or a list BUT with an assignment,
    # will *not* affect the original array or list, but assign an
    # affected copy:
    
    my @array_A = my_sub @array;
    my @array_B = my_sub (1, 2, 3, 4, 5, 'string_element');
    
    # Listable functions can be chained to achieve both behaviors
    # (assignment or direct effect) on a single call. Assume
    # 'my_sub2', 'my_sub3' and 'my_sub4' are also Listable functions:
    
    my_sub my_sub1 my_sub2 my_sub3 my_sub4 @array;
    my @array_C = my_sub my_sub1 my_sub2 my_sub3 my_sub4 (1, 2, 3, 4, 5, 'string element');
    
    # When a Listable function is assigned in scalar context, then only the
    # first element is assigned, not a list/array count.
    
    my $scalar = my_sub @array; # $scalar contains the first element of the resulting list
    
When writting a listable function, you need to do two things: first, make that function C<listable>
by including in its <@ISA> the namespace C<Perlmazing::Listable>. Second, you should always deal directly
with the argument C<$_[0]> and not a copy of it. This means you B<should not> do something like C<my ($arg1, $arg2) = @_>.
You will only deal with C<$_[0]> because C<Perlmazing::Engine> will always pass only one argument to C<Perlmazing::Listable>
functions and expect that function to directly affect that argument. Then C<Perlmazing::Engine> will be the one
deciding what to do with that result, based on the context and arguments that function was called with.

The following is an example taken from the function C<escape_uri> from the L<Perlmazing> module. Look at how simple it is:

    use Perlmazing;
    use URI::Escape;
    our @ISA = qw(Perlmazing::Listable);

    sub main {
        $_[0] = uri_escape($_[0]) if defined $_[0];
    }

    1;
    
That function will have all the behavior previously described for C<Listable> functions, but you don't need to think
of that behavior here, C<Perlmazing::Engine> will do that for you and you will only work with C<$_[0]>.


=head1 EXPORTS

C<Perlmazing::Engine> doesn't export anything by default. In fact, so far none of its functions or methods are meant to be imported.
If you are wondering about how to export functions from your own module (even if they work through C<Perlmazing::Engine>), then you
will do so exactly as you would if you weren't using this module (e.g. using L<Exporter> or your favorite export module/method).


=head1 METHODS

The following is a list of methods you can call from C<Perlmazing::Engine>:


=head2 found_symbols

C<< my @symbols = Perlmazing::Engine->found_symbols($optional_namespace) >>

This method will return a list with all the symbols C<Perlmazing::Engine> found for a specific package/namespace. If you don't
provide any arguments, then the current namespace will be used. The following is an example of it being used to export every
function from your module into its caller:

    use strict;
    use warnings;
    use Perlmazing::Engine;
    require Exporter;
    
    our @EXPORT = Perlmazing::Engine->found_symbols;
    
    # Or, you could do that with @EXPORT_OK just to make them available for export.
    

=head2 loaded_symbols

C<< my @symbols = Perlmazing::Engine->loaded_symbols($optional_namespace) >>

This method will return a list of the symbols for which its actual code has been already loaded.


=head2 preload

C<< Perlmazing::Engine->preload(@list_of_symbols_to_preload) >>

This method will load (completely, including their respective code) all of the symbols passed as argument. This is useful
then you know you will need these symbols loaded from the begining, or maybe at compile time, for any reasons you may have.


=head2 precompile

C<< Perlmazing::Engine->precompile >>

This method is similar to C<preload>, but while C<preload> works with any symbol name passed as argument, C<precompile> works
with the symbols found in the I<precompile> folder described L<previously|Perlmazing::Engine/HOW TO USE>.


=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-perlmazing at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perlmazing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perlmazing::Engine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perlmazing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlmazing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlmazing>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlmazing/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Francisco Zarabozo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
