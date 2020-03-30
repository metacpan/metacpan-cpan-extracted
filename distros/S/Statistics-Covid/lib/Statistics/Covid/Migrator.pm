package Statistics::Covid::Migrator;

use 5.006;
use strict;
use warnings;

use DateTime;

our $VERSION = '0.23';

sub	new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;

	my $self = {
		'config-hash' => undef,
		'version-from' => undef,
		'version-to' => $VERSION,
	};
	my $m;
	my $config_hash = undef;
	if( exists($params->{'config-file'}) && defined($m=$params->{'config-file'}) ){
		$config_hash = Statistics::Covid::Utils::configfile2perl($m);
		if( ! defined $config_hash ){ warn "error, failed to read config file '$m'."; return undef }
	} elsif( exists($params->{'config-string'}) && defined($m=$params->{'config-string'}) ){
		$config_hash = Statistics::Covid::Utils::configstring2perl($m);
		if( ! defined $config_hash ){ warn "error, failed to parse config string '$m'."; return undef }
	} elsif( exists($params->{'config-hash'}) && defined($m=$params->{'config-hash'}) ){ $config_hash = Storable::dclone($m) }
	else { warn "error, configuration was not specified using one of 'config-file', 'config-string', 'config-hash'. For an example configuration file see t/example-config.t."; return undef }
	$self->config($config_hash);

	# and done
	return $self
}
# return 1 on success, 0 on failure
sub	migrate {
	my $self = $_[0];
	die "not implemented, thoughts are using  DBIx::Class::DeploymentHandler but I was afraid of its long dependency list. This will be decided in the future. Email author if you have a suggestion."
}
sub     config {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'p'}->{'config-hash'} = $m; return $m }
	return $self->{'p'}->{'config-hash'}
}

1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8


=head1 NAME
Statistics::Covid::Migrator - Migrate data already collected to a newer version


=head1 VERSION

Version 0.23

=head1 DESCRIPTION
Newer versions of L<Statistics::Covid> may alter the database schema. This module
will try to move an older database to the new schame. It basically
has a lot of migration cases in the form C<from-version -> to-version>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid::Migrator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut
