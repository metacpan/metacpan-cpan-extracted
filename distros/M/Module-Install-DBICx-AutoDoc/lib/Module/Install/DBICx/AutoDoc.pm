package Module::Install::DBICx::AutoDoc;


BEGIN {
	use 5.004;
	use strict;
	use warnings;
	
	use Data::Dump qw/dump/;
	use DBICx::AutoDoc; # if this fails this module fails
	
	use base 'Module::Install::Base';

	our $VERSION = '0.03';
	use vars qw/$SCHEMA $AUTODOC_OUTPUT/;
}

=head1 NAME

Module::Install::DBICx::AutoDoc - Use your Makefile to run DBICx::AutoDoc

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

In MakeFile.PL:
	
	dbicx_autodoc('doc'); # use name() or module_name() as Schema package
	# or
	dbicx_autodoc('doc','My::Schema'); # better be in lib/
	# or
	dbicx_autodoc({
		output => 'doc',
		schema => 'My::Schema'
	});

From CLI:
	
	make autodoc

=head1 METHODS

=head2 dbicx_autodoc

Add a DBICx::AutoDoc call to a Makefile

Example (in Makefile.PL):
	
	name 'My-Schema';
	all_from 'lib/My/Schema.pm';
	author 'Foo Bar';
	
	dbicx_autodoc('doc'); # use name() or module_name() as Schema package
	# or
	dbix_autodoc('doc','My::Schema'); # better be in lib/
	# or
	dbix_autodoc({
		output => 'doc',
		schema => 'My::Schema'
	});
	
This would run DBICx::AutoDoc for My::Schema and store documents in <module-directory>/doc.

=cut

sub dbicx_autodoc {
	my $self = shift;
	
	return unless $Module::Install::AUTHOR;
	
	die "First argrument to 'dbicx_autodoc' must be either an output directory or a HASH ref"
		unless ref($_[0]) eq 'HASH' or !ref($_[0]);
		
	# if our fix argrument (after self) is a hash ref use that as
	# our constructor for DBICx::AutoDoc else use our first argrument
	# as our output directory for DBICx::Schema
	# if our first argrument is not a hash and is not defined
	# use our module_name or name from Module::Install after
	# replacing '-' with '::'
	
	my %args = ref $_[0] eq 'HASH'? %{$_[0]} : (
		schema => defined $_[1]? $_[1] : $self->_get_fixed_module(),
		output => $_[0]
	);
	
	$SCHEMA = $args{schema};
	$AUTODOC_OUTPUT = $args{$output};
	
	my $m = $self->mk_makecmds(\%args);
	return $self->postamble($m);
}

=head2 mk_makecmds
	
Generates our our Makefile statements

=cut

sub mk_makecmds {
	my $self = shift;
	my $hash = shift;
	
	$self->_ck_hash($hash);
	
	return  qq/autodoc :: all\n/.
		qq/\t\$(PERLRUN) -I\$(INST_LIB) -MDBICx::AutoDoc -e '/.
		$self->gen_dbicxautodoc($hash).
		qq/'\n\ndistclean :: autodoc_clean\n\n/.
		qq/autodoc_clean:\n\t\$(RM_RF) /.$hash->{output}.
		qq/\n\n/;
}

=head2 gen_dbicxautodoc

Generates or DBICx::AutoDoc command line call

=cut

sub gen_dbicxautodoc {
	my $self = shift;
	my $hash = shift;
	
	$self->_ck_hash($hash);
	
	my $str = Data::Dump::dump($hash);
	my $ret = q/my $$h=/.$str.q/;DBICx::AutoDoc->new(%{$$h})->fill_all_templates()/;

	return $ret;
}

sub _ck_hash {
	my $self = shift;
	my $hash = shift;
	
	die "Recieved an ".ref($hash)." ref when we expected a HASH ref"
		unless ref($hash) eq 'HASH';
	
}

sub _get_fixed_module {
	my $self = shift;
	return 	join('::',split(/-/,
		($self->module_name? $self->module_name : $self->name )
	));
}


=head1 AUTHOR

Jason M. Mills, C<< <jmmills at cpan.org> >>

=head1 BUGS

B<Warning!>, I have yet to write a "proper" unit test for the Makefile preamble output. I do use this module for my internal db libs and haven't found a problem yet. If someone wanted to contribute a good unit test it would be greatly appreciated. 

Please report any bugs or feature requests to C<bug-module-install-dbicx-autodoc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-DBICx-AutoDoc>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Install::DBICx::AutoDoc


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Install-DBICx-AutoDoc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Install-DBICx-AutoDoc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Install-DBICx-AutoDoc>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Install-DBICx-AutoDoc>

=back

=head1 SEE ALSO
	
	Module::Install, Module::Install::AutoManifest

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jason M. Mills

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Module::Install::DBICx::AutoDoc

