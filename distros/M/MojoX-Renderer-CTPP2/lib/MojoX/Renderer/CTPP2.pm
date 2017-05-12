package MojoX::Renderer::CTPP2;

use strict;
use warnings;

use base 'Mojo::Base';

use File::Spec ();
use File::Path qw/make_path/;

use Carp        ();
use HTML::CTPP2 ();

our $VERSION = '0.02';

__PACKAGE__->attr('ctpp2');

my %ctpp2_allow_params = map { $_, 1 }
  qw/arg_stack_size code_stack_size steps_limit max_functions source_charset destination_charset/;

sub build {
    my $self = shift->SUPER::new(@_);

    $self->_init_ctpp2(@_);

    return sub { $self->_render(@_) };
}

sub _init_ctpp2 {
    my $self = shift;
    my %args = @_;

    my $mojo = $args{mojo};
    my %config = %{delete $args{template_options} || {}};

    $self->{COMPILE_EXT} ||= '.ctpp2c';

    $self->{CACHE_ENABLE} = 1 if not exists $self->{CACHE_ENABLE};

    unless (exists $self->{COMPILE_DIR}) {
        $self->{COMPILE_DIR} = $mojo ? $mojo->home->rel_dir('tmp/ctpp2') : File::Spec->tmpdir;
    }

    for (keys %config) {
        exists $ctpp2_allow_params{$_} or delete $config{$_};
    }

    $self->ctpp2(HTML::CTPP2->new(%config)) or Carp::croak 'Could not initialize CTPP2 object';

    if (!(ref $args{INCLUDE_PATH} eq 'ARRAY')) {
        my @include_path = _coerce_paths($args{INCLUDE_PATH}, $args{DELIMITER});
        if (!@include_path) {
            @include_path = $mojo ? $mojo->home->rel_dir('templates') : ();
        }
        $args{INCLUDE_PATH} = \@include_path;
    }

    $self->ctpp2->include_dirs(\@{$args{INCLUDE_PATH}});

    return $self;
}

sub _coerce_paths {
    my ($paths, $dlim) = @_;

    return () if (!$paths);
    return @{$paths} if (ref $paths eq 'ARRAY');

    $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':' unless (defined $dlim);

    return split(/$dlim/, $paths);
}

sub _render {
    my ($self, $renderer, $c, $output, $options) = @_;

    my $ctpp2         = $self->ctpp2;
    my $template_path = $c->stash->{'template_path'} || $renderer->template_path($options);
    my $bytecode      = $self->_get_bytecode($renderer->root, $template_path);

    $ctpp2->param({%{$c->stash}, base => $c->tx->req->url->base->to_string});

    unless ($$output = $ctpp2->output($bytecode)) {
        Carp::carp 'Template error: ['
          . $ctpp2->get_last_error->{'template_name'} . '] - '
          . $ctpp2->get_last_error->{'error_str'};
        return 0;
    }
    else {
        return 1;
    }
}

