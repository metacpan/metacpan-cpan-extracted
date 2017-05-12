package P5U::Lib::Version;

use 5.010;
use utf8;

BEGIN {
	$P5U::Lib::Version::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::Version::VERSION   = '0.100';
};

use JSON qw< from_json >;
use LWP::Simple qw< get >;
use Module::Info;
use Module::Runtime qw< module_notional_filename >;
use Object::AUTHORITY;

sub local_module_info
{
	my $self = shift;
	return
		map { sprintf "%s: %s", $_->file, $_->version }
		Module::Info->all_installed(@_);
}

sub cpan_module_info
{
	my $self = shift;
	my $mod  = shift;

	my $data = from_json get(
		sprintf
			'http://api.metacpan.org/v0/module/_search?q=status:cpan+AND+path:lib/%s&fields=version,release,author,path,date&size=1000',
			module_notional_filename($mod),
	);
	return $self->_format_hits(cpan => $data);
}

sub backpan_module_info
{
	my $self = shift;
	my $mod  = shift;

	my $data = from_json get(
		sprintf
			'http://api.metacpan.org/v0/module/_search?q=status:backpan+AND+path:lib/%s&fields=version,release,author,path,date&size=1000',
			module_notional_filename($mod),
	);
	return $self->_format_hits(backpan => $data);
}

sub _format_hits
{
	my ($self, $label, $data) = @_;
	die "MetaCPAN API timed out" if $data->{timed_out};
	
	return
		map {
			sprintf
				'%s:%s/%s.tar.gz#%s: %s (%s)',
				$label,
				@{$_}{qw<author release path version date>}
		}
		sort { $a->{version} cmp $b->{version} }
		map  { $_->{fields} }
		@{ $data->{hits}{hits} };
}

1;

__END__

=pod

=encoding utf-8

=for stopwords BackPAN MetaCPAN

=head1 NAME

P5U::Lib::Version - support library implementing p5u's version command

=head1 SYNOPSIS

 use P5U::Lib::Version;
 my @lines = P5U::Lib::Version->local_module_info($module);

=head1 DESCRIPTION

This is a support library for the version command.

=head2 Class Methods

=over

=item C<< local_module_info($module) >>

Locates a Perl module on the local machine, searching through @INC.
For each file found (there may be more than one) finds the version
number of the module.

Returns a list of strings formatted like C<< "FILE: VERSION" >>.

=item C<< cpan_module_info($module) >>

As per C<local_module_info> but searches CPAN using the MetaCPAN API.

Returns a list of strings formatted like
C<< "cpan:AUTHOR/TARBALL#FILE: VERSION (DATE)" >>.

=item C<< backpan_module_info($module) >>

As per C<local_module_info> but searches BackPAN using the MetaCPAN API.

Returns a list of strings formatted like
C<< "backpan:AUTHOR/TARBALL#FILE: VERSION (DATE)" >>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>, L<V>.

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

