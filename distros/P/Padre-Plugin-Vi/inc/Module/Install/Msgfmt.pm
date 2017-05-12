#line 1
package Module::Install::Msgfmt;

use strict;
use File::Spec;
use Module::Install::Base ();
use Module::Install::Share;

our $VERSION = '0.14';
our @ISA     = 'Module::Install::Base';

sub install_share_with_mofiles {
	my @orig      = (@_);
	my $self      = shift;
	my $class     = ref($self);
	my $prefix    = $self->_top->{prefix};
	my $name      = $self->_top->{name};
	my $dir       = @_ ? pop : 'share';
	my $type      = @_ ? shift : 'dist';
	my $module    = @_ ? shift : '';
	$self->build_requires( 'Locale::Msgfmt' => '0.14' );
	install_share(@orig);
	my $distname = "";

	if ( $type eq 'dist' ) {
		$distname = $self->name;
	} else {
		$distname = Module::Install::_CLASS($module);
		$distname =~ s/::/-/g;
	}
	my $path = File::Spec->catfile( 'auto', 'share', $type, $distname );
	$self->postamble(<<"END_MAKEFILE");
config ::
\t\$(NOECHO) \$(PERL) "-MLocale::Msgfmt" -e "Locale::Msgfmt::do_msgfmt_for_module_install(q(\$(INST_LIB)), q($path))"

END_MAKEFILE
}
