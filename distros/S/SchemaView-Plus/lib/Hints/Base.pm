package Hints::Base;

use strict;
use Hints;
use IO::Handle;
use vars qw/$VERSION @ISA/;

$VERSION = '0.02';
@ISA = qw/Hints/;

=head1 NAME

Hints::Base - Perl extension for hints program storage databases

=head1 SYNOPSIS

	use Hints::Base;

	my $hints = new Hints::Base 'program';

	print $hints->random();

=head1 DESCRIPTION

Specialized version of Hints(3) extension. This variant can be used for
internal program storage database of hints. Descendant contents databases,
this module implement loading of databases from internal data storage.

=head1 THE HINTS::BASE CLASS

=head2 init

Loading data storage between __DATA__ and __END__ or EOF tags. Using
default separator.

=cut

sub init {
	my $obj = shift;
	my $next = shift;
	if ($next) {
		my $nextname = "Hints::Base::$next";
		eval "package Hints::Base::_safe; require $nextname;";
		unless ($@) {	# database
			$nextname->import();
			return $nextname->new(@_);
		}
	}
	my @data = ();
	my $sourcepkg = ref $obj;
	no strict 'refs';
	my $fh = \*{"${sourcepkg}::DATA"};
	use strict 'refs';
	while (<$fh>) {
		last if /^__END__$/;
		push @data,$_;
	}
	$obj->load_from_file(\@data);
	$obj;
}

1;

__DATA__
__END__

=head1 VERSION

0.02

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>) for making
user-friendly interface.

=head1 SEE ALSO

perl(1), svplus(1), Hints(3), Hints::Base::svplus(3).

=cut

