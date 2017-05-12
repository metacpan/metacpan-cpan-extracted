package P5U::Lib::Reprove;

BEGIN {
	$P5U::Lib::Reprove::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::Reprove::VERSION   = '0.100';
};

use 5.010;
use autodie;

use Moo;
use App::Prove qw//;
use Class::Load qw/load_class/;
use Carp qw/confess/;
use JSON qw/from_json/;
use File::pushd qw/pushd/;
use File::Temp qw//;
use Module::Info qw//;
use Path::Tiny qw//;
use LWP::Simple qw/get/;
use Module::Manifest qw//;
use Object::AUTHORITY qw/AUTHORITY/;
use Types::Standard qw< ArrayRef Bool Str >;
use Type::Utils qw< class_type >;

has author => (
	is         => 'lazy',
	isa        => Str,
);

has release => (
	is         => 'ro',
	isa        => Str,
	required   => 1,
);

has version => (
	is         => 'ro',
	isa        => Str,
	required   => 1,
);

has manifest => (
	is         => 'lazy',
	isa        => ArrayRef,
);

has testdir => (
	is         => 'lazy',
	isa        => class_type { class => 'Path::Tiny' },
);

has working_dir => (
	is         => 'lazy',
	isa        => class_type { class => 'Path::Tiny' },
);

has verbose => (
	is         => 'rw',
	isa        => Bool,
	required   => 1,
	default    => sub { 0 },
);