sub _get_bytecode {
    my ($self, $templates_rootdir, $template) = @_;

    my $ctpp2 = $self->ctpp2;

    if ($self->{CACHE_ENABLE}) {
        my $mojo            = $self->{mojo};
        my $compile_rootdir = $self->{COMPILE_DIR};

        my $template_relpath = File::Spec->abs2rel($template, $templates_rootdir);
        $template_relpath  =~ s{\.[^\.]+$}{};
        $template_relpath .= $self->{COMPILE_EXT};

        my $ctemplate = File::Spec->catfile($compile_rootdir, $template_relpath);

        my $bytecode;
        if (-e $ctemplate) {
            if ((stat($ctemplate))[9] < (stat($template))[9]) {
                $bytecode = $ctpp2->parse_template($template);
                $bytecode->save($ctemplate) if $bytecode;
            }
            else {
                return $ctpp2->load_bytecode($ctemplate);
            }
        }
        else {
            $bytecode = $ctpp2->parse_template($template);

            my $save_path = $ctemplate;
            $save_path =~ s{/[^/]+$}{};

            make_path($save_path) if !-d $save_path;

            $bytecode->save($ctemplate) if $bytecode;
        }
        return $bytecode;
    }
    else {
        $ctpp2->parse_template($template);
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MojoX::Renderer::CTPP2 - CTPP2 renderer for Mojo

=head1 SYNOPSIS

Add the handler:

  use MojoX::Renderer::CTPP2;

  sub startup {
     ...

    my $ctpp2 = MojoX::Renderer::CTPP2->build(
      mojo         => $self,

      INCLUDE_PATH => '/tmp;/tmp/project1',
      DELIMITER    => ';',

      CACHE_ENABLE => 0,
      COMPILE_DIR  => '/tmp/ctpp',
      COMPILE_EXT  => '.ctp2',

      template_options =>
        { arg_stack_size => 1024,
          steps_limit    => 1024*1024
        }
      );

      $self->renderer->add_handler( ctpp2 => $ctpp2 );

     ...
  }

And then in the handler call render which will call the
MojoX::Renderer::CTPP2 renderer.

  $c->render(templatename, format => 'htm', handler => 'ctpp2');

Template parameter are taken from $c->stash :

  $c->stash(users => [John, Peter, Ann]);

=head1 METHODS

=head2 build

This method returns a handler for the Mojo renderer.

Supported parameters are:

=over 4

=item mojo

C<build> currently uses a C<mojo> parameter pointing to the base class Mojo-object.

=item INCLUDE_PATH

The C<INCLUDE_PATH> is used to specify one or more directories in which
template files are located.  When a template is requested that isn't
defined locally as a C<BLOCK>, each of the C<INCLUDE_PATH> directories is
searched in turn to locate the template file.  Multiple directories
can be specified as a reference to a list or as a single string where
each directory is delimited by 'C<:>'.

  INCLUDE_PATH => '/project1/templates/1'

  INCLUDE_PATH => '/myapp/path1:/myapp/path2:path3'

  INCLUDE_PATH => [
    '/project1/templates/1',
    '/myapp/path2'
  ]

On Win32 systems, a little extra magic is invoked, ignoring delimiters
that have 'C<:>' followed by a 'C</>' or 'C<\>'.  This avoids confusion when using
directory names like 'C<C:\Blah Blah>'.

=item DELIMITER

Used to provide an alternative delimiter character sequence for
separating paths specified in the C<INCLUDE_PATH>.  The default
value for C<DELIMITER> is 'C<:>'.

  DELIMITER => ';'

On Win32 systems, the default delimiter is a little more intelligent,
splitting paths only on 'C<:>' characters that aren't followed by a 'C</>'.
This means that the following should work as planned, splitting the
C<INCLUDE_PATH> into 2 separate directories, C<C:/foo> and C<C:/bar>.

  # on Win32 only
  INCLUDE_PATH => 'C:/Foo:C:/Bar'

However, if you're using Win32 then it's recommended that you
explicitly set the C<DELIMITER> character to something else (e.g. 'C<;>')
rather than rely on this subtle magic.

=item CACHE_ENABLE

The C<CACHE_ENABLE> can be set 0 to disable templates caching. Default - caching enable.

=item COMPILE_DIR

The C<COMPILE_DIR> option is used to specify an alternate directory root
under which compiled template files should be saved.

  COMPILE_DIR => '/tmp/ctpp'

=item COMPILE_EXT

The C<COMPILE_EXT> option may be provided to specify a filename extension for
compiled template files. It is undefined by default used extension '.ctpp2c' .

  COMPILE_EXT => '.ccc'

=item template_options

A hash reference of options that are passed to HTML::CTPP2->new(). See also L<HTML::CTPP2>

=back

=head1 AUTHOR

Victor M Elfimov, (victor@sols.ru)

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-renderer-ctpp2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Renderer-CTPP2>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc MojoX::Renderer::CTPP2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Renderer-CTPP2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-CTPP2>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-CTPP2/>

=back

=head1 SEE ALSO

HTML::CTPP2(3) Mojo(3) MojoX::Renderer(3)

=head1 COPYRIGHT & LICENSE

Copyright 2009 Victor M Elfimov

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

