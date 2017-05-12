package Report::Generator::Render::TT2;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

use File::ShareDir ();
use File::Spec     ();
use Params::Util qw(_ARRAY0);

require Report::Generator::Render;
require Template;

=head1 NAME

Report::Generator::Render::TT2 - class for rendering reports using TT2

=cut

$VERSION = '0.002';
@ISA     = qw(Report::Generator::Render);

=head1 SYNOPSIS

    my %cfg = (
	 renderer => 'Report::Generator::Render::TT2',
	 'Report::Generator::Render::TT2' => {
	     config => { ABSOLUTE => 1, },
	     output => 'test1.ext',
	     vars => { },
	     template => 'test1.tt2',
	     options => {},
	 },
    );
    Report::Generator->new({cfg => \%cfg})->generate();

=head1 DESCRIPTION

C<Report::Generator::Render::TT2> provides a base class for rendering
reports in L<Report::Generator> using Template::Toolkit.

See the C<test*.tt2> examples in the examples directory of this
distribution to get a sense who to use this renderer.

=head1 SUBROUTINES/METHODS

=head2 new

Instantiates a new TT2 renderer for C<Report::Generator>.

    Report::Generator::Render::TT2->new(
	{
	    config   => { ... },
	    vars     => { ... },
	    options  => { ... },
	    template => 'path/to/template',
	    output   => 'path/to/output',
	}
    );

The parameters C<config>, <vars> and <options> are optional, C<template>
and C<output> are mandatory.

If the C<config> parameter hash contains a flag C<FIXED_INCLUDE_PATH> with
a true value, the next paragraph can be skipped.

When the C<config> parameter hash doesn't contain a value for C<DELIMITER>,
it's set to C<;> (semicolon) for the I<MSWin32> environment or to C<:>
(colon) otherwise. The value for C<INCLUDE_PATH> is appended by the
I<share>d directory for this distribution.

=cut

sub new
{
    my ( $proto, $attr ) = @_;

    # XXX some checks might be required here ...

    my $self      = $proto->SUPER::new($attr);
    my $config    = $self->{config} ||= {};
    my $fixed_inc = delete $config->{FIXED_INCLUDE_PATH};

    unless ($fixed_inc)
    {
        $config->{DELIMITER} ||= $^O eq 'MSWin32' ? ';' : ':';
        if ( $config->{INCLUDE_PATH} && '' eq ref( $config->{INCLUDE_PATH} ) )
        {
            $config->{INCLUDE_PATH} = [ split( $config->{DELIMITER}, $config->{INCLUDE_PATH} ) ];
        }
        push(
              @{ $config->{INCLUDE_PATH} },
              File::Spec->catdir( File::ShareDir::dist_dir('Report-Generator') )
            );
    }

    $self->{template} or croak("The template parameter is required");
    $self->{output}   or croak("The output parameter is required");

    return $self;
}

=head2 render

Renders the given C<template> into specified C<output> using the given
knobs. Returns a true value on success or sets C<< $self->{error} >>
otherwise.

=cut

sub render
{
    my $self = $_[0];

    my $template = Template->new( $self->{config} );
    my $rc = $template->process( $self->{template}, $self->{vars} || {},
                                 $self->{output}, %{ $self->{options} || {} } );
    $rc or $self->{error} = $template->error();

    return $rc;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-report-generator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Report-Generator>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Report::Generator::Render

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Report-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Report-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Report-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Report-Generator/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
