package Submodules;
use strict;
use warnings;
use Submodules::Result ();
use File::Spec;
use File::Find qw();
use Carp;
use File::Basename;
our $VERSION = '1.0014';

my $names;

sub import {
	my $self = shift;
	my $pack = caller;
	my $name = shift;
	if (defined($name) and length $name) {
		no strict 'refs';
		croak "Cannot export symbol '&${pack}::$name' because it's already defined" if defined &{"${pack}::$name"};
		*{"${pack}::$name"} = \&submodules;
		$names->{$pack} = $name;
	}
}

sub submodules (;*) {
	my @caller = caller(0);
	my $name = 'submodules';
	if (exists $names->{$caller[0]}) {
		$name = $names->{$caller[0]} if length $names->{$caller[0]};
	}
	my $usage = "Usage:\n   $name name::space\n";
	croak $usage if @_ > 1;
	if (not defined wantarray) {
		carp "Useless call of '$name' in void context";
		return;
	}
	my $query = shift;
	$query = $caller[0] unless defined $query;
	my $self = {
		list		=> [],
		caller_abs	=> File::Spec->rel2abs($caller[1]),
		query		=> $query,
		seen_paths	=> {},
	};
	bless $self, __PACKAGE__;
	my @members = split/(?:::|')/, $query;
	my @inc;
	for my $i (@INC) {
		my $abs = File::Spec->rel2abs($i);
		unless (exists $self->{seen_paths}->{$abs}) {
			push @inc, $abs;
			$self->{seen_paths}->{$abs} = 1;
		}
	}
	for my $i (@inc) {
		my $inc_dir = File::Spec->rel2abs($i);
		if (-f (my $file = File::Spec->catfile($inc_dir, @members).'.pm')) {
			$file = _get_abs_path($file);
			my $caller = _get_abs_path($caller[1]);
			$self->process_file($inc_dir, $file) unless $file eq $caller;
		}
		return $self->{list}->[0] if @{$self->{list}} and not wantarray;
		if (-d (my $path = File::Spec->catfile($inc_dir, @members))) {
			$self->process_path($inc_dir, $path);
		}
	}
	@{$self->{list}};
};

sub find {
	my $self = shift;
	goto &submodules;
}

sub process_path {
	my $self = shift;
	my $path_abs = shift;
	my $path = shift;
	File::Find::find (
		{
			no_chdir	=> 1,
			wanted		=> sub {
				$self->process_file($path_abs, $File::Find::name)
			},
		},
		$path,
	);
}

sub process_file {
	my $self = shift;
	my $path_abs = shift;
	my $file = shift;
	return unless $file =~ /(\.pm)$/i and -f $file and my $extension = $1;
	my $file_abs = File::Spec->rel2abs($file);
	my $file_rel = File::Spec->abs2rel($file_abs);
	my $filename = basename $file_abs;
	my @parts_path = File::Spec->splitdir($path_abs);
	my @parts = File::Spec->splitdir($file_abs);
	splice @parts, 0, scalar @parts_path;
	$parts[$#parts] = substr $parts[$#parts], 0, - length $extension;
	my $code_path = join '::', @parts;
	my $perl_path = join('/', @parts).$extension;
	my $name = $parts[$#parts];
	push @{$self->{list}}, Submodules::Result->new (
		Name		=> $name,
		AbsPath		=> $file_abs,
		RelPath		=> $file_rel,
		Path		=> $perl_path,
		Clobber		=> $self->{seen_paths}->{$name},
		Module		=> $code_path,
	);
	$self->{seen_paths}->{$name} = $file_abs;
}

sub _get_abs_path {
	my $path = shift;
	my @parts = File::Spec->splitdir($path);
	my $file = File::Spec->catfile(@parts);
	File::Spec->rel2abs($file);
}

1;

__END__
=pod

=head1 NAME

Submodules - Efficient way to load or handle all submodules for a specific package.

=head1 SYNOPSIS

This module will walk the paths that Perl itself walks whenever a module is B<use>d or B<require>d
and will return all the submodules found for a specific package (or the current package if none is
specified).

This is useful for many different cases. For example, when you work on a module that is always going
to B<use> or B<require> all of its submodules. Suppose the module I<MyModule> has many submodules
that is going to B<use> from the beggining (e.g. I<MyModule::Protocol>, I<MyModule::Result>,
I<MyModule::Config>, I<MyModule::Plugins>, and so on). You would then normally write something like:

    package MyModule;
    use MyModule::Protocol;
    use MyModule::Result;
    use MyModule::Config;
    use MyModule::Plugins;
    use MyModule::Plugins::PlugA;
    use MyModule::Plugins::PlugB;
    use MyModule::Plugins::PlugC;
    use MyModule::SomethingElse;
    # ...and so on with all of your submodules

Now, imagine you constantly add submodules and you need to keep this list updated too. Instead, you
can use this module in a very efficient way:

    package MyModule;
    use Submodules;
    for my $i (Submodules->find) {
        $i->require;
    }
    
    # Maybe you need to do the same for
    # a package different than the current:
    
    for my $i (Submodules->find('LWP')) { # All LWP & LWP submodules
        $i->require;
    }
    
    # Or maybe you only want a subset:
    
    for my $i (Submodules->find('LWP::Protocol')) { # All LWP protocols
        $i->require;
    }

Not only that will save you lots of lines, but it will always include new submodules without you having
to go back to this one to include them.

Each of the elements returned by the L<find|Submodules/find> method is an instance of L<Submodules::Result>,
which is automagically stringified to the name of the module (as in Some::Module) but has
useful methods that can do a lot more.

=head1 EXPORT

Nothing is exported by default. However, you can import a non OO version of L<find|Submodules/find> with the
name that you prefere. For example, let's say you'd like that function to be called I<walk>.
You'd then call this module like this:

    use strict;
    use Submodules 'walk';
    
    # The new 'walk' function doesn't
    # need you to quote the module name:
    
    for my $i (walk LWP::Protocol) {
        print "Found module $i\n";
    }

You can use any name you want and it'll work as long as it is not already defined in that namespace.

=head1 METHODS

=head2 find

This is basically the only method you'll work with. It can take an optional argument with the name
of a package. If that argument is not supplied, then the current package will be used. It will
return instances of L<Submodules::Result>.

For example:

    # This will find all submodules from the current package
    for my $i (Submodules->find) {
        $i->require;
        say "Required $i";
    }
    
    # This will find all submodules from package LWP::Protocol
    for my $i (Submodules->find('LWP::Protocol')) {
        $i->require;
        say "Required $i";
    }

Read the documentation for L<Submodules::Result> to learn about its own methods.

=head2 Importing a custom 'find' name that is not object oriented

You can import a non object oriented version of L<find|Submodules/find> that also accepts module names
without quoting them (barewords). This might be more for the taste of some and considered
ugly by others. It all depends on you, nothing gets imported by default.

You can chose any valid function name for it and it will be created as long as it is
not already defined in that namespace. It will, just like L<find|Submodules/find>, return instances of
L<Submodules::Result>.

For example:

    use strict;
    use Submodules 'walk';
    
    # The new 'walk' function doesn't
    # need you to quote the module name:
    
    for my $i (walk LWP::Protocol) {
        print "Found module $i\n";
    }

=head1 SEE ALSO

L<Submodules::Result> for more detail on its own methods.

=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-submodules at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Submodules>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Submodules

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
