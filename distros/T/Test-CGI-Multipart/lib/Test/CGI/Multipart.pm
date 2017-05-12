package Test::CGI::Multipart;

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;
use Params::Validate qw(:all);
use MIME::Entity;
use Readonly;
require 5.006_001; # we use 3-arg open in places

use version; our $VERSION = qv('0.0.3');

# Module implementation here

# Make callbacks a package variable as then loading callbacks
# will be prettier.
my @callbacks;

# Parameter specs
# Note the purpose of these spcs is to protect our data structures.
# It should not protect the code that will be tested
# as that must look after itself.
Readonly my $NAME_SPEC => {type=>SCALAR};
Readonly my $VALUE_SPEC => {type=>SCALAR|ARRAYREF};
Readonly my $UA_SPEC => {type=>SCALAR, default=> 'Test::CGI::Multipart'};
Readonly my $CGI_SPEC => {
    type=>SCALAR,
    default=>'CGI',
    regex=> qr{
                \A              # start of string
                (?:
                    \w          
                    |(?:\:\:)   # Module name separator
                )+
                \z              # end of string
    }xms
};
Readonly my $TYPE_SPEC => {
    type=>SCALAR,
    optional=>1,
    regex=> qr{
                \A              # start of string
                [\w\-]+         # major type
                \/              # MIME type separator
                [\w\-]+         # sub-type
                \z              # end of string
    }xms
};
Readonly my $FILE_SPEC => {
    type=>SCALAR,
};
Readonly my $MIME_SPEC => {
    type=>OBJECT,
    isa=>'MIME::Entity',
};
Readonly my $CODE_SPEC => {
    type=>CODEREF,
};

# MIME parsing states
Readonly my $TYPE_STATE => 0;
Readonly my $HEADER_STATE => 1;
Readonly my $DATA_STATE=> 2;
Readonly my $EOL => "\015\012";

sub new {
    my $class = shift;
    my $self = {
        file_index=>0,
        params=>{},
    };
    bless $self, $class;
    return $self;
}

sub set_param {
    my $self = shift;
    my %params = validate(@_, {name=>$NAME_SPEC, value=>$VALUE_SPEC});
    my @values  = ref $params{value} eq 'ARRAY'
                ? @{$params{value}}
                : $params{value}
    ;
    $self->{params}->{$params{name}} = \@values;
    return;
}

sub upload_file {
    my $self = shift;
    my %params = @_;
    my $params = \%params;

    foreach my $code (@callbacks) {
        $params = &$code($params);
    }

    $self->_upload_file(%$params);

    return;
}


sub _upload_file {
    my $self = shift;
    my %params = validate(@_, {
                    name=>$NAME_SPEC,
                    value=>$VALUE_SPEC,
                    file=>$FILE_SPEC,
                    type=>$TYPE_SPEC
    });
    my $name = $params{name};

    if (!exists $self->{params}->{$name}) {
        $self->{params}->{$name} = {};
    }
    if (ref $self->{params}->{$name} ne 'HASH') {
        croak "mismatch: is $name a file upload or not";
    }

    my $file_index = $self->{file_index};

    $self->{params}->{$name}->{$file_index} = \%params;

    $self->{file_index}++;

    return;
}

sub get_param {
    my $self = shift;
    my %params = validate(@_, {name=>$NAME_SPEC});
    my $name = $params{name};
    if (ref $self->{params}->{$name} eq 'HASH') {
        return values %{$self->{params}->{$name}};
    }
    return @{$self->{params}->{$name}};
}

sub get_names {
    my $self = shift;
    return keys %{$self->{params}};
}

sub create_cgi {
    use autodie qw(open);
    my $self = shift;
    my %params = validate(@_, {cgi=>$CGI_SPEC, ua=>$UA_SPEC});

    my $mime = $self->_mime_data;
    my $mime_str = $mime->stringify;
    my $mime_string = $self->_normalize1($mime_str);
    my $boundary = $mime->head->multipart_boundary;

    $ENV{REQUEST_METHOD}='POST';
    $ENV{CONTENT_TYPE}="multipart/form-data; boundary=$boundary";
    $ENV{CONTENT_LENGTH}=length($mime_string);
    $ENV{HTTP_USER_AGENT}=$params{ua};

    # Would like to localize these but this causes problems with CGI::Simple.
    local *STDIN;
    open(STDIN, '<', \$mime_string);
    binmode STDIN;

    $params{cgi}->require;

    if ($params{cgi} eq 'CGI::Simple') {
        $CGI::Simple::DISABLE_UPLOADS = 0;
    }
    if ($params{cgi} eq 'CGI') {
        CGI::initialize_globals();
    }
    if ($params{cgi} eq 'CGI::Minimal') {
        CGI::Minimal::reset_globals();
    }

    my $cgi = $params{cgi}->new;
    return $cgi;
}

