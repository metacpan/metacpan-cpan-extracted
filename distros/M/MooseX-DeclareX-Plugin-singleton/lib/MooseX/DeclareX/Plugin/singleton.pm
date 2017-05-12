package MooseX::DeclareX::Plugin::singleton;

BEGIN {
	$MooseX::DeclareX::Plugin::singleton::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::singleton::VERSION   = '0.003';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare 0 ();
use Moose::Util ();
use MooseX::Singleton::Role::Object 0 ();

sub _callback
{
	my $caller = shift;
	
	Moose::Util::MetaRole::apply_metaroles(
		for   => $caller,
		class_metaroles => {
			class       => ['MooseX::Singleton::Role::Meta::Class'],
			instance    => ['MooseX::Singleton::Role::Meta::Instance'],
			constructor => ['MooseX::Singleton::Role::Meta::Method::Constructor'],
		},
	);
	Moose::Util::MetaRole::apply_base_class_roles(
		for   => $caller,
		roles => ['MooseX::Singleton::Role::Object'],
	);
}

sub plugin_setup
{
	my ($class, $kw) = @_;

	if ($kw->isa('MooseX::DeclareX::Keyword::class'))
	{
		$kw->register_feature(singleton => sub {
			my ($self, $ctx, $package) = @_;
			$ctx->add_early_cleanup_code_parts(
				"MooseX::DeclareX::Plugin::singleton::_callback(q[$package])"
			);
		});
	}
}

1;


__END__

=head1 NAME

MooseX::DeclareX::Plugin::singleton - shiny syntax for MooseX::Singleton

=head1 SYNOPSIS

 class Logger is singleton
 {
    method log ($str) {
       ...;
    }
 }
 
 Logger->instance->log("here we are!");

=head1 DESCRIPTION

This distribution extends MooseX::DeclareX with a new plugin:

=over

=item C<< is singleton >>

Marks a class as a singleton, providing C<< instance >> and C<< initialize >>
methods as per L<MooseX::Singleton>.

=back

=head1 BUGS

B<Known issue:> you may occasionally get errors about inlining the constructor.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-DeclareX-Plugin-singleton>.

=head1 SEE ALSO

L<MooseX::DeclareX>, L<MooseX::Singleton>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

