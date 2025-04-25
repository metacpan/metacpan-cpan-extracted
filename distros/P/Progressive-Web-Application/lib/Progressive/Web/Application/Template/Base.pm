package Progressive::Web::Application::Template::Base;
use strict;
use JSON qw//;
our $JSON;
BEGIN { $JSON = JSON->new->utf8->pretty(1)->allow_nonref->allow_blessed; }

sub new {
	my $self = bless {}, $_[0];
	$self->{handle} = $_[0] . '::DATA';
	$self->{handle_start} = tell $self->{handle};
	$self->{data} = $self->get_data_section();
	return $self;
}

sub get_data_section {
	my $fh = $_[0]->{handle};
	my $content = do { local $/; <$fh> } or return;
	seek $_[0]->{handle}, $_[0]->{handle_start}, 0; # reset for next 'call' to get_data_section
	$content =~ s/^.*\n__DATA__//s;
	$content =~ s/\n__END__\n.*$/\n/s;
	my @data = split /^@@\s+(.+?)\s*\r?\n/m, $content;
	shift @data;
	return {@data};
}

sub render {
	my $templates = $_[0]->{data};
	if ($_[0]->can('required_params')) {
		for ($_[0]->required_params()) {
			Carp::croak(sprintf 'Required template param not found %s', $_)
				unless exists $_[1]->{$_};
		}
	}
	my $dataReg = join '|', map { quotemeta($_) } keys %{$_[1]};
	for my $key (keys %{$templates}) {
		$templates->{$key} =~ s/\{($dataReg)\}/_encode_json($_[1]->{$1})/eg;
		$templates->{$key} =~ s/\s*$//;
	}
	return $templates;
}

sub _encode_json {
	my $val = $JSON->encode($_[0]);
	chomp($val);
	return $val;
}

1;

__END__

=head1 NAME

Progressive::Web::Application::Template::Base - Base class for Progressive::Web::Application::Template's.

=cut

=head1 SYNOPSIS

	package Progressive::Web::Application::Template::MyTemplate;

	use parent 'Progressive::Web::Application::Template::Base';

	sub required_params { qw/.../ }

	1;

	__DATA__

	@@ pwa.js

	...

	@@ service-worker.js
	
	...
	
=cut

=head1 Methods

=cut

=head2 new 

Instantiate the template class, this identifies whether the template has __DATA__ associated to it and will read each 'template section' via get_data_section.

	my $template = Progressive::Web::Application::Template::MyTemplate->new();

=cut

=head2 get_data_section

Reads the __DATA__ section into an key/value Hash reference where the key is the template name and the value is the content of the template.

	my $re_read_data_section = $template->get_data_section();

=cut

=head2 render

Renders/Compiles all templates with the passed params. If the template has a 'required_params' sub configured then render will die if any of these params are missing. Returns a Key/Value Hash reference where the key is the template name and the value is the template content.

	my $templates = $template->render();

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-progressive-web-application at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Progressive-Web-Application>.  I will be notifie
d, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Progressive::Web::Application

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Progressive-Web-Application>

=item * Search CPAN

L<http://search.cpan.org/dist/Progressive-Web-Application/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019->2025 LNATION.

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
