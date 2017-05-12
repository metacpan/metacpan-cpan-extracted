package Submodules::Result;
use File::Spec;
use strict;
use warnings;
use Carp;
use overload (
	fallback	=> 1,
	'""'		=> 'SCALAR',
);
our $AUTOLOAD;
our $VERSION = '1.0014';
our @CARP_NOT = qw(Submodules);
our $default_property = 'Module';
our $SCALAR = sub {
	my $self = shift;
	my @call = caller(1);
	return $self if $call[0] eq __PACKAGE__;
	eval {
		$self->isa('UNIVERSAL');
	};
	return $self if $@;
	$self->{$default_property};
};

sub SCALAR {
	# Easily oerride stringification through $Submodules::SCALAR
	return &$SCALAR(@_) if 'CODE' eq ref $SCALAR;
}

sub new {
	my $class = shift;
	bless {
		AbsPath	=> undef,
		Clobber	=> undef,
		Module	=> undef,
		Name	=> undef,
		Path	=> undef,
		RelPath	=> undef,
		@_,
	}, $class;
}

sub require {
	my $self = shift;
	my @call = caller(0);
	my $r = eval {
		require "$self->{Path}";
	};
	if (my $e = $@) {
		if ($e =~ /did not return a true value/) {
			die $self->Path." did not return a true value at $call[1] line $call[2]\n";
		} else {
			$e =~ s/(Compilation failed in require at) .*?$/$1 $call[1] line $call[2]/g;
			die $e;
		}
	}
	$r;
}

sub use {
	my $self = shift;
	$self->require;
	if (my $import = $self->Module->can('import')) {
		unshift @_, $self->Module;
		goto &$import;
	}
}

sub read {
	my $self = shift;
	undef local $/;
	open my $in, '<', $self->AbsPath or croak "Failed to open $self->{AbsPath} for reading: $!";
	binmode $in;
	my $data = <$in>;
	close $in;
	$data;
}

sub AUTOLOAD : lvalue {
	(my $name = $AUTOLOAD) =~ s/^.+:://;
	my $self = shift;
    my $lvalue;
	if (exists $self->{$name}) {
		$lvalue = \($self->{$name});
	} else {
		eval {
			$lvalue = \($self->{$default_property}->$name);
		};
		croak "Unknown method or property '$name': $@" if $@;
	}
    $$lvalue;
}

sub DESTROY {
	my $self = shift;
	for my $k (keys %$self) {
		undef $self->{$k};
		delete $self->{$k};
	}
	undef $self;
}

1;

__END__
=pod

=head1 NAME

Submodules::Result - Efficient way to load or handle results from L<Submodules>.

=head1 SYNOPSIS

This is the object returned by L<< Submodules->find|Submodules/find >>. It has several methods that makes it
easy to handle the tasks that are more commonly needed for a module. It's automagically
stringified to the name of the module (in B<Module::Name> format), but even inside string
interpolation, you can access its properties as you would with a hashref:

    package MyModule;
    use Submodules;
    for my $i (Submodules->find) {
        next if $i->Clobber; # Important
        
        $i->require;
        # Equivalent to 'require Some::Module'
        
        print "I found $i";
        # Will print: I found Some::Module
        
        print "The path is $i->{RelPath}";
        # Will print something like Some/Module.pm
        
        print "The absolute path is $i->{AbsPath}";
        # Will print something like /usr/local/lib64/perl5/lib/Some/Module.pm
        
        print "The name of the module is $i->{Module}";
        # Will print The name of the module is Some::Module
    }

=head1 PROPERTIES

All properties can be called as methods too. For example:

    package MyModule;
    use Submodules;
    for my $i (Submodules->find) {
        # Used as method
        next if $i->Clobber;
        
        # Used as property (hash element)
        print "The value of Clobber is $i->{Clobber}";
    }

=head2 Module

This property correponds to the complete name of the module in the format of B<Some::Module>.

=head2 Name

This property refers to the last part of the name of the module. For example, B<Some::Module>
would be only B<Module>.

=head2 Path

This property contains a path exactly like the one that Perl stores internaly in its symbol table.
This means that, for B<Some::Module>, it will be B<Some/Module.pm>, using forward slashes independently
of the current operating system.

=head2 AbsPath

Corresponds to the absolute path where the module can be found. Depending on your system, the format
can be different. For example, on Windows you'll get back-slashes on the path. This behavior comes
directly from L<File::Spec>.

=head2 RelPath

Correspods to the relative path to the module. Similar to L<AbsPath|Submodules::Result/AbsPath> except for being relative to
the location of the current execution.

=head2 Clobber

This property indicates that a module cannot (or should not) be visible by commands like B<use> or
B<require>. It generally means that another module with the same name is the one being read and
is masking this one. One example of this would be a core module that came with Perl by default,
but was later upgraded and installed into the site/lib section. It's value is the absolute path
to the first module that is directly masking it.

B<IMPORTANT:> You should always test for this property and B<not> load the code when true, unless
you know what you are doing and you actually intended to use this module for that very purpose.

=head1 METHODS

As mentioned in L<PROPERTIES|Submodules::Result/PROPERTIES>, all properties can be called as methods too. Besides that, there are
a few more useful methods:

=head2 read

This will read and return the contents of the module, as plain text. No code is parsed or executed.

=head2 require

This acts just like Perl's C<require>, meaning that the module in question will be read, evaluated
(executed) and the last statement will be returned, which in case of it not being a true value it
will die. Nothing gets imported.

=head2 use

B<Use properly!>

This acts just like Perl's C<use>, meaning that it will do the same as in C<require>, but it will
also call C<< ->import >> into the current namespace. However, you should understand that the
native Perl's C<use> is generally executed at I<compile> time. For some modules and its features
(like prototypes, constants, function names that can be used without parenthesis, and many other 
things), executing all that in compile time is crucial and can result in unexpected and hard to debug
erros when executed at runtime.

To avoid this, either use it only in modules that are supposed to be loaded at compile time (via C<use>
from another script calling it), or place your code inside a C<BEGIN> block to force its execution 
at compile time.

This is an example:

    use strict;
    use warnings;
    use Submodules;
    
    BEGIN {
        for my $i (Submodules->find('LWP::Protocol')) {
            next if $i->Clobber;
            $i->use;
        }
    }

=head2 new

This is the constructor and exists mainly for internal purposes. It requires all of its properties
to be passed as arguments and that's something that L<Submodules> does by itself. There should
be no reason to use this method directly.

Read the documentation for L<Submodules> to learn about its own methods.

=head1 SEE ALSO

L<Submodules> for more detail on its own methods.

=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-submodules at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Submodules>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Submodules::Result

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Submodules>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Submodules>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Submodules>

=item * Search CPAN

L<http://search.cpan.org/dist/Submodules/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Francisco Zarabozo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
