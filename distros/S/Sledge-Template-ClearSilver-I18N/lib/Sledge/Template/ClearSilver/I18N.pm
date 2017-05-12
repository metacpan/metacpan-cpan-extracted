package Sledge::Template::ClearSilver::I18N;

use strict;
use base qw(Sledge::Template::ClearSilver);
use Encode;

use vars qw($VERSION);
$VERSION = '0.01';

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
            $input.': Parse Error.'
        );
    }
    my $output = $cs->render();
    return Encode::decode('utf-8',$output);
}

sub _create_hdf {
    my $self = shift;
    local $Sledge::Template::NSSepChar = '.';
    $self->_associate_dump;
    my $hdf = ClearSilver::HDF->new;
    # set loadpath
    _hdf_setValue($hdf, 'hdf.loadpaths', $self->{_options}->{loadpaths});
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
            _hdf_setValue($hdf, $key.'.'.$index, $v);
            $index++;
        }
    } elsif (ref $val eq 'HASH') {
        while (my ($k, $v) = each %$val) {
            _hdf_setValue($hdf, $key.'.'.$k, $v);
        }
    } elsif (ref $val eq 'SCALAR') {
        _hdf_setValue($hdf, $key, $$val);
    } elsif (ref $val eq '' && $key && $val) {
        Encode::_utf8_on($key) unless Encode::is_utf8($key);
        Encode::_utf8_on($val) unless Encode::is_utf8($val);
        $hdf->setValue($key, $val);
    }
}

1;
__END__

=head1 NAME

Sledge::Template::ClearSilver::I18N - Internationalization extension to Sledge::Template::ClearSilver.


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

=head2 Sledge Base Controller

  package YourProj::Pages;
  use strict;
  use base qw(Sledge::Pages::Apache::I18N);
  use Sledge::Template::ClearSilver::I18N;
  use Sledge::Charset::UTF8::I18N;
  
  ....
  
  sub create_charset {
      my $self = shift;
      Sledge::Charset::UTF8::I18N->new($self);
  }

=head2 Sledge Application Controller

  package YourProj::Pages::Foo;
  use strict;
  use base qw(YourProj::Pages);
  
  dispatch_index {
      my $self = shift;
      $self->tmpl->param('bar' => {foo_one => 1, foo_two => 2});
  }

=head2 ClearSilver Template

  <?cs var:bar.foo_one ?> ## print 1
  <?cs var:bar.foo_two ?> ## print 2

=head1 DESCRIPTION

Sledge::Template::ClearSilver::I18N is Internationalization extension to Sledge::Template::ClearSilver.

=head1 BUGS

Please report any bugs or suggestions at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Template-CleaSilver-I18N>

=head1 SEE ALSO

L<Sledge::Template::ClearSilver> L<Bundle::Sledge::I18N>

ClearSilver Documentation:  L<http://www.clearsilver.net/docs/>

=head1 AUTHOR

syushi matsumoto, C<< <matsumoto at alink.co.jp> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Alink INC. all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



