package PostScript::Barcode;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Alien::BWIPP;
use IO::CaptureOutput qw(capture);
use List::Util qw(first);
use PostScript::Barcode::GSAPI::Singleton qw();
use Moose::Role qw(requires has);

our $VERSION = '0.006';

has '_gsapi_instance' => (
    is      => 'ro',
    isa     => 'PostScript::Barcode::GSAPI::Singleton',
    default => sub {return PostScript::Barcode::GSAPI::Singleton->instance;},
);

has 'data'      => (is => 'rw', isa => 'Str',           required => 1,);
has 'pack_data' => (is => 'rw', isa => 'Bool',          default  => 1,);
has 'move_to'   => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Tuple', default  => sub {return [0, 0];},);
has 'translate' => (is => 'rw', isa => 'Maybe[PostScript::Barcode::Meta::Types::Tuple]', default  => sub {return;},);
has 'scale'     => (is => 'rw', isa => 'Maybe[PostScript::Barcode::Meta::Types::Tuple]', default  => sub {return;},);

has '_post_script_source_bounding_box' => (is => 'rw', isa => 'Str',       lazy_build => 1,);
has 'bounding_box'                     => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::TuplePair',);
has '_post_script_source_header'       => (is => 'rw', isa => 'Str',       lazy_build => 1,);
has '_short_package_name'              => (is => 'ro', isa => 'Str',       lazy_build => 1,);
has '_alien_bwipp_class'               => (is => 'ro', isa => 'ClassName', lazy_build => 1,);

sub _build__post_script_source_header {
    my ($self) = @_;
    return "%!PS-Adobe-2.0 EPSF-2.0\n" . $self->_post_script_source_bounding_box;
}

sub _build__post_script_source_bounding_box {
    my ($self) = @_;
    if ($self->bounding_box) {
        return sprintf "%%%%BoundingBox: %u %u %u %u\n",
            $self->bounding_box->[0][0],
            $self->bounding_box->[0][1],
            $self->bounding_box->[1][0],
            $self->bounding_box->[1][1];
    } else {
        $self->_post_script_source_bounding_box('');
        my $stderr;
        capture { $self->render(-sDEVICE => 'bbox', -dEPSCrop => undef); } undef, \$stderr;
        {
            my (undef, $x1, $y1, $x2, $y2) = split ' ', $stderr;
            $self->bounding_box([[$x1, $y1], [$x2, $y2]]);
        }
        return $stderr;
    }
}