sub _normalize1 {
    my $self = shift;
    my $mime_string = shift;
    $mime_string =~ s{([\w-]+:\s+[^\n]+)\n\n}{$1$EOL$EOL}xmsg;
    $mime_string =~ s{\n([\w-]+:\s+)}{$EOL$1}xmsg;
    $mime_string =~ s{\n(-------)}{$EOL$1}xmsg;
    return $mime_string;
}

sub _mime_data {
    my $self = shift;

    my $mime = $self->_create_multipart;
    foreach my $name ($self->get_names) {
        my $value = $self->{params}->{$name};
        if (ref($value) eq "ARRAY") {
            foreach my $v (@$value) {
                $self->_attach_field(
                    mime=>$mime,
                    name=>$name,
                    value=>$v,
                );
            }
        }
        elsif(ref($value) eq "HASH") {
            $self->_encode_upload(mime=>$mime,values=>$value);
        }
        else {
            croak "unexpected data structure";
        }
    }

    # Required so at least we don't have an empty MIME structure.
    # And lynx at least does send it.
    # CGI.pm seems to strip it out where as the others seem to pass it on.
    $self->_attach_field(
        mime=>$mime,
        name=>'.submit',
        value=>'Submit',
    );

    return $mime;
}

sub _attach_field {
    my $self = shift;
    my %params = validate(@_, {
                mime => $MIME_SPEC,
                name=>$NAME_SPEC,
                value=>$VALUE_SPEC,
        }
    );
    $params{mime}->attach(
        'Content-Disposition'=>"form-data; name=\"$params{name}\"",
        Data=>$params{value},
    );
    return;
}

sub _create_multipart {
    my $self = shift;
    my %params = validate(@_, {});
    return MIME::Entity->build(
        'Type'=>"multipart/form-data",
    );
}

sub _encode_upload {
    my $self = shift;
    my %params = validate(@_, {
                mime => $MIME_SPEC,
                values => {type=>HASHREF}
    });
    my %values = %{$params{values}};
    foreach my $k (keys %values) {
        $self->_attach_file(
            mime=>$params{mime},
            %{$values{$k}}
        );
    }
    return;
}

sub _attach_file {
    my $self = shift;
    my %params = validate(@_, {
                mime => $MIME_SPEC,
                file=>$FILE_SPEC,
                type=>$TYPE_SPEC,
                name=>$NAME_SPEC,
                value=>$VALUE_SPEC,
        }
    );
    my %attach = (
        'Content-Disposition'=>
            "form-data; name=\"$params{name}\"; filename=\"$params{file}\"",
        Data=>$params{value},
        Encoding=>'binary',
    );
    if ($params{type}) {
        $attach{Type} = $params{type};
    }
    $params{mime}->attach(
        %attach
    );
    return;
}

