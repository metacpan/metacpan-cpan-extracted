package Template::Provider::PAR;
use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES);
use PAR;
use Scalar::Util qw(blessed);
use Carp qw(croak);
use File::Spec;
use Template::Provider;

use vars qw(@ISA $VERSION %AZ_ERROR_CODES);

@ISA = qw(Template::Provider);
use version; $VERSION = qv('0.1.102'); # last digit is SVN revision number

# FIXME disallow use of RELATIVE paths?

=head1 NAME

Template::Provider::PAR - Include templates from a path within a PAR or Zip archive.

=head1 VERSION

This document describes Template::Provider::PAR version 0.1.102.

=head1 SYNOPSIS

    use Template;
    use Template::Provider::PAR;

    # Specify the provider in the config for Template::Toolkit.  Note,
    # since no archive name is specified here, the name of the archive
    # will be obtained from $0
    my $tt_config =
    {
        LOAD_TEMPLATES =>
        [Template::Provider::PAR->new(INCLUDE_PATH => 'some/archive/dir')]
    };

    my $template = <<TEMPLATE;
    [% PROCESS something_in_the_archive.tt %]
    TEMPLATE

    my $tt = Template->new($tt_config);
    $tt->process($template, $vars) || die $tt->error;

=head1 DESCRIPTION

This C<Template::Provider::PAR> is designed to behave like a regular
C<Template::Provider>, except that it retrieves templates from a path
in a PAR archive, by default the archive in which the running script
is embedded within.  

This allows C<Template::Toolkit> to be used from an entirely
self-contained PAR archive.

=cut


# package variables

%AZ_ERROR_CODES = 
(AZ_OK           => 'Everything is fine.',
 AZ_STREAM_END   => 'The read stream (or central directory) ended normally.',
 AZ_ERROR        => 'There was some generic kind of error.',
 AZ_FORMAT_ERROR => 'There is a format error in a ZIP file being read.',
 AZ_IO_ERROR     => 'There was an IO error.');



=head1 INHERITED METHODS

These methods are inherited from L<Template::Provider> and function in
exactly the same way:

=over 4

=item * C<fetch()>

=item * C<store()>

=item * C<load()>

=item * C<include_path()>

=item * C<paths()>

=item * C<DESTROY()>

=back

See L<Template::Provider> for details of these methods.

=head1 CLASS METHODS

=head2 C<< $obj = $class->new(%parameters) >>

Constructs a new instance.

Accepts all the arguments as for the base class L<Template::Provider>,
with the following additions:

=over 4

=item C<ARCHIVE>

This optional parameter explicity sets the archive to use, either as a
filename or a reference to a C<Archive::Zip> object.  If omitted, then
the return value of C<PAR::par_handle($0)> is used. If this returns
undef, an error is thrown.


=item C<INCLUDE_PATH>

This works as before, except obviously it refers to a path
within the archive.  

=back

Note that the C<RELATIVE> parameter makes no sense within a PAR
archive, as it has no concept of a current directory, so the behaviour
is currently undefined and it should not be used.


=cut


=head1 INSTANCE METHODS

=head2 C<< $obj->archive >>

Returns a reference to the PAR archive (an instance of L<Archive::Zip>).

=cut

sub archive { shift->{ARCHIVE} }



#------------------------------------------------------------------------
# private class methods
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# $zip_path = $class->_zip_path($native_path)
#
# Converts native paths as returned by File::Spec to zip archive
# (unix) style paths.
#------------------------------------------------------------------------
sub _zip_path
{
    shift;
    # make sure we have a zip (unix style) path.
    # (I'd like to use unix paths through and through, but
    # we can't really override the parent class's use of
    # File::Spec without overriding everything else)
    join "/", File::Spec->splitdir(shift);
}




