package P5U::Lib::AutoProve;

BEGIN {
	$P5U::Lib::AutoProve::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::AutoProve::VERSION   = '0.100';
};

use 5.010;
use strict;
use utf8;

use App::Prove;
use Cwd 'cwd';
use Object::AUTHORITY;

sub change_to_suitable_directory
{
	my ($self) = @_;
	
	while (-d '..' and not -d 't')
	{
		chdir '..';
	}

	unless (-d 't')
	{
		die "No suitable test suite found.\n";
	}

	return cwd;
}

sub opts
{
	qw(
		recurse|r timer verbose|v color|c dry|D failures|f comments|o fork
		ignore-exit merge|m shuffle|s reverse normalize T t W w jobs|j=i
	);
}

sub build_option_args
{
	my ($self, %opt) = @_;
	my $jobs = delete $opt{jobs};
	
	my @args =
		map { "--$_" }
		sort keys %opt;
	
	push @args, "--jobs=$jobs" if $jobs;
	
	return @args;
}

sub build_lib_args
{
	map { "-I$_" } grep { -d $_ } qw( blib/lib inc lib t/lib xt/lib );
}

sub get_app
{
	my ($self, %opt) = @_;

	my $do_author_tests = delete $opt{xt};

	my $origwd = cwd;
	my $cwd    = $self->change_to_suitable_directory;
	print "Found suitable test suite within directory '$cwd'.\n";

	my @args = $self->build_option_args(%opt);
	push @args, $self->build_lib_args;
	
	push @args, 't'  if -d 't';
	push @args, 'xt' if -d 'xt' && $do_author_tests;
	
	chdir $origwd;

	print join(q{ }, prove => @args), "\n"
		if $opt{verbose};
	
	my $app = App::Prove->new;
	$app->process_args(@args);
	return ($cwd, $app);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords chdir

=head1 NAME

P5U::Lib::AutoProve - support library implementing p5u's auto-prove command

=head1 SYNOPSIS

 use P5U::Lib::AutoProve;
 
 my ($dir, $app) = P5U::Lib::AutoProve->get_app(
     verbose  => 1,
     xt       => 1,
 );
 
 chdir $dir;
 $app->run;

=head1 DESCRIPTION

This is a support library for the auto-prove command.

=head2 Class Method

There's only one method (a class method, not an object method... this
isn't really an OO module) worth caring about:

=over

=item C<< get_app(%opts) >>

Returns a two-item list. The first is a directory to chdir to; the second
is an instance of L<App::Prove> which the C<run> method should be called
on.

%opts represents the command-line options passed to prove. When options
have an abbreviated and full version (e.g. C<< -v >> versus C<< --verbose >>)
the longer version is expected, without the dashes. For boolean options,
the value is ignored; the existence of the option in the hash at all (even
with a false or undefined value) switches it on.

=back

=begin private

=item change_to_suitable_directory

=item opts

=item build_option_args

=item build_lib_args

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