sub register_callback {
    my $self = shift;
    my %params = validate(@_, {
            callback => $CODE_SPEC,
        }
    );
    push @callbacks, $params{callback};
    return;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::CGI::Multipart - Test posting of multi-part form data

=head1 VERSION

This document describes Test::CGI::Multipart version 0.0.3

=head1 SYNOPSIS

    use Test::CGI::Multipart;

    my $tcm = Test::CGI::Multipart;

    # specify the form parameters
    $tcm->set_param(name='email',value=>'jim@hacker.com');
    $tcm->set_param(name=>'pets',value=> ['Rex', 'Oscar', 'Bidgie', 'Fish']);
    $tcm->set_param(name=>'first_name',value=>'Jim');
    $tcm->set_param(name=>'last_name',value=>'Hacker');
    $tcm->upload_file(
        name=>'file1',
        file=>'made_up_filename.txt',
        value=>$content
    );
    $tcm->upload_file(
        name=>'file1',
        file=>'made_up_filename.blah',
        value=>$content_blah,
        type=>'application/blah'
    );

    # Behind the scenes this will fake the browser and web server behaviour
    # with regard to environment variables, MIME format and standard input.
    my $cgi = $tcm->create_cgi;

    # Okay now we have a CGI object which we can pass into the code 
    # that needs testing and run the form handling various tests.
  
=head1 DESCRIPTION

It is quite difficult to write test code to capture the behaviour 
of CGI or similar objects handling forms that include a file upload.
Such code needs to harvest the parameters, build file content in MIME
format, set the environment variables accordingly and pump it into the 
the standard input of the required CGI object. This module provides
simple methods so that having prepared suitable content, the test script
can simulate the submission of web forms including file uploads.

However we also recognise that a test script is not always the best place
to prepare content. Rather a test script would rather specify requirements
for a file a upload: type, size, mismatches between the file name and its
contents and so on. This module cannot hope to provide such open ended
functionality but it can provide extension mechanisms.

This module works with L<CGI> (the default), L<CGI::Minimal> and 
L<CGI::Simple>. In principle it ought to work with all equivalent modules
however each module has a slightly different interface when it comes
to file uploads and so requires slightly different test code.

=head1 INTERFACE 

Several of the methods below take named parameters. For convenience we define those parameters here:

=over 

=item C<cgi>

This option defines the CGI module. It should be a scalar consisting only
of alphanumeric characters and C<::>. It defaults to 'CGI'.

=item C<name>

This is the name of form parameter. It must be a scalar.

=item C<value>

This is the value of the form parameter. It should either be
a scalar or an array reference of scalars.

=item C<file>

Where a form parameter represents a file, this is the name of that file.

=item C<type>

The MIME type of the content. This defaults to 'text/plain'.

=item C<ua>

The HTTP_USER_AGENT environment variable. This defaults to 'Test::CGI::Multipart'.

=back

=head2 new

An instance of this class might best be thought of as a "CGI object factory".
The constructor takes no parameters.

=head2 create_cgi

This returns a CGI object created according to the specification encapsulated in the object. The exact mechanics are as follows:

=over

=item The parameters are packaged up in MIME format.

=item The environment variables are set.

=item A pipe is created. The far end of the pipe is attached to our standard
input and the MIME content is pushed through the pipe.

=item The appropriate CGI class is required.

=item Uploads are enabled if the CGI class is L<CGI::Simple>.

=item Global variables are reset for L<CGI> and L<CGI::Minimal>.

=item The CGI object is created and returned.

=back

As far as I can see this simulates what happens when a CGI script processes a multi-part POST form. One can specify a different CGI class using the C<cgi> named parameter. One can set the HTTP_USER_AGENT environment variable with the C<ua> parameter.

=head2 set_param

This can be used to set a single form parameter. It takes two named arguments C<name> and C<value>. Note that this method overrides any previous settings including file uploads.

=head2 get_param

This retrieves a single form parameter. It takes a single named
parameter: C<name>. The data returned will be a list either of scalar
values or (in the case of a file upload) of HASHREFs. The HASHREFs would have
the following fields: C<file>, C<value> and C<type> representing the parameter
name, the file name, the content and the MIME type respectively.

=head2 get_names

This returns a list of stashed parameter names.

=head2 upload_file

In the absence of any defined callbacks, this method takes three mandatory
named parameters: C<name>, C<file> and C<value> and one optional parameter
C<type>. If there are any callbacks then the parameters are passed through each
of the callbacks and must meet the standard parameter requirements by the time
all the callbacks have been called.

Unlike the C<set_param> method this will not override previous
settings for this parameter but will add. However setting a normal parameter
and then an upload on the same name will throw an error.

=head2 register_callback

Callbacks are used by the C<upload_file> method, to allow a file to be specified
by properties rather than strict content. This method takes a single named
parameter called C<callback>, which adds that callback to an internal array
of callbacks. The idea being that the C<upload_file> method can take any
arguments you like so long as after all the callbacks have been applied, the
parameters consist of C<name>, C<file>, C<value> and possibly C<type>.
A callback should take and return a single hash reference.

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

Test::CGI::Multipart requires no configuration files or environment variables.

However it should be noted that the module will overwrite the following 
environment variables:

=over

=item REQUEST_METHOD

=item CONTENT_LENGTH

=item CONTENT_TYPE

=item HTTP_USER_AGENT

=back

=head1 INCOMPATIBILITIES

I would like to get this working with L<CGI::Lite::Request> and L<Apache::Request> if that makes sense. So far I have not managed that.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-cgi-multipart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

This module depends upon L<MIME::Tools>. Unfortunately that module
does not handle newlines quite correctly. That seems to work fine for
email but does not work with L<CGI>. I  have looked at  L<MIME::Fast>
and L<MIME::Lite> but L<MIME::Tools> combined with a hack seems the best
that can be done at the moment. Sooner or later someone is going to hit 
the limitations of that hack.

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