#------------------------------------------------------------------------
# $obj = $obj->_init(\%params)
#
# Initialise a new instance - sets the C<ARCHIVE> attribute and calls the 
# parent class's C<_init> method.
#------------------------------------------------------------------------
sub _init {
    my ( $self, $params ) = @_;
    my $archive;
    if ($params->{ARCHIVE})
    {
        $archive = $params->{ARCHIVE};
        if (blessed $archive)
        {
            croak "ARCHIVE parameter is not an Archive::Zip instance" 
                unless $archive->isa('Archive::Zip');
        }
        else
        {
            croak "Archive '$archive' does not exist"
                unless -f $archive;
        
            $archive = Archive::Zip->new($archive);
        }
    }
    else
    {
        $archive = PAR::par_handle($0)
            || croak "As we do not seem to be used within a PAR archive".
                " you must define the ARCHIVE parameter to reference a Zip archive";
    }

    $self->SUPER::_init( $params );
    $self->{ ARCHIVE } = $archive;
    # FIXME disallow RELATIVE?
    
    return $self;
}





#------------------------------------------------------------------------
# $time = $obj->_template_modified($path)
#
# Returns the last modified time of the $path.
# Returns undef if the path does not exist.
# Override if templates are not on disk, for example
#------------------------------------------------------------------------

sub _template_modified {
    my $self = shift;
    my $template = shift || return;
    $template = $self->_zip_path($template);

    my $member = $self->archive->memberNamed($template);
    
    return $member->lastModTime() if $member;
}


#------------------------------------------------------------------------
# $data = $obj->_template_content($path)
# ($data, $error, $mtime) = $obj->_template_content($path)
#
# Fetches content pointed to by $path (which is a local path spec referring 
# to a path within the archive, that will be converted to a zip-path 
# internally).
#
# Returns the content in scalar context.
# Returns ($data, $error, $mtime) in list context where
#   $data       - content
#   $error      - error string if there was an error, otherwise undef
#   $mtime      - last modified time from calling stat() on the path
#------------------------------------------------------------------------

sub _template_content {
    my ($self, $path) = @_;

    return (undef, "No path specified to fetch content from ")
        unless $path;
    $path = $self->_zip_path($path);

    my $archive = $self->archive;
    my ($data, $error) = $archive->contents($path);
    my $member = $archive->memberNamed($path);
    my $mod_date = $member? $member->lastModTime() : 0;

    # convert the error code
    $error = $error == AZ_OK? undef :
        "$path: Archive::Zip - ". $AZ_ERROR_CODES{$error};
        
    
    return wantarray
        ? ( $data, $error, $mod_date )
        : $data;
}


1; # End of the module code; everything from here is documentation...
__END__

=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<PAR>, L<Archive::Zip>


=head1 DIAGNOSTICS

In addition to errors raised by L<Template::Provider> and L<DBIx::Class>,
Template::Provider::PAR may generate the following error messages:

=over

=item C<< Archive '$archive' does not exist >>

Thrown by the constructor if the C<ARCHIVE> paramter is a non-existant
filename.

=item C<< ARCHIVE parameter is not an Archive::Zip instance >>

Thrown by the constructor if the C<ARCHIVE> paramter references an
object which isn't an C<Archive::Zip> instance.

=item C<< As we do not seem to be used within a PAR archive you must define the ARCHIVE parameter to reference a Zip archive >>

Thown by the constructor if no C<ARCHIVE> parameter is defined and the
host archive can't be inferred (i.e. if the running script is not
packaged within a PAR archive).

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<Template::Provider::PAR> requires no configuration files or
environment variables, other than those set by C<PAR>'s runtime
environment.

=head1 DEPENDENCIES

=over

=item

L<Archive::Zip>

=item

L<PAR>

=item

L<Scalar::Util>

=item

L<File::Spec>

=item

L<Carp>

=item

L<Template::Provider>

=item

L<Module::Build>

=item

L<Test::More>

=back

Additionally, use of this module requires an object of the class
L<DBIx::Class::Schema> or L<DBIx::Class::ResultSet>.


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-provider-par at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-PAR>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Provider::PAR

You may also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Provider-PAR/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Provider-PAR>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Provider-PAR/>

=back


=head1 AUTHOR

Nick Woolley <npw@cpan.org>

Much of the code was adapted from L<Template::Provider> by Andy
Wardley and L<Template::Provider::DBIC>, by David Cardwell.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Nick Woolley. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut
