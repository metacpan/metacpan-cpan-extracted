package Test::CGI::Multipart::Gen::Text;

use warnings;
use strict;
use Carp;
use Readonly;
use Test::CGI::Multipart;
use Text::Lorem;
use Scalar::Util qw(looks_like_number);

use version; our $VERSION = qv('0.0.3');

# Module implementation here

Test::CGI::Multipart->register_callback(callback => \&_random_text_cb);

sub _random_text_cb {
    my $href = shift;

    # If the MIME type is not explicitly text/plain its not ours.
    return $href if !exists $href->{type};
    return $href if $href->{type} ne 'text/plain';

    return $href if exists $href->{value};

    my $lorem = Text::Lorem->new;

    my $arg = sub {
        my $arg = shift;
        return exists $href->{$arg} && looks_like_number($href->{$arg});
    };

    $href->{value}
        = &$arg('words') ? $lorem->words($href->{words})
        : &$arg('sentences') ? $lorem->sentences($href->{sentences})
        : &$arg('paragraphs') ? $lorem->paragraphs($href->{paragraphs})
        : croak 'No words, sentences or paragraphs specified';

    delete $href->{words};
    delete $href->{sentences};
    delete $href->{paragraphs};

    return $href;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::CGI::Multipart::Gen::Text - Generate text test data for multipart forms

=head1 VERSION

This document describes Test::CGI::Multipart::Gen::Text version 0.0.3


=head1 SYNOPSIS

    use Test::CGI::Multipart;
    use Test::CGI::Multipart::Gen::Text;

    my $tcm = Test::CGI::Multipart;

    # specify the form parameters
    $tcm->upload_file(
        name='cv',
        file=>'cv.doc',
        paragraphs=>6,
        type=>'text/plain'
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
It generates random text using L<Text::Lorem>.

=head1 INTERFACE 

For information  on how to use this module, see L<Test::CGI::Multipart>, in
particular the section on callbacks. The effect of loading this module
is that the C<value> parameter ceases to be mandatory. Instead one can use
one of C<words>, C<sentences>, C<paragraphs> which are simply passed to
L<Text::Lorem>. Of these the highest priority is C<words>, then C<sentences>.

=head1 DIAGNOSTICS

=over

=item C<< No words, sentences or paragraphs specified >>

This module does require that at least one of the three
L<Text::Lorem> parameters is provided.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Test::CGI::Multipart::Gen::Text requires no configuration files or environment variables.

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
