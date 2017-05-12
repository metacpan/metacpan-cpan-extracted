package Test::CGI::Multipart::Gen::Image;

use warnings;
use strict;
use Carp;
use Readonly;
use Test::CGI::Multipart;
use GD::Simple;

use version; our $VERSION = qv('0.0.3');

# Module implementation here

Test::CGI::Multipart->register_callback(
    callback => sub {
        my $hashref = shift;

        my %to_delete;
        return $hashref if exists $hashref->{value};

        # If the MIME type is not explicitly image/* its not ours.
        return $hashref if not exists $hashref->{type};
        return $hashref if $hashref->{type} !~ m{\Aimage/(\w+)\z}xms;
        my $type = $1;

        # get dimensions
        croak "no width specified" if not exists $hashref->{width};
        my $width = $hashref->{width};
        $to_delete{width} = 1;
        croak "no height specified" if not exists $hashref->{height};
        my $height = $hashref->{height};
        $to_delete{height} = 1;

        my $image = GD::Simple->new($width, $height);

        croak "no instructions specified"
            if not exists $hashref->{instructions};
        croak "intructions not a list"
            if ref $hashref->{instructions} ne 'ARRAY';
        my @instructions = @{$hashref->{instructions}};
        $to_delete{instructions} = 1;

        foreach my $instr (@instructions) {
            my ($cmd, @args) = @$instr;
            eval {$image->$cmd(@args)};
            if ($@) {
                warn "GD: $@";
                return $hashref;
            }
        }

        $hashref->{value} = eval {$image->$type};
        if ($@) {
            warn "GD: $@";
            delete $hashref->{value};
            return $hashref;
        }

        foreach my $del (keys %to_delete) {
            delete $hashref->{$del};
        }

        return $hashref;
    }
);

1; # Magic true value required at end of module
__END__

=head1 NAME

Test::CGI::Multipart::Gen::Image - Generate image test data for multipart forms

=head1 VERSION

This document describes Test::CGI::Multipart::Gen::Image version 0.0.3


=head1 SYNOPSIS

    use Test::CGI::Multipart;
    use Test::CGI::Multipart::Gen::Image;

    my $tcm = Test::CGI::Multipart;

    # specify the form parameters
    $tcm->upload_file(
        name='Image',
        file=>'cleopatra.doc',
        width=>400,
        height=>250,
        instructions=>[
            ['bgcolor,'red'],
            ['fgcolor','blue'],
            ['rectangle',30,30,100,100],
            ['moveTo',280,210],
            ['font','Times:italic'],
            ['fontsize',20],
            ['angle',-90],
            ['string','Helloooooooooooo world!'],
        ],
        type=>'image/jpeg'
    );
    $tcm->set_param(name=>'first_name',value=>'Jim');
    $tcm->set_param(name=>'last_name',value=>'Hacker');

    # Behind the scenes this will fake the browser and web server behaviour
    # with regard to environment variables, MIME format and standard input.
    my $cgi = $tcm->create_cgi;

    # Okay now we have a CGI object which we can pass into the code 
    # that needs testing and run the form handling various tests.
  
=head1 DESCRIPTION

This is a callback package for L<Test::CGI::Multipart> that facilitates 
the testing of the upload of text files of a given size and sample content.
One can specify the dimensions of the image and the size, font and colours
of a simple string.

=head1 INTERFACE 

For information on how to use this module, see L<Test::CGI::Multipart>
especially the section on callbacks. What this module offers is that if
the C<type> parameter begins with 'image/' and there is no C<value>
parameter you can specify various human
comprehensible inputs into the image rather than the raw binary.
In particular this covers what appears to be common use cases in testing
image upload: namely images of various types, file sizes and dimensions.

=over 

=item C<type>

The MIME type of the content. For this module to be interested
this parameter must be set, and must begin with 'image/'.
What follows is taken to be the image format and is treated as a 
function to the L<GD::Image> module.

=item C<width>, C<height>

These are the requested dimensions of the proposed image. They are
mandatory parameters.

=item C<font>, C<fontsize>, C<bgcolor>, C<fgcolor>, C<string>

These parameters are passed straight through to the L<GD::Simple>
module.

=back

=head1 DIAGNOSTICS

=over

=item C<< unexpected data structure >>

During the construction of the MIME data, the internal
data structure turned out to have unexpected features.
Since we control that data structure that should not happen.

=item C<< mismatch: is %s a file upload or not >>

The parameter was being used for both for file upload and normal
parameters.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Test::CGI::Multipart::Gen::Image requires no configuration files or environment variables.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-cgi-multipart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

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
