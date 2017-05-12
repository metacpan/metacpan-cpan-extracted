package MooseX::PDF;

use Moose::Role;

use Template;
use File::chdir;
use IO::CaptureOutput qw(capture qxx qxy);

our $VERSION = '0.01';

=head1 NAME

MooseX::PDF - Create PDF files with Moose using Template Toolkit templates

=head1 DESCRIPTION

MooseX::PDF provides functionality to create PDF files using Template Toolkit
templates. Given a template with PDF::Reuse directives, this module will
process the template and return the raw PDF contents.

This scalar can then be written to file, or output via a streamed process,
such as a web server.

=head1 SYNOPSIS

In your moose file do something like:

  with 'MooseX::PDF';

  $self->inc_path('/path/to/my/templates/folder/');
  my $vars = {
    scalar => $test,
    array  => \@array,
    hash   => \%hash
  };

  my $raw_pdf = $self->create_pdf('template_file',$vars);

=head1 ATTRIBUTES

=over 4

=item $self->inc_path()

Used to set the INCLUDE_PATH for TT

=back

=head1 SUBROUTINES/METHODS

=head2 create_pdf

Used to generate the raw pdf

=cut

has 'inc_path' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    predicate   => 'has_inc_path'
);

sub create_pdf {
    my ($self, $pdf_template, $vars) = @_;

    die 'Error: TT INCLUDE_PATH has not been specified!'
        unless( $self->has_inc_path );

    my $tt = Template->new({
        INCLUDE_PATH    => $self->inc_path,
        ENCODING        => 'utf8',
	    PLUGIN_BASE     => 'Template::Plugin',
        LOAD_PERL       => 1,
    });

    my $template = <<"EOT";
    [% USE pdf = PDF::Reuse %]
    [% PROCESS $pdf_template %]
EOT

    my ($output, $stdout, $stderr);

    local $CWD = $self->inc_path;

    #capture the output of TT and stick it into $stdout
    capture { $tt->process(\$template,$vars,\$output) } \$stdout;

    die 'There is an error with the template: ' . $tt->error
        if !$stdout;

    return $stdout;
}

1;

__END__

=head1 AUTHOR

Hamid Afshar, C<< <hamster at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-pdf-reuse at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-PDF>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 LICENSE AND COPYRIGHT

    Copyright 2013-2014 Hamid Afshar.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