sub BUILDARGS
{
	my ($class, @args) = @_;
	
	my %args;
	if (@args == 1 and ref $args[0])
	{
		%args = %{ $args[0] }
	}
	elsif (scalar(@args) % 2 == 0)
	{
		%args = @args;
	}
	else
	{
		confess "Called with the wrong number of arguments.";
	}
	
	if (defined $args{module} and not defined $args{version})
	{
		$args{version} = Module::Info::->new_from_module($args{module})->version;
	}
	
	if (defined $args{module} and not defined $args{author})
	{
		load_class($args{module});
		if ($args{module}->can('AUTHORITY'))
		{
			($args{author}) =
				map { s/^cpan://; $_ }
				grep { /^cpan:/ }
				($args{module}->AUTHORITY);
		}
		else
		{
			no strict 'refs';
			my $auth = ${$args{module}.'::AUTHORITY'};
			if (defined $auth and $auth =~ /^cpan:(.+)$/)
			{
				$args{author} = $1;
			}
		}
	}
	
	if (defined $args{module} and not defined $args{release})
	{
		my $d = from_json(get(sprintf('http://api.metacpan.org/v0/module/%s', $args{module})));
		$args{release}  = $d->{distribution};
		$args{author} //= $d->{author};
	}
	
	if (defined $args{release} and not defined $args{author})
	{
		my $d = from_json(get(sprintf('http://api.metacpan.org/v0/release/%s', $args{release})));
		$args{author} //= $d->{author};
	}
	
	delete $args{module};
	$class->SUPER::BUILDARGS(%args);
}

sub _url_for
{
	my ($self, $file) = @_;
	sprintf(
		'http://api.metacpan.org/source/%s/%s-%s/%s',
		uc $self->author,
		$self->release,
		$self->version,
		$file,
		);
}

sub _getfile_to_handle
{
	my ($self, $file, $fh) = @_;
	print $fh get($self->_url_for($file));
}

sub test_files
{
	my $self = shift;
	grep { m{^t/} } @{ $self->manifest };
}

sub _build_author
{
	my $self = shift;
	my $d = from_json(get(
		sprintf('http://api.metacpan.org/v0/release/%s', $self->release)
		));
	$d->{author};
}

sub _build_manifest
{
	my $self = shift;
	my $fh = $self->working_dir->child('MANIFEST')->openw;
	binmode( $fh, ":utf8");
	$self->_getfile_to_handle('MANIFEST', $fh);
	close $fh;
	
	my $manifest = Module::Manifest->new;
	$manifest->open(manifest => $self->working_dir->child('MANIFEST')->stringify);
	return [ $manifest->files ];
}

sub _build_testdir
{
	my $self    = shift;
	my $testdir = $self->working_dir->child('t');
	$testdir->mkpath;
	
	foreach my $file ($self->test_files)
	{
		my $dest = $testdir->child($file);
		Path::Tiny::->new($dest->dirname)->mkpath;
		$self->_getfile_to_handle($file, $dest->openw);
	}
	
	return $testdir;
}

sub _build_working_dir
{
	my $self = shift;
	Path::Tiny::->tempdir;
}

sub _app_prove_args
{
	't';
}

sub run
{
	my $self = shift;
	printf("Reproving %s/%s (%s)\n", $self->release, $self->version, uc $self->author);
	printf("Using temp dir '%s'\n", $self->testdir) if $self->verbose;
	my $chdir = pushd($self->testdir);
	my $app   = App::Prove->new;
	$app->process_args($self->_app_prove_args);
	$app->verbose(1) if $self->verbose;
	$app->run;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords refactored MetaCPAN

=head1 NAME

P5U::Lib::Reprove - download a distribution's tests and prove them

=head1 SYNOPSIS

 my $test = P5U::Lib::Reprove::->new(
     author  => 'TOBYINK',
     release => 'Object-AUTHORITY',
     version => '0.003',
     verbose => 1,
 );
 $test->run;

=head1 DESCRIPTION

This module downloads a distribution's test files (the contents of the C<t>
directory) and runs L<App::Prove> (part of L<Test::Harness>) on them.

It assumes that all the other files necessary for passing the test suite are
already available on your system, installed into locations where the test suite
will be able to find them. In particular, the libraries necessary to pass the
test suite must be installed.

It makes a number of assumptions about how a distribution's test cases are
structured, but these assumptions do tend to hold in most cases.

This work was previously released as B<Module::Reprove>, but has now been
refactored and integrated with L<P5U>.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Construct an object with given attributes. This is a Moo-based class.

=back

=head2 Attributes

=over

=item C<< release >>

Release name, e.g. "Moose" or "RDF-Trine". Required.

=item C<< version >>

Release version, e.g. "2.0001" or "0.136". Required.

=item C<< author >>

Release author's CPAN ID, e.g. "DOY" or "GWILLIAMS". If this is not provided,
it can usually be figured out using the MetaCPAN API, but it's a good idea
to provide it.

=item C<< verbose >>

Boolean indicating whether output should be verbose. Optional, defaults to false.

=item C<< working_dir >>

A L<Path::Tiny> object pointing to a directory where all the working
will be done. If you don't provide one to the constructor, P5U::Lib::Reprove
is sensible enough to create a temporary directory for working in (and delete
it afterwards).

=item C<< manifest >>

An arrayref of strings, listing all the files in the distribution.
Don't provide this to the constructor - just allow P5U::Lib::Reprove
to build it.

=item C<< testdir >>

A L<Path::Tiny> object pointing to a directory where test cases
are stored. Don't provide this to the constructor - just allow
P5U::Lib::Reprove to build it.

=back

There is also a pseudo-attribute C<< module >> which may be provided to the
constructor, and allows the automatic calculation of C<< release >>,
C<< version >> and C<< author >>. There is no getter/setter method for
C<< module >> though; it is not a true attribute.

=head2 Methods

=over

=item C<< test_files >>

Returns a list of test case files, based on the contents of the manifest.

=item C<< run >>

Runs the test using C<< App::Prove::run >> and returns whatever L<App::Prove>
would have returned, which is undocumented but appears to be false if there
are test failures, and true if all tests pass.

=begin private

=item C<< BUILDARGS >>

Moose stuff.

=end private

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

L<http://www.perlmonks.org/?node_id=942886>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

