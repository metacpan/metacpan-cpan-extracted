package Template::Provider::MD5;
use strict;
use base qw(Template::Provider);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Template::Constants qw(:status);
use Template::Provider;
use vars qw/$VERSION/;
$VERSION = "0.02";

my %tt_md5_cache = ();

=head1 NAME

Template::Provider::MD5 - MD5 Cached Compiled SCALARS for Template Toolkit

=head1 SYNOPSIS

	use Template::Provider::MD5;
	use Template;

	# NOTE: Config is shared between Providers and Templates there is no
	# clear separation.

	my $config = {
		INCLUDE_PATH    => "Some/Include/Path",
		EVAL_PERL       => 0,
		COMPILE_DIR     => "/var/tmp/TTCache",
		COMPILE_EXT     => '.ttc',
	};

	# MAke your provider first, otherwise Template will make one for you.
	my $p = Template::Provider::MD5->new($config);
	$config->{LOAD_TEMPLATES} = [$p];
	$config->{PREFIX_MAP} = {default => 0};
	my $tt = Template->new($config);

	... use $tt as per standard Template Toolkit ...

=head1 DESCRIPTION

Extension for L<Template> Toolkit to cache SCALAR Templates by using
MD5. A L<Template::Provider> is actually designed to provide an
alternate method for getting data (eg: the example is a WEB Access
Module). In this case it is actually a replacement to the default
L<Template::Provider> by providing caching for strings and then falling
back to the original when required.

=head1 METHODS

There are no public methods. They are all consumed by Template Toolkit

=cut

# XXX POD
# XXX Example
# XXX Test
# XXX
#       - Use init to check if we want memory cache only or file only or
#         combined.
#       - Notes on how we should be using REAL cache
#if ($slot = $self->{ LOOKUP }->{ $compiled }) {
#       XXX Totally temporary cache version, should be ->store
#       and ->refresh
#       ## cached entry exists, so refresh slot and extract data
#       #($data, $error) = $self->_refresh($slot);
#       #$data = $slot->[ Template::Provider::DATA ] unless $error;
# XXX ($data, $error) = $self->_store($compiled, { data => $data, load => 0 }, $compiled);

# ----------------------------------------------------------------------
sub fetch {
        my ($self, $name) = @_;

        # ONLY Supports SCALAR References, otherwise use standard
        if (ref($name) eq "SCALAR") {

                # Calculate the compiled filename
                my $compiled = $self->_compiled_filename_scalar($name);
                my ($data, $error, $slot);

                # Do we have it in our class cache ?
                if (exists($tt_md5_cache{$compiled})) {
                        # TODO - Consider using current TT cache
                        #       (that may not work but at least
                        #        support the same size limits)
                        # Load from cache
                        $data = $tt_md5_cache{$compiled};
                        $error = STATUS_OK;

                # Otherwise - do we have it on disk
                } elsif ($compiled && -f $compiled) {
                        # Load off the disk... should also store ?
                        $data = $self->_load_compiled($compiled);
                        $error = STATUS_OK;
                        $tt_md5_cache{$compiled} = $data;

                # Nope - we need to compile and store it
                } else {
                        # Compile from fresh.
                        ($data, $error) = $self->_load($name);
                        ($data, $error) = $self->_compile($data, $compiled) 
                                unless $error;

                        # Local file cached
                        ($data, $error) = $self->store($compiled, $data)
				unless $error;
                        $data = $data->{ data } 
                                unless $error;

                        # Memory cached
                        $tt_md5_cache{$compiled} = $data
				unless $error;
                }

                return ($data, $error);

        } else {
                return $self->SUPER::fetch($name);
        }
}

# ----------------------------------------------------------------------
sub _compiled_filename_scalar {
        my ($self, $name) = @_;
        return File::Spec->canonpath(
                # TODO - Make MD5_ etc configurable
                # TODO - Make this a HASHED path rather than flat
                # TODO - Allow other calculation algorythms - eg: not MD5
                $self->SUPER::_compiled_filename(
                        $self->_hash_name($name)
                )
        );
}

# ALLOW Overload of just this function
sub _hash_name {
	my ($self, $name) = @_;
	return 'MD5_' . md5_hex($$name);
}


1;

=head1 TODO

There are various things to do including:

=over

=item Alternate Hashing

There is no reason just to use MD5, this should be either something that can be
passed in or you could inherit this and pass in an alternate hashing.

=item Directory Hashing

Template Toollkit standard provider has a directory cache hashing by using the
name of the file. This one is all in one directory, which is, well, obviously
bad if you have LOTS of files. Generally speaking once unix hits 1000 files in
a directory you start noticing serious degradataion in performance of a simple
file operation (eg: -f).

=back

=head1 SEE ALSO

L<Template>

=head1 AUTHOR

Scott Penrose E<lt>F<scottp@dd.com.au>E<gt> OR E<lt>F<scott@cpan.org>E<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. (Artistic License and LGPL).

=cut