sub _build__short_package_name {
    my ($self) = @_;
    my $package_name = $self->meta->name;
    $package_name =~ s{\A .* (?:'|::)}{}msx;    # keep last part
    return $package_name;
}

sub _build__alien_bwipp_class {
    my ($self) = @_;
    return 'Alien::BWIPP::' . $self->_short_package_name;
}

sub _post_script_source_appendix {
    my ($self) = @_;
    my @own_attributes_with_value = grep {
        $_->definition_context->{'package'} eq $self->meta->name && $_->has_value($self)
    } $self->meta->get_all_attributes;
    my @bool_options = map {$_->name} grep {
        $_->type_constraint->equals('PostScript::Barcode::Meta::Types::Bool')
    } @own_attributes_with_value;
    my @compound_options = map {$_->name . '=' . $_->get_value($self)} grep {
        !$_->type_constraint->equals('PostScript::Barcode::Meta::Types::Bool')
    } @own_attributes_with_value;

    return sprintf "%s %s %u %u moveto %s (%s) /%s /uk.co.terryburton.bwipp findresource exec showpage\n",
        ($self->translate ? "@{$self->translate} translate" : q{}),
        ($self->scale ? "@{$self->scale} scale" : q{}),
        @{$self->move_to},
        ($self->pack_data ? '<' . unpack('H*', $self->data) . '>' : '(' . $self->data . ')'),
        "@bool_options @compound_options",
        $self->_short_package_name;
}

sub post_script_source_code {
    my ($self) = @_;
    return
        $self->_post_script_source_header
      . $self->_alien_bwipp_class->new->post_script_source_code
      . $self->_post_script_source_appendix;
}

sub _atomise_optlist {
    my ($self, @option_list) = @_;
    my $option_name = qr/\A -\w/msx;
    my @atoms;
    while (@option_list) {
        my $particle = pop @option_list;
        # maybe boolean option, maybe option value
        if (defined && /$option_name/msx) {
            unshift @atoms, [$particle];
        } else {
            my $option_key = pop @option_list;
            unshift @atoms, [$option_key => $particle];
        }
    }
    return @atoms;
}

sub gsapi_init_options {
    my ($self, @params) = @_;

    my $option_is_boolean = 1;
    my $option_without_equal_sign = qr/\A -g/msx;

    my %defaults = (
        -dBATCH             => \$option_is_boolean,
        -dEPSCrop           => \$option_is_boolean,
        -dNOPAUSE           => \$option_is_boolean,
        -dQUIET             => \$option_is_boolean,
        -dSAFER             => \$option_is_boolean,
        -dGraphicsAlphaBits => 4,
        -dTextAlphaBits     => 4,
        -sOutputFile        => '-',
    );

    {
        my $device_name = @{ first(sub {$_->[0] eq '-sDEVICE'}, $self->_atomise_optlist(@params)) // [] }[1];
        %defaults = (%defaults, -sDEVICE => 'pngalpha') unless $device_name;

        no warnings 'uninitialized';
        my $factor = {
            epswrite => 10,
            pdfwrite => 10,
            svg      => 1 / 0.24,
        }->{$device_name} // 1;
        %defaults = (%defaults,
            sprintf('-g%ux%u',
                $factor * ($self->bounding_box->[1][0] - $self->bounding_box->[0][0]),
                $factor * ($self->bounding_box->[1][1] - $self->bounding_box->[0][1])
            ) => \$option_is_boolean
        ) if $self->bounding_box;
    }

    # overwrite defaults with user supplied optlist
    for my $atom ($self->_atomise_optlist(@params)) {
        if (exists $defaults{$atom->[0]}) {
            if (2 == @{ $atom }) {
                if (defined $atom->[1]) {
                    $defaults{$atom->[0]} = $atom->[1];
                } else {
                    $defaults{$atom->[0]} = undef; # option to be dropped
                }
            }
        } elsif ($atom->[0] =~ /$option_without_equal_sign/msx) {
            delete @defaults{grep {/$option_without_equal_sign/msx} keys %defaults};
            if (2 == @{ $atom }) {
                if (defined $atom->[1]) {
                    $defaults{$atom->[0] . $atom->[1]} = \$option_is_boolean;
                }
            } else {
                $defaults{$atom->[0]} = \$option_is_boolean;
            }
        } else {
            if (2 == @{ $atom }) {
                $defaults{$atom->[0]} = $atom->[1];
            } else {
                $defaults{$atom->[0]} = \$option_is_boolean;
            }
        }
    }

    my @gsapi_init_options;
    for my $optname (keys %defaults) {
        if (ref $defaults{$optname} && $option_is_boolean == ${ $defaults{$optname} }) {
            push @gsapi_init_options, $optname;
        } else {
            if (defined $defaults{$optname}) {
                push @gsapi_init_options, "$optname=$defaults{$optname}";
            }
        }
    }
    return @gsapi_init_options;
}

sub render {
    my ($self, @params) = @_;

    $self->post_script_source_code;
    # Force building the dependent attributes now if they have not been built
    # yet. This is necessary because L</post_script_source_code> is used below,
    # after the initialisation of the GSAPI singleton. If this calls L</render>
    # again, C<libgs> is in an invalid state and crashes.

    GSAPI::init_with_args(
        $self->_gsapi_instance->handle, $self->meta->name, $self->gsapi_init_options(@params),
    );

    GSAPI::run_string($self->_gsapi_instance->handle, $self->post_script_source_code);
    GSAPI::exit($self->_gsapi_instance->handle);
    return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode - barcode writer


=head1 VERSION

This document describes C<PostScript::Barcode> version C<0.006>.


=head1 SYNOPSIS

    # This is abstract, do not use directly.


=head1 DESCRIPTION

By itself alone, this role does nothing useful. Use one of the classes
residing under this namespace:

=over

=item L<PostScript::Barcode::azteccode>

=item L<PostScript::Barcode::datamatrix>

=item L<PostScript::Barcode::qrcode>

=back

=head1 INTERFACE

See L<Moose::Manual::Types/"THE TYPES"> about the type names.

=head2 Attributes

=head3 C<data>

Type C<Str>, B<required> attribute, data to be encoded into a barcode.

=head3 C<pack_data>

Type C<Bool>, whether data is encoded into PostScript hex notation. Default
is true.

=head3 C<move_to>

Type C<PostScript::Barcode::Meta::Types::Tuple>, position where the barcode is
placed initially. Default is C<[0, 0]>, which is the lower left hand of a
document.

=head3 C<translate>

Type C<Maybe[PostScript::Barcode::Meta::Types::Tuple]>, vector by which the
barcode position is shifted. Default is C<undef>, no position shifting.

=head3 C<scale>

Type C<Maybe[PostScript::Barcode::Meta::Types::Tuple]>, vector by which the
barcode is resized. Default is C<undef>, no size scaling.

=head3 C<bounding_box>

Type C<PostScript::Barcode::Meta::Types::TuplePair>, coordinates of the EPS
document bounding box. Default values are automatically determined through the
Ghostscript C<bbox> device, see
L<http://ghostscript.com/doc/current/Devices.htm#Bounding_box_output>.

=head2 Methods

=head3 C<post_script_source_code>

Returns EPS source code of the barcode as string.

=head3 C<render>

    $barcode->render;
      # use defaults, see below
    $barcode->render(-sDEVICE => 'epswrite');
    $barcode->render(-sDEVICE => 'pdfwrite');
    $barcode->render(-sDEVICE => 'svg');

Most of the time the simple examples above are sufficient.

    $barcode->render(-sDEVICE => 'pnggray', -sOutputFile => 'out.png',);
      # overrides some default values
    $barcode->render(-dEPSCrop => undef, -g => undef,);
      # disables some default values

Takes an list of initialisation arguments. The argument names start with a
dash, see the explanation at L<GSAPI/"init_with_args"> and
L<http://ghostscript.com/doc/current/Use.htm#Invoking>. Renders and writes
the barcode image binary data to the specified file name.

=head4 options list atoms

=over

=item

a pair of C<Str> and C<Value> which results in a C<-key=value> option

=item

a pair of C<Str> and C<Undef> which disables a boolean option that
was enabled by default by this module

=item

a C<Str> which enables a boolean option.

=back

=head4 options defaults

C<qw(-dBATCH -dEPSCrop -dNOPAUSE -dQUIET -dSAFER -g>I<XXX>C<x>I<YYY>
C<-dGraphicsAlphaBits=4 -dTextAlphaBits=4 -sDEVICE=pngalpha -sOutputFile=-)>,
meaning the barcode is rendered as transparent PNG with anti-aliasing to
STDOUT, with the image size automatically taken from the L</"bounding_box">.


=head1 EXPORTS

Nothing.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

C<PostScript::Barcode> requires no configuration files or environment
variables.


=head1 DEPENDENCIES

=head2 Configure time

Perl 5.10, L<Module::Build>

=head2 Run time

=head3 core modules

Perl 5.10, L<List::Util>

=head3 CPAN modules

L<Alien::BWIPP>, L<IO::CaptureOutput>, L<GSAPI>, L<Moose>, L<Moose::Role>,
L<Moose::Util::TypeConstraints>, L<MooseX::Singleton>


=head1 INCOMPATIBILITIES

After version C<0.003> the type constraint for L</"bounding_box"> changed.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
L<http://github.com/daxim/PostScript-Barcode/issues>,
or send an email to the maintainer.


=head1 TO DO

=over

=item add classes for the other barcodes

=back

Suggest more future plans by L<filing a bug|/"BUGS AND LIMITATIONS">.


=head1 AUTHOR

=head2 Distribution maintainer

Lars Dɪᴇᴄᴋᴏᴡ C<< <daxim@cpan.org> >>

=head2 Contributors

See file F<AUTHORS>.


=head1 LICENCE AND COPYRIGHT

Copyright © 2010 Lars Dɪᴇᴄᴋᴏᴡ C<< <daxim@cpan.org> >>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0.

=head2 Disclaimer of warranty

This library is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or fitness
for a particular purpose.


=head1 ACKNOWLEDGEMENTS

I wish to thank C<rillian> on Freenode. Without your help, I would not have
got this project off the ground.


=head1 SEE ALSO

L<irc://irc.freenode.net/ghostscript>
