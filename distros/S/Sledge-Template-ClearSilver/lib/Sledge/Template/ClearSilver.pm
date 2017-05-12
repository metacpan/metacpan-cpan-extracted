package Sledge::Template::ClearSilver;
use strict;
use warnings;
use base qw(Sledge::Template);

our $VERSION = '0.01';

use ClearSilver;
use Sledge::Exceptions;

sub import {
    my $class = shift;
    my $pkg = caller(0);
    no strict 'refs';
    *{"$pkg\::create_template"} = sub {
        my ($self, $file) = @_;
        return $class->new($file, $self);
    };
}

sub new {
    my ($class, $file, $page) = @_;
    bless {
        _options   => {
            filename  => $file,
            associate => [ $page->r ],
            loadpaths => [ $page->create_config->tmpl_path, '.' ],
            hdfpaths  => [],
        },
        _params    => {},
        _assoc     => {},
    }, $class;
}

sub output {
    my $self = shift;
    my $input = $self->{_options}->{filename};
    unless (-e $input) {
        Sledge::Exception::TemplateNotFound->throw(
            "$input: No template file detected. Check your template path.",
        );
    }
    my $hdf = $self->_create_hdf;
    my $cs = ClearSilver::CS->new($hdf);
    unless ($cs->parseFile($input)) {
        Sledge::Exception::TemplateParseError->throw(
            "$input: Parse Error."
        );
    }
    my $output = $cs->render;
    return $output;
}

sub _create_hdf {
    my $self = shift;
    local $Sledge::Template::NSSepChar = '.';
    $self->_associate_dump;
    my $hdf = ClearSilver::HDF->new;
    # set loadpath
    _hdf_setValue($hdf, 'hdf.loadpaths', $self->{_loadpaths});
    # read HDF Dataset files
    for my $path (@{$self->{_options}->{hdfpaths}}) {
        my $ret = $hdf->readFile($path);
        unless ($ret) {
            Sledge::Exception::TemplateParseError->throw(
                "$path: Parse Error. Couldn't create HDF Dataset."
            );
        }
    }
    # set params
    while (my ($key, $val) = each %{$self->{_params}}) {
        _hdf_setValue($hdf, $key, $val);
    }
    # set associate
    for my $assoc (@{$self->{_options}->{associate}}) {
        _hdf_setValue($hdf, $_, $assoc->param($_)) for $assoc->param;
    }
    $hdf;
}

sub _hdf_setValue {
    my ($hdf, $key, $val) = @_;
    if (ref $val eq 'ARRAY') {
        my $index = 0;
        for my $v (@$val) {
            _hdf_setValue($hdf, "$key.$index", $v);
            $index++;
        }
    } elsif (ref $val eq 'HASH') {
        while (my ($k, $v) = each %$val) {
            _hdf_setValue($hdf, "$key.$k", $v);
        }
    } elsif (ref $val eq 'SCALAR') {
        _hdf_setValue($hdf, $key, $$val);
    } elsif (ref $val eq '') {
        $hdf->setValue($key, $val);
    }
}

1;
__END__

=head1 NAME

Sledge::Template::ClearSilver - ClearSilver template system for Sledge

=head1 SYNOPSIS

  package MyApp::Pages;
  use strict;
  use base qw(Sledge::Pages::Apache);
  use Sledge::Template::ClearSilver

=head1 DESCRIPTION

Sledge::Template::ClearSilver is ClearSilver template system for Sledge.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bundle::Sledge>

ClearSilver Documentation:  L<http://www.clearsilver.net/docs/>

=cut
